import SwiftUI
import AVFoundation

struct ScannerView: View {
    @StateObject private var camera = CameraController()
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var showAlert = false
    @State private var errorMessage: String?
    @State private var isFlashlightOn = false
    @State private var isViewActive = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if camera.isSessionReady {
                    CameraPreview(camera: camera)
                        .ignoresSafeArea()
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                toggleFlashlight()
                            }) {
                                Image(systemName: isFlashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                        }
                        
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
                            Text("Инициализация камеры...")
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
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .sheet(isPresented: $productViewModel.showProductDetail) {
                if let product = productViewModel.currentProduct {
                    ProductDetailView(product: product)
                        .onDisappear {
                            productViewModel.startScanning()
                            camera.isScanningEnabled = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                camera.startSession()
                            }
                        }
                }
            }
            .sheet(isPresented: $productViewModel.showPhotoUpload) {
                if let barcode = productViewModel.currentBarcode {
                    PhotoUploadView(barcode: barcode)
                        .onDisappear {
                            productViewModel.startScanning()
                            camera.isScanningEnabled = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                camera.startSession()
                            }
                        }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            isViewActive = true
            productViewModel.startScanning()
            camera.isScanningEnabled = true
            checkCameraPermission()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                camera.startSession()
            }
        }
        .onDisappear {
            isViewActive = false
            productViewModel.stopScanning()
            camera.isScanningEnabled = false
            camera.stopSession()
            turnOffFlashlight()
        }
        .onChange(of: productViewModel.isScanning) { isScanning in
            if isScanning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    camera.startSession()
                }
            } else {
                camera.stopSession()
            }
        }
        .alert("Требуется доступ к камере", isPresented: $camera.showPermissionAlert) {
            Button("Настройки", role: .cancel) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("iScan требуется доступ к камере для сканирования штрих-кодов. Пожалуйста, предоставьте доступ в Настройках.")
        }
    }
    
    private func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                camera.onCodeScanned = { barcode in
                    guard productViewModel.isScanning && camera.isScanningEnabled else { return }
                    Task {
                        await productViewModel.fetchProduct(barcode: barcode)
                    }
                }
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    camera.onCodeScanned = { barcode in
                        guard productViewModel.isScanning && camera.isScanningEnabled else { return }
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
    
    private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                if device.torchMode == .on {
                    device.torchMode = .off
                    isFlashlightOn = false
                } else {
                    try device.setTorchModeOn(level: 1.0)
                    isFlashlightOn = true
                }
                device.unlockForConfiguration()
            } catch {
                print("Flashlight could not be used")
            }
        }
    }
    
    private func turnOffFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                isFlashlightOn = false
                device.unlockForConfiguration()
            } catch {
                print("Flashlight could not be turned off")
            }
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

class CameraController: NSObject, ObservableObject {
    @Published var showPermissionAlert = false
    @Published var isSessionReady = false
    @Published var isInitializing = false
    @Published var error: String?
    @Published var isScanningEnabled = false
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var onCodeScanned: ((String) -> Void)?
    
    var session: AVCaptureSession? {
        return captureSession
    }
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        isInitializing = true
        error = nil
        
        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            setError("Не удалось получить доступ к камере")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                setError("Не удалось добавить вход камеры")
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [
                    .ean8, .ean13, .upce, .code39, .code39Mod43, .code93, .code128,
                    .pdf417, .qr, .aztec, .interleaved2of5, .itf14, .dataMatrix
                ]
            } else {
                setError("Не удалось добавить выход метаданных")
                return
            }
            
            captureSession.commitConfiguration()
            self.captureSession = captureSession
            isInitializing = false
        } catch {
            setError("Ошибка инициализации камеры: \(error.localizedDescription)")
        }
    }
    
    func startSession() {
        guard let captureSession = captureSession, !captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionReady = true
                self.isInitializing = false
                self.error = nil
            }
        }
    }
    
    func stopSession() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.stopRunning()
            DispatchQueue.main.async {
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
            print("Scanned barcode: \(stringValue)")
            onCodeScanned?(stringValue)
        }
    }
} 