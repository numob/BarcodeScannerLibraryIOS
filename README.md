## Setup

1. Open your project in Xcode.
2. Select `File > Add Package Dependencies`.
3. Enter the package repository URL: `https://github.com/numob/BarcodeScannerLibraryIOS.git`.
4. Choose the version rule and click `Next`.
5. Select the package products you need and click `Finish`.

## BarcodeScannerView Class
A SwiftUI class that encapsulates functionality from `DataScannerViewController` and `VNBarcodeObservation` APIs using custom logic for selecting and returning barcodes.

- **Parameters:**
  - `autoscan`: A boolean indicating whether to automatically process codes from capture types (photo, file). Optional and defaults to true.
  - `restrictedArea`: A `CGSize` that determines the area on the view that can recognize barcodes, centered in the view. Optional and defaults to `CGSize(width: 200, height: 200)`.
  - `isCenterIconVisible`: A boolean that determines if the icon indicating the center of the view shows or not. Optional and defaults to true.
  - `alignment`: The alignment of the content within the view. Optional and defaults to `.bottom`.
  - `didScannedCodes`: A callback function that handles the recognized barcodes and the capture type. The callback provides two parameters:
    - `capture`: The capture type, which indicates the source of the barcode capture (camera or file) and additional information such as whether the barcode is in the center of the view.
    - `barcodes`: A set of `Barcode` objects recognized from the DataScannerViewController. The object contains the following properties:
      - `id`: A UUID representing the unique identifier of the barcode.
      - `payloadString`: The string representation of the barcode's payload.
      - `symbology`: The symbology type of the barcode, which can be either a known symbology or unknown.
  - `label`: A view builder that allows for custom modifiers for the media button displayed on the `BarcodeScannerView`.

### Example:
```swift
// minimum configuration
BarcodeScannerView(
    didScannedCodes: { capture, barcodes in
        self.captureType = capture
        self.barcodes = barcodes
    }
)
// full configuration
BarcodeScannerView(
    autoscan: true,
    restrictedArea: CGSize(width: 200, height: 200),
    isCenterIconVisible: false,
    alignment: .bottom,
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
Highlight for camera barcode scanning don't support angles not standard (0, 90, 180, 270)

