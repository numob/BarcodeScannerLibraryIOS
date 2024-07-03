//
//  BarcodeScannerView.swift
//  BarcodeScannerApp
//
//  Created by Wei Chen on 6/27/24.


import BarcodeScanner
import SwiftUI
import Vision
import PDFKit
import UniformTypeIdentifiers
import VisionKit
import Foundation
import UIKit
/// A view that incorporates custom logic to select and return barcodes recognized from DataScannerViewController and VNBarcodeObservation APIs
/// - Parameters:
///   - autoscan: A boolean indicating whether to automatically process codes from capture types (photo, file). Optional and defaults to true.
///   - restrictedArea: A CGSize that determines the area on the view that can recognize barcodes, centered in the view. Optional and defaults to CGSize(width: 200, height: 200).
///   - alignment: The alignment of the content within the view. Optional and defaults to .bottom.
/// - didScannedCodes: A callback function that handles the recognized barcodes and the capture type. The callback provides two parameters:
///       - capture: The capture type, which indicates the source of the barcode capture (camera or file) and additional information such as whether the barcode is in the center of the view.
///       - barcodes: An array of `Barcode` objects recognized from the DataScannerViewController. The object contains the following properties:
///           - payloadString: The string representation of the barcode's payload.
///           - symbology: The symbology type of the barcode, which can be either a known symbology or unknown.
///           - scannedCode: The raw `RecognizedItem` from DataScannerViewController, if available.
///           - processedCode: The `VNBarcodeObservation` from Vision, if available.
///   - label: A view builder that provides allows for custom modifiers for the media button displayed on the BarCodeScannerView
/// - Example:
/// ```
/// BarcodeScannerView(
///     autoscan: true,
///     restrictedArea: CGSize(width: 200, height: 200),
///     alignment: .bottom,
///     didScannedCodes: { capture, barcodes in
///         self.captureType = capture
///         self.barcodes = barcodes
///     }
/// ) {
///     Text("Custom Text")
///         .frame(width: 300, height: 50)
///         .background(Color.blue)
///         .foregroundColor(.white)
///         .cornerRadius(10)
///         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
/// }
///
///
/// ```


struct ImageBarcodeData: Hashable, Identifiable {
    public var id: Int { self.hashValue }
    
    let image: UIImage
    let foundCodes: [VNBarcodeObservation]
}

public struct BarcodeScannerView<Label: View>: View {
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var isSelectingInput = false
    @State private var selectedCode: VNBarcodeObservation?
    @State private var showingConfirmationDialog = false
    @State private var showingImageSheet: ImageBarcodeData?
    @State private var isProcessingImage = false
    @State private var allowsScanning = true
    
    private let label: () -> Label
    private let didScannedCodes: (CaptureType, [Barcode]) -> Void
    
    private let alignment: Alignment
    private let restrictedArea: CGSize
    private let autoscan: Bool
    
    private var shouldStopScanning: Bool {
        showingImagePicker || showingDocumentPicker || showingConfirmationDialog || showingImageSheet != nil || isProcessingImage
    }
    
    public init(
        autoscan: Bool = true,
        restrictedArea: CGSize = . init(width: 200, height: 200),
        alignment: Alignment = .bottom,
        didScannedCodes: @escaping (CaptureType, [Barcode]) -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.autoscan = autoscan
        self.restrictedArea = restrictedArea
        self.alignment = alignment
        self.label = label
        self.didScannedCodes = didScannedCodes
    }
    
