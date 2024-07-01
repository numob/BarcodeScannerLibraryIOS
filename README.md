## Setup

1. Open your project in Xcode.
2. Select `File > Add Package Dependencies`.
3. Enter the package repository URL: `https://github.com/numob/BarcodeScannerLibraryIOS.git`.
4. Choose the version rule and click `Next`.
5. Select the package products you need and click `Finish`.

## BarcodeScannerView Class

A class that incorporates custom logic for selecting and returning barcodes recognized from `DataScannerViewController`.

- **Parameters:**
  - `onRecognizedItem`: A callback function that handles the recognized item and whether it includes the target.
  - `isTargetVisible`: A boolean that sets the target visible or not; optional and default true.
  - `focusedViewWidth`: Sets the width of the focused view, which restricts the recognized items within the view; optional.
  - `focusedViewHeight`: Sets the height of the focused view, which restricts the recognized items within the view; optional.

### Example:
```swift
    BarcodeScannerView(
        didScannedCode: { scannedCode, isInCenterOfView in
            self.scannedCode = scannedCode
            self.isInCenterOfView = isInCenterOfView
        },
        isCenterIconVisible: false,
        restrictedArea: CGSize(width: 200, height: 200)
    )

    BarcodeScannerView(
        didScannedCode: { scannedCode, isInCenterOfView in
            self.scannedCode = scannedCode
            self.isInCenterOfView = isInCenterOfView
        }
    )

```
## Preview
<img src="https://github.com/numob/BarcodeScannerLibraryIOS/assets/164918815/6d877515-9bbf-4189-a901-6f2b0821fcd5" alt="Screenshot 2024-06-24 at 1 44 24 PM" width="400"/>


