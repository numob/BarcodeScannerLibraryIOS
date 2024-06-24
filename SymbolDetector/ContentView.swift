//
//  ContentView.swift
//  SymbolDetector
//
//  Created by Wei Chen on 6/17/24.
//
import SwiftUI
import VisionKit

struct ContentView: View {
    @State private var recognizedItem: RecognizedItem?
    @State private var containsTarget: Bool = false
    @State private var target: Bool = true

    var body: some View {
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            ZStack(alignment: .bottom) {
              BarcodeScannerView(recognizedItem: $recognizedItem, containsTarget: $containsTarget, isTargetVisible: $target, focusedViewWidth: 200, focusedViewHeight: 200)
              BarcodeScannerView(recognizedItem: $recognizedItem, containsTarget: $containsTarget, isTargetVisible: $target)
            }
            Text("Within target: \(containsTarget)")
        } else if !DataScannerViewController.isSupported {
            Text("Device is not supported")
        } else {
            Text("Camera not available")
        }
    }
}
