//
//  BarcodeScannerView.swift
//  SymbolDetector
//
//  Created by Wei Chen on 6/17/24.
//

import SwiftUI
import AVFoundation
import VisionKit

struct BarCodeScannerView: UIViewControllerRepresentable {
    @Binding var recognizedCode: String?
    
    var codeTypes: [AVMetadataObject.ObjectType] = [
        .codabar, .code39, .code39Mod43, .code93, .code128,
        .ean8, .ean13, .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited,
        .interleaved2of5, .itf14, .upce, .aztec, .dataMatrix,
        .microPDF417, .microQR, .pdf417, .qr
    ]
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: BarCodeScannerView
        var session: AVCaptureSession?
        
        init(parent: BarCodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  parent.codeTypes.contains(metadataObject.type),
                  let stringValue = metadataObject.stringValue else {
                return
            }
            
            DispatchQueue.main.async {
                self.parent.recognizedCode = stringValue
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        let session = AVCaptureSession()
        context.coordinator.session = session
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return viewController
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = codeTypes
        } else {
            return viewController
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        
        let scanningRect = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5) // relative coordinates
        metadataOutput.rectOfInterest = scanningRect
        
        session.startRunning()
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No need to update the view controller in this example
    }
}


struct MainView: View {
    @State private var recognizedCode: String?
    
    var body: some View {
        VStack {
            BarCodeScannerView(recognizedCode: $recognizedCode)
                .frame(width: 200, height: 200)
                .border(Color.green, width: 2)
                .overlay(
                    recognizedCode != nil ?
                        AnyView(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.green, lineWidth: 2)
                            .padding(10))
                        : AnyView(EmptyView())
                )
            
            if let code = recognizedCode {
                Text("Recognized Code: \(code)")
                    .padding()
            }
        }
    }
}

#Preview{
    MainView()
}
