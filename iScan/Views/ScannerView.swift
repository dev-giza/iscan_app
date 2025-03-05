import SwiftUI
import AVFoundation

struct ScannerView: View {
    @StateObject private var camera = CameraController()
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var showAlert = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if camera.isSessionReady {
                    CameraPreview(camera: camera)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 250, height: 250)
                        
                        Spacer()
                        
                        if let error = productViewModel.error {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                } else {
                    Color.black
                        .ignoresSafeArea()
                    VStack {
                        if camera.isInitializing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Initializing camera...")
                                .foregroundColor(.white)
                                .padding()
                        }
                        
                        if let error = camera.error {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let product = productViewModel.currentProduct {
                            ProductDetailView(product: product)
                                .onDisappear {
                                    productViewModel.startScanning()
                                }
                        }
                    },
                    isActive: $productViewModel.showProductDetail
                ) { EmptyView() }
            )
            .onAppear {
                productViewModel.startScanning()
                checkCameraPermission()
            }
            .onDisappear {
                productViewModel.stopScanning()
                camera.stopSession()
            }
            .onChange(of: productViewModel.isScanning) { isScanning in
                if isScanning {
                    camera.startSession()
                } else {
                    camera.stopSession()
                }
            }
            .alert("Camera Permission Required", isPresented: $camera.showPermissionAlert) {
                Button("Settings", role: .cancel) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("iScan needs camera access to scan barcodes. Please grant access in Settings.")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                await camera.setupCaptureSession()
                camera.onCodeScanned = { barcode in
                    guard productViewModel.isScanning else { return }
                    Task {
                        await productViewModel.fetchProduct(barcode: barcode)
                    }
                }
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    await camera.setupCaptureSession()
                    camera.onCodeScanned = { barcode in
                        guard productViewModel.isScanning else { return }
                        Task {
                            await productViewModel.fetchProduct(barcode: barcode)
                        }
                    }
                } else {
                    camera.showPermissionAlert = true
                }
            case .denied, .restricted:
                camera.showPermissionAlert = true
            @unknown default:
                camera.error = "Unknown camera permission status"
            }
        }
    }
}

class CameraController: NSObject, ObservableObject {
    @Published var showPermissionAlert = false
    @Published var isSessionReady = false
    @Published var isInitializing = false
    @Published var error: String?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var onCodeScanned: ((String) -> Void)?
    
    var session: AVCaptureSession? {
        return captureSession
    }
    
    override init() {
        super.init()
    }
    
    func setupCaptureSession() async {
        await MainActor.run {
            isInitializing = true
            error = nil
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            await MainActor.run {
                setError("Failed to access camera device")
                isInitializing = false
            }
            return
        }
        
        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        do {
            let input = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                await MainActor.run {
                    setError("Failed to add camera input")
                    isInitializing = false
                }
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr]
            } else {
                await MainActor.run {
                    setError("Failed to add metadata output")
                    isInitializing = false
                }
                return
            }
            
            captureSession.commitConfiguration()
            self.captureSession = captureSession
            
            startSession()
        } catch {
            await MainActor.run {
                setError("Failed to initialize camera: \(error.localizedDescription)")
                isInitializing = false
            }
        }
    }
    
    func startSession() {
        guard let captureSession = captureSession, !captureSession.isRunning else { return }
        
        Task.detached {
            captureSession.startRunning()
            await MainActor.run {
                self.isSessionReady = true
                self.isInitializing = false
                self.error = nil
            }
        }
    }
    
    func stopSession() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        
        Task.detached {
            captureSession.stopRunning()
            await MainActor.run {
                self.isSessionReady = false
            }
        }
    }
    
    private func setError(_ message: String) {
        self.error = message
        self.isSessionReady = false
        self.isInitializing = false
    }
}

extension CameraController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            onCodeScanned?(stringValue)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let camera: CameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        if let captureSession = camera.session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
} 