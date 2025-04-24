//
//  iScanApp.swift
//  iScan
//
//  Created by Gizat Uteyev on 3/3/25.
//

import SwiftUI

@main
struct iScanApp: App {
    @StateObject private var productViewModel = ProductViewModel()
    @State private var selectedTab = 0 // 0 for Scanner, 1 for History
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ScannerView()
                    .tabItem {
                        Label("Сканер", systemImage: "barcode.viewfinder")
                    }
                    .tag(0)
                
                HistoryView()
                    .tabItem {
                        Label("История", systemImage: "clock.fill")
                    }
                    .tag(1)
            }
            .environmentObject(productViewModel)
            .onChange(of: selectedTab) { newTab in
                if newTab == 0 { // Switched to Scanner
                    print("Switched to Scanner tab, calling startScanning")
                    productViewModel.startScanning()
                } else { // Switched away from Scanner
                    print("Switched away from Scanner tab, calling stopScanning")
                    productViewModel.stopScanning()
                }
            }
        }
    }
}
