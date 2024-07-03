## Setup

1. Open your project in Xcode.
2. Select `File > Add Package Dependencies`.
3. Enter the package repository URL: `https://github.com/numob/BarcodeScannerLibraryIOS.git`.
4. Choose the version rule and click `Next`.
5. Select the package products you need and click `Finish`.

## BarcodeScannerView Class
A SwiftUI class that encapsulates functionality from `DataScannerViewController` `VNBarcodeObservation` APIs using custom logic for selecting and returning barcodes.

- **Parameters:**
  - `autoscan`: A boolean indicating whether to automatically process codes from capture types (photo, file). Optional and defaults to true.
  - `restrictedArea`: A `CGSize` that determines the area on the view that can recognize barcodes, centered in the view. Optional and defaults to `CGSize(width: 200, height: 200)`.
  - `alignment`: The alignment of the content within the view. Optional and defaults to `.bottom`.
  - `didScannedCodes`: A callback function that handles the recognized barcodes and the capture type. The callback provides two parameters:
    - `capture`: The capture type, which indicates the source of the barcode capture (camera or file) and additional information such as whether the barcode is in the center of the view.
    - `barcodes`: An array of `Barcode` objects recognized from the DataScannerViewController. The object contains the following properties:
      - `payloadString`: The string representation of the barcode's payload.
      - `symbology`: The symbology type of the barcode, which can be either a known symbology or unknown.
      - `scannedCode`: The raw `RecognizedItem` from DataScannerViewController, if available.
      - `processedCode`: The `VNBarcodeObservation` from Vision, if available.
  - `label`: A view builder that provides allows for custom modifiers for the media button displayed on the `BarcodeScannerView`.

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
### Privacy:  
- BarcodeScannerView is public
  
## Preview
<div style="display: flex; gap: 10px;">
    <img src="https://github.com/numob/BarcodeScannerLibraryIOS/assets/164918815/d2fa023c-974d-430c-a073-214692c8b531" alt="Screenshot 2024-07-03 at 1 12 14 AM" height="400"/>
    <img src="https://github.com/numob/BarcodeScannerLibraryIOS/assets/164918815/7a2e1f43-41f1-4379-883b-82f2f84cb67f" alt="IMG_5097" height="400"/>
</div>


