## Setup

1. Open your project in Xcode.
2. Select `File > Add Package Dependencies`.
3. Enter the package repository URL: `https://github.com/numob/BarcodeScannerLibraryIOS.git`.
4. Choose the version rule and click `Next`.
5. Select the package products you need and click `Finish`.

## BarcodeScannerView Class

A class that incorporates custom logic for selecting and returning barcodes recognized from `DataScannerViewController`.

- **recognizedItem**: (from `DataScannerViewController` item)
- **containsTarget**: A bool reference that is returned from this class on whether or not the recognized item includes the target (crosshair plus icon).
- **isTargetVisible**: A bool reference that sets the target (center indicated by plus symbol) visible or not.
- **focusedViewWidth** and **focusedViewHeight**: Set the dimensions of the focused view, which is a view that restricts the recognized items within the view; optional.

### Example:
```swift
BarcodeScannerView(
    recognizedItem: $recognizedItem, 
    containsTarget: $containsTarget, 
    isTargetVisible: $target, 
    focusedViewWidth: 200, 
    focusedViewHeight: 200
)
BarcodeScannerView(
    recognizedItem: $recognizedItem, 
    containsTarget: $containsTarget, 
    isTargetVisible: $target
)

```
## Preview
![Screenshot 2024-06-24 at 1 44 24 PM](https://github.com/numob/BarcodeScannerLibraryIOS/assets/164918815/6d877515-9bbf-4189-a901-6f2b0821fcd5)


