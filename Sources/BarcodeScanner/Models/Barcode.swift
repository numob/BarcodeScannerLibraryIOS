#if !targetEnvironment(macCatalyst)
import Foundation
import VisionKit
import Vision

public enum CaptureSource {
    case camera(isInCenter: Bool)
    case file
}

/// A custom symbology value to represent unknown or non-barcode items.
public enum BarcodeSymbology: Hashable {
    case known(VNBarcodeSymbology)
    case unknown
}

/// Barcode is a model that contains information about a scanned code.
public struct Barcode: Identifiable {
    public let id: UUID
    public let payloadString: String?
    public let symbology: BarcodeSymbology
    public let recognizedItemCamera: RecognizedItem?
    public let recognizedItemImage: VNBarcodeObservation?
    
    /// Initializes a Barcode from a RecognizedItem.
    /// - Parameter item: The recognized item, which can be either text or a barcode.
    public init(recognizedItem: RecognizedItem) {
        self.recognizedItemCamera = recognizedItem
        self.recognizedItemImage = nil
        switch recognizedItem {
        case .text(let text):
            self.id = text.id
            self.payloadString = text.transcript
            self.symbology = .unknown
        case .barcode(let barcode):
            self.id = barcode.id
            self.payloadString = barcode.payloadStringValue
            self.symbology = .known(barcode.observation.symbology)
        }
    }
    
    /// Initializes a Barcode from a VNBarcodeObservation.
    /// - Parameter observation: The VNBarcodeObservation containing the barcode information.
    public init(observation: VNBarcodeObservation) {
        self.recognizedItemImage = observation
        self.recognizedItemCamera = nil
        self.id = observation.uuid
        self.payloadString = observation.payloadStringValue
        self.symbology = .known(observation.symbology)
    }
}

#endif
