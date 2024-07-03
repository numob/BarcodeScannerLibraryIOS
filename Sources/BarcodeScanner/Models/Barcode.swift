//
//  Barcode.swift
//
//
//  Created by Wei Chen on 7/2/24.
//

import Foundation
import VisionKit
import Vision

public enum CaptureType {
    case camera(isInCenter: Bool)
    case file
}

/// A custom symbology value to represent unknown or non-barcode items.
public enum BarcodeSymbology: Hashable {
    case known(VNBarcodeSymbology)
    case unknown
}

/// Barcode is a model that contains information about a scanned code.
public struct Barcode: Hashable, Identifiable {
    public let id: UUID
    public let payloadString: String?
    public let symbology: BarcodeSymbology
//    public let scannedCode: RecognizedItem?
//    public let processedCode: VNBarcodeObservation?
    
    /// Initializes a Barcode from a RecognizedItem.
    /// - Parameter item: The recognized item, which can be either text or a barcode.
    public init(item: RecognizedItem) {
//        self.scannedCode = item
//        self.processedCode = nil
        
        switch item {
        case .text(let text):
            self.id = text.id
            self.payloadString = text.transcript
            self.symbology = .unknown // Default value for non-barcode items
        case .barcode(let barcode):
            self.id = barcode.id
            self.payloadString = barcode.payloadStringValue
            self.symbology = .known(barcode.observation.symbology)
        }
    }
    
    /// Initializes a Barcode from a VNBarcodeObservation.
    /// - Parameter observation: The VNBarcodeObservation containing the barcode information.
    public init(observation: VNBarcodeObservation) {
//        self.scannedCode = nil
//        self.processedCode = observation
        self.id = observation.uuid
        self.payloadString = observation.payloadStringValue
        self.symbology = .known(observation.symbology)
    }
}
