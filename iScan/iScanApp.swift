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
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ScannerView()
                    .tabItem {
                        Label("Scan", systemImage: "barcode.viewfinder")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
            }
            .environmentObject(productViewModel)
        }
    }
}