    public var body: some View {
        ZStack(alignment: alignment) {
            PreviewBarcodeScanner(
                scan: $allowsScanning,
                restrictedAreaSize: restrictedArea
            ) { scannedCode, isInCenterOfView in
                didScannedCodes(.camera(isInCenter: isInCenterOfView), [scannedCode].map(Barcode.init(item:)))
            }
            .ignoresSafeArea()
            
            label()
                .onTapGesture {
                    isSelectingInput = true
                }
        }
        .confirmationDialog("Choose", isPresented: $isSelectingInput, titleVisibility: .visible) {
            Button("Select Photo") {
                showingImagePicker = true
            }
            Button("Select File") {
                showingDocumentPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { selectedImage in
                loadImage(image: selectedImage)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                loadDocument(documentURL: url)
            }
            .ignoresSafeArea()
        }
        .sheet(item: $showingImageSheet) { state in
            VStack {
                Button {
                    showingImageSheet = nil
                }label:{
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .padding()
                }
                GeometryReader { geometry in
                    renderImageWithOverlay(state, geometry: geometry)
                }
                .alert(isPresented: $showingConfirmationDialog) {
                    Alert(
                        title: Text("Confirm Selection"),
                        message: Text("Do you want to select this code?"),
                        primaryButton: .default(Text("Yes")) {
                            if let selectedCode {
                                didScannedCodes(.file, [selectedCode].map(Barcode.init(observation:)))
                            }
                        },
                        secondaryButton: .cancel(Text("No")) {
                            showingConfirmationDialog = false
                            selectedCode = nil
                        }
                    )
                }
                
                let text: LocalizedStringKey = if state.foundCodes.isEmpty {
                    "No codes are recognized"
                }
                else if autoscan{
                    "All recognized codes will be added automatically."

                }
                else {
                    "Tap on a recognized code to select it"
                }
                
                
                HStack {
                    if autoscan {
                        ProgressView()
                    }
                    
                    Text(text)
                        .font(.caption)
                        .padding()
                }
            }
            .padding()
            .onAppear {
                // if autoscan is on, return all codes
                if autoscan {
                    didScannedCodes(.file, state.foundCodes.map(Barcode.init(observation:)))
                }
            }
            .onChange(of: shouldStopScanning) { oldValue, newValue in
                allowsScanning = !newValue
            }
        }
    }
    
    private func renderImageWithOverlay(_ state: ImageBarcodeData, geometry: GeometryProxy) -> some View {
        Image(uiImage: state.image)
            .resizable()
            .scaledToFit()
            .overlay(
                GeometryReader { geometry in
                    let imageSize = geometry.size
                    let imageWidth = imageSize.width
                    let imageHeight = imageSize.height
                    ForEach(state.foundCodes, id: \.uuid) { code in
                        Path { path in
                            let topLeft = CGPoint(
                                x: code.topLeft.x * imageWidth,
                                y: code.topLeft.y * imageHeight
                            ).translateCoords(using: imageHeight)
                            
                            let topRight = CGPoint(
                                x: code.topRight.x * imageWidth,
                                y: code.topRight.y * imageHeight
                            ).translateCoords(using: imageHeight)
                            
                            let bottomRight = CGPoint(
                                x: code.bottomRight.x * imageWidth,
                                y: code.bottomRight.y * imageHeight
                            ).translateCoords(using: imageHeight)
                            
                            let bottomLeft = CGPoint(
                                x: code.bottomLeft.x * imageWidth,
                                y: code.bottomLeft.y * imageHeight
                            ).translateCoords(using: imageHeight)
                            
                            path.move(to: topLeft)
                            path.addLine(to: topRight)
                            path.addLine(to: bottomRight)
                            path.addLine(to: bottomLeft)
                            path.closeSubpath()
                        }
                        .fill(Color.green.opacity(0.1))
                        .stroke(
                            selectedCode?.uuid == code.uuid ? Color.blue : Color.green,
                            lineWidth: 2
                        )
                        .onTapGesture {
                            guard !autoscan else { return }
                            selectedCode = code
                            showingConfirmationDialog = true
                        }
                    }
                }
            )
    }
    
    private func loadImage(image: UIImage) {
        guard !isProcessingImage else { return }
        isProcessingImage = true
        
        let request = VNDetectBarcodesRequest { (request, error) in
            if let results = request.results as? [VNBarcodeObservation] {
                self.showingImageSheet = .init(image: image, foundCodes: results)
            }
        }
        
        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: image.imageOrientation.cgImagePropertyOrientation,
            options: [:]
        )
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform barcode detection: \(error)")
            }
            
            isProcessingImage = false
        }
    }
    
    private func loadDocument(documentURL: URL) {
        guard !isProcessingImage else { return }
        isProcessingImage = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            processDocument(url: documentURL) { image in
                guard let image else { return }
                self.detectBarcodes(in: image)
            }
        }
    }
    
    private func detectBarcodes(in image: UIImage) {
        let request = VNDetectBarcodesRequest { (request, error) in
            if let results = request.results as? [VNBarcodeObservation] {
                self.showingImageSheet = .init(image: image, foundCodes: results)
            }
        }
        
        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: image.imageOrientation.cgImagePropertyOrientation,
            options: [:]
        )
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform barcode detection: \(error)")
            }
            
            isProcessingImage = false
        }
    }
    
    private func processDocument(url: URL, completion: @escaping (UIImage?) -> Void) {
        let fileType = UTType(filenameExtension: url.pathExtension)
        
        if fileType?.conforms(to: .pdf) == true {
            convertPDFToImage(url: url, completion: completion)
        } else if fileType?.conforms(to: .image) == true {
            if let image = UIImage(contentsOfFile: url.path) {
                completion(image)
            } else {
                print("Failed to load image from URL")
                completion(nil)
            }
        } else {
            print("Unsupported file type")
            completion(nil)
        }
    }
    
    private func convertPDFToImage(url: URL, completion: @escaping (UIImage?) -> Void) {
        print("PDF URL: \(url.absoluteString)")
        
        
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security-scoped resource")
            completion(nil)
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        let fileCoordinator = NSFileCoordinator()
        var error: NSError?
        
        fileCoordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &error) { newURL in
            let fileManager = FileManager.default
            let filePath = newURL.path
            
            if !fileManager.fileExists(atPath: filePath) {
                print("File does not exist at path: \(filePath)")
                do {
                    try fileManager.startDownloadingUbiquitousItem(at: newURL)
                    print("Started downloading the file.")
                } catch {
                    print("Failed to start downloading file: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
            }
            
            if !fileManager.fileExists(atPath: filePath) {
                print("File still does not exist at path after attempting download: \(filePath)")
                completion(nil)
                return
            }
            
            guard let document = PDFDocument(url: newURL) else {
                print("Failed to initialize PDFDocument with URL: \(newURL)")
                completion(nil)
                return
            }
            
            guard let page = document.page(at: 0) else {
                print("Failed to get the first page of the PDF document")
                completion(nil)
                return
            }
            
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let img = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                
                ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            completion(img)
        }
        
        if let error = error {
            print("Failed to coordinate access to file: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    private func preprocessImage(_ image: UIImage) -> CIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let upscaleTransform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        let upscaledImage = ciImage.transformed(by: upscaleTransform)
        
        return upscaledImage
    }

}

extension UIImage.Orientation {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage {
        let scale = width / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: width, height: newHeight))
        self.draw(in: CGRect(origin: .zero, size: CGSize(width: width, height: newHeight)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}

extension CGPoint {
    func translateCoords(using imageHeight: CGFloat) -> CGPoint {
        return CGPoint(x: self.x, y: imageHeight - self.y)
    }
}
