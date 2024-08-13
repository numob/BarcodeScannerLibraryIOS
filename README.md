## Setup

1. Open your project in Xcode.
2. Select `File > Add Package Dependencies`.
3. Enter the package repository URL: `https://github.com/numob/BarcodeScannerLibraryIOS.git`.
4. Choose the version rule and click `Next`.
5. Select the package products you need and click `Finish`.

## BarcodeScannerView Class
A SwiftUI class that encapsulates functionality from `DataScannerViewController` and `VNBarcodeObservation` APIs using custom logic for selecting and returning barcodes.

### **Parameters**
- `restrictedArea`: A `CGSize` that determines the area on the view that can recognize barcodes, centered in the view. Optional and defaults to `CGSize(width: 200, height: 200)`.
- `isCenterIconVisible`: A boolean that determines if the icon indicating the center of the view shows or not. Optional and defaults to `true`.
- `isHighlightingCameraCode`: A boolean which enables or disables a green box highlighting to the recognized and returned barcode.
- `imageChooseLabelAlignment`: The alignment of the content within the view. Optional and defaults to `.bottom`.
- `returnMultipleSymbolsForLocalImage`: A boolean which determines if processing local images for codes will return multiple automatically or must be user-selected.
- `didScannedCodes`: A callback function that handles the recognized barcodes and the capture type. The callback provides two parameters:
  - `capture`: The capture type, which indicates the source of the barcode capture (camera or file) and additional information such as whether the barcode is in the center of the view.
  - `barcodes`: An array of `Barcode` objects recognized from the `DataScannerViewController`. The object contains the following properties:
    - `id`: A UUID representing the unique identifier of the barcode.
    - `payloadString`: The string representation of the barcode's payload.
    - `symbology`: The symbology type of the barcode, which can be either a known symbology or unknown.
    - `recognizedItemCamera`: An optional `RecognizedItem` object representing the barcode or text recognized from the camera. This property is `nil` if the barcode was initialized from an image.
    - `recognizedItemImage`: An optional `VNBarcodeObservation` object representing the barcode recognized from an image. This property is `nil` if the barcode was initialized from the camera.
- `label`: A view builder that allows for custom modifiers for the media button displayed on the `BarcodeScannerView`.

### Example

```swift
// Minimum configuration
BarcodeScannerView(
    didScannedCodes: { capture, barcodes in
        self.captureType = capture
        self.barcodes = barcodes
    }
)

// Full configuration
BarcodeScannerView(
    restrictedArea: CGSize(width: 200, height: 200),
    isCenterIconVisible: false,
    isHighlightingCameraCode: true,
    imageChooseLabelAlignment: .bottom,
    returnMultipleSymbolsForLocalImage: false,
    didScannedCodes: { capture, barcodes in
        self.captureType = capture
        self.barcodes = barcodes
    }
) {
    Text("Custom Text")
        .frame(width: 300, height: 50)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
}
```

### Dependencies:
- VisionKit and other libraries handled; only requires SwiftUI.
- Camera, Photo Gallery, and Document Folder permissions required.


### Privacy:  
- BarcodeScannerView is public.

## Preview
<div style="display: flex; gap: 10px;">
    <img src="https://github.com/numob/BarcodeScannerLibraryIOS/assets/164918815/59f6cd46-c713-438f-b8b1-9a260a5297cf" alt="IMG_0026" height="400"/>
    <img src="https://github.com/numob/BarcodeScannerLibraryIOS/assets/164918815/eb4540a4-5948-43cd-bf4c-0d6ada2e6f7f" alt="IMG_0022" height="400"/>
</div>

***NOTE***
Highlight for camera barcode scanning doesn't support angles not standard (0, 90, 180, 270)

