//
//  DataScannerRepresentable.swift
//  SymbolDetector
//
//  Created by Wei Chen on 6/17/24.
//

import SwiftUI
import VisionKit
import Foundation
import UIKit

/// A class that incorporates custom logic to select and return barcodes recognized from DataScannerViewController.
/// - Parameters:
///   - onRecognizedItem: A callback function that handles the recognized item and whether it includes the target.
///   - isTargetVisible: A boolean  that sets the target visible or not; optional and default true
///   - focusedViewWidth: Sets the width of the focused view, which restricts the recognized items within the view; optional.
///   - focusedViewHeight: Sets the height of the focused view, which restricts the recognized items within the view; optional.
/// Example:
/// ```
/// BarcodeScannerView(
///     onRecognizedItem: { recognizedItem, containsTarget in
///         self.recognizedItem = recognizedItem
///         self.containsTarget = containsTarget
///     },
///     isTargetVisible: false,
///     focusedViewWidth: 200,
///     focusedViewHeight: 200,
/// )
/// BarcodeScannerView(
///     onRecognizedItem: { recognizedItem, containsTarget in
///         self.recognizedItem = recognizedItem
///         self.containsTarget = containsTarget
///     }
/// )
/// ```
/// Includes data labels for coordinates, dimensions, and recognized item data for debugging:
/// - displayOrientationLabel()
/// - displayRecognizedItemCoordinates(items: items)
/// - displayFrameCoords()
/// - displayFocusDimensions()

@MainActor
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onRecognizedItem: (RecognizedItem?, Bool) -> Void
    var isTargetVisible: Bool = true
    var focusedViewWidth: CGFloat?
    var focusedViewHeight: CGFloat?
    var scannerViewController: DataScannerViewController = DataScannerViewController(
        recognizedDataTypes: [.barcode()],
        qualityLevel: .balanced,
        recognizesMultipleItems: true,
        isHighFrameRateTrackingEnabled: false,
        isHighlightingEnabled: true
    )
    
    func addFocusedView(to view: UIView) {
        let padding: CGFloat = 10.0
        let defaultWidth: CGFloat = view.bounds.width - 2 * padding
        let defaultHeight: CGFloat = view.bounds.height - 2 * padding
        
        let width = min(focusedViewWidth ?? defaultWidth, view.bounds.width - 2 * padding)
        let height = min(focusedViewHeight ?? defaultHeight, view.bounds.height - 2 * padding)
        
        let viewXPosition: CGFloat = (view.bounds.width - width) / 2
        let viewYPosition: CGFloat = (view.bounds.height - height) / 2
        let focusBox = CGRect(x: viewXPosition, y: viewYPosition, width: width, height: height)
        
        let focusedView = FocusedView(focus: focusBox)
        view.addSubview(focusedView)
        focusedView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            focusedView.widthAnchor.constraint(equalToConstant: width),
            focusedView.heightAnchor.constraint(equalToConstant: height),
            focusedView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            focusedView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        scannerViewController.delegate = context.coordinator
        
        do {
            try scannerViewController.startScanning()
        } catch {
            print("Failed to start scanning: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            addTarget(to: scannerViewController.view)
            addFocusedView(to: scannerViewController.view)
            //context.coordinator.displayOrientationLabel()
            
        }
        
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // required function
        if let targetView = uiViewController.view.subviews.first(where: { $0 is TargetView }) {
            targetView.isHidden = !isTargetVisible
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, onRecognizedItem: onRecognizedItem)
    }
    func displayCutoutDimensions() {
        guard let cutout = (scannerViewController.view.subviews.first { $0 is FocusedView } as? FocusedView)?.focusBox else { return }
        
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.text = "Cutout: \(Int(cutout.width)) x \(Int(cutout.height))"
        label.sizeToFit()
        label.frame.origin = CGPoint(x: 10, y: 50)
        
        scannerViewController.view.subviews.filter { $0 is UILabel && $0.frame.origin == CGPoint(x: 10, y: 50) }.forEach { $0.removeFromSuperview() }
        
        scannerViewController.view.addSubview(label)
    }
    @MainActor
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: BarcodeScannerView
        var roundBoxMappings: [UUID: UIView] = [:]
        var coordinateLabels: [UUID: UILabel] = [:]
        var deviceOrientationLabel: UILabel?
        var onRecognizedItem: (RecognizedItem?, Bool) -> Void

        
        init(_ parent: BarcodeScannerView, onRecognizedItem: @escaping (RecognizedItem?, Bool) -> Void) {
            self.parent = parent
            self.onRecognizedItem = onRecognizedItem
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        }
        
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        }
        
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(items: allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(items: allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(items: allItems)
            
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            processItem(item: item)
        }
        
        func processItems(items: [RecognizedItem]) {
            removeAllBorderedBoxes()
            removeAllCoordinateLabels()
            
            if items.isEmpty {
                onRecognizedItem(nil, false)
                return
            }
            
            let visibleItems: [RecognizedItem]
            
            if parent.focusedViewWidth != nil && parent.focusedViewHeight != nil {
                visibleItems = items.filter { isItemWithinFocus(item: $0) }
            } else {
                visibleItems = items
            }
            
            guard let closestItem = findClosestToCenter(items: visibleItems) else {
                onRecognizedItem(nil, false)
                return
            }
            processItem(item: closestItem)
        }
        
        
        func isItemWithinFocus(item: RecognizedItem) -> Bool {
            guard let focusedView = (parent.scannerViewController.view.subviews.first { $0 is FocusedView } as? FocusedView),
                  let cutout = focusedView.focusBox else {
                return false
            }
            
            let (normalizedTopLeft, normalizedTopRight, normalizedBottomLeft, normalizedBottomRight) = normalizeBounds(item: item)
            
            let normalizedItemBounds = CGRect(
                x: min(normalizedTopLeft.x, normalizedBottomRight.x),
                y: min(normalizedTopLeft.y, normalizedBottomRight.y),
                width: abs(normalizedTopRight.x - normalizedTopLeft.x),
                height: abs(normalizedBottomLeft.y - normalizedTopLeft.y)
            )
            
            let normalizedCutout = normalizeBounds(coordinates: (
                topLeft: CGPoint(x: cutout.minX, y: cutout.minY),
                topRight: CGPoint(x: cutout.maxX, y: cutout.minY),
                bottomLeft: CGPoint(x: cutout.minX, y: cutout.maxY),
                bottomRight: CGPoint(x: cutout.maxX, y: cutout.maxY)
            ))
            
            let normalizedCutoutBounds = CGRect(
                x: min(normalizedCutout.topLeft.x, normalizedCutout.bottomRight.x),
                y: min(normalizedCutout.topLeft.y, normalizedCutout.bottomRight.y),
                width: abs(normalizedCutout.topRight.x - normalizedCutout.topLeft.x),
                height: abs(normalizedCutout.bottomLeft.y - normalizedCutout.topLeft.y)
            )
            
            
            return normalizedCutoutBounds.intersects(normalizedItemBounds)
        }
        
        func normalizeCutout(cutout: (x: Double, y: Double, width: Double, height: Double), image: (x: Double, y: Double, width: Double, height: Double)) -> (Double, Double, Double, Double) {
            let normalizedX = (cutout.x - image.x) / image.width
            let normalizedY = (cutout.y - image.y) / image.height
            let normalizedWidth = cutout.width / image.width
            let normalizedHeight = cutout.height / image.height
            return (normalizedX, normalizedY, normalizedWidth, normalizedHeight)
        }
        
        
        func findClosestToCenter(items: [RecognizedItem]) -> RecognizedItem? {
            let center = CGPoint(x: parent.scannerViewController.view.bounds.midX, y: parent.scannerViewController.view.bounds.midY)
            
            return items.min(by: { distanceToCenter(item: $0, center: center) < distanceToCenter(item: $1, center: center) })
        }
        
        func distanceToCenter(item: RecognizedItem, center: CGPoint) -> CGFloat {
            let itemCenter = CGPoint(x: (item.bounds.topLeft.x + item.bounds.bottomRight.x) / 2,
                                     y: (item.bounds.topLeft.y + item.bounds.bottomRight.y) / 2)
            return hypot(itemCenter.x - center.x, itemCenter.y - center.y)
        }
        
        func processItem(item: RecognizedItem) {
            removeAllBorderedBoxes()
            removeAllCoordinateLabels()
            
            let frame = calculateSelectedFrame(item: item)
            // displaySelectedCoords(frame: frame)
            switch item {
            case .barcode:
                addSelectionFrame(frame: frame, text: nil, item: item)
            default:
                print("No items recognized")
            }
            
            let containsTarget: Bool
            if parent.focusedViewWidth != nil && parent.focusedViewHeight != nil {
                containsTarget = isTargetWithinItemBounds(item: item)
            } else {
                containsTarget = true
            }
            
            onRecognizedItem(item, containsTarget)
        }
        
        func isTargetWithinItemBounds(item: RecognizedItem) -> Bool {
            let targetSize: CGFloat = 30.0
            let targetHalfSize = targetSize / 2.0
            let crosshairRect = CGRect(
                x: parent.scannerViewController.view.bounds.midX - targetHalfSize,
                y: parent.scannerViewController.view.bounds.midY - targetHalfSize,
                width: targetSize,
                height: targetSize
            )
            
            let itemBounds = CGRect(
                x: item.bounds.topLeft.x,
                y: item.bounds.topLeft.y,
                width: abs(item.bounds.topRight.x - item.bounds.topLeft.x),
                height: abs(item.bounds.topLeft.y - item.bounds.bottomLeft.y)
            )
            
            return itemBounds.intersects(crosshairRect)
        }
        
        func addSelectionFrame(frame: CGRect, text: String?, item: RecognizedItem) {
            let roundedRectView = RoundedRectLabel(frame: frame)
            roundedRectView.setText(text: text ?? "")
            parent.scannerViewController.overlayContainerView.addSubview(roundedRectView)
            roundBoxMappings[item.id] = roundedRectView
        }
        
        func removeAllBorderedBoxes() {
            for (_, roundBoxView) in roundBoxMappings {
                roundBoxView.removeFromSuperview()
            }
            roundBoxMappings.removeAll()
        }
        
        func removeAllCoordinateLabels() {
            for (_, label) in coordinateLabels {
                label.removeFromSuperview()
            }
            coordinateLabels.removeAll()
        }
        
        enum Rotation {
            case upright
            case rotated90
            case rotated180
            case rotated270
        }
        
        
        func calculateSelectedFrame(item: RecognizedItem) -> CGRect {
            let (normalizedTopLeft, normalizedTopRight, normalizedBottomLeft, normalizedBottomRight) = normalizeBounds(item: item)
            
            let frame = CGRect(
                x: min(normalizedTopLeft.x, normalizedBottomRight.x),
                y: min(normalizedTopLeft.y, normalizedBottomRight.y),
                width: abs(normalizedTopRight.x - normalizedTopLeft.x),
                height: abs(normalizedBottomLeft.y - normalizedTopLeft.y)
            )
            
            return frame
        }
        
        
        func normalizeBounds(item: RecognizedItem? = nil, coordinates: (topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint)? = nil) -> (topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
            let topLeft, topRight, bottomLeft, bottomRight: CGPoint
            
            if let item = item {
                topLeft = item.bounds.topLeft
                topRight = item.bounds.topRight
                bottomLeft = item.bounds.bottomLeft
                bottomRight = item.bounds.bottomRight
            } else if let coordinates = coordinates {
                topLeft = coordinates.topLeft
                topRight = coordinates.topRight
                bottomLeft = coordinates.bottomLeft
                bottomRight = coordinates.bottomRight
            } else {
                fatalError("Either a RecognizedItem or coordinates must be provided.")
            }
            
            let widthVector = CGPoint(x: topRight.x - topLeft.x, y: topRight.y - topLeft.y)
            let heightVector = CGPoint(x: bottomLeft.x - topLeft.x, y: bottomLeft.y - topLeft.y)
            
            var rotation: Rotation
            
            if abs(widthVector.x) > abs(widthVector.y) {
                if widthVector.x > 0 {
                    rotation = .upright
                } else {
                    rotation = .rotated180
                }
            } else {
                if heightVector.y > 0 {
                    rotation = .rotated90
                } else {
                    rotation = .rotated270
                }
            }
            
            let normalizedTopLeft, normalizedTopRight, normalizedBottomLeft, normalizedBottomRight: CGPoint
            
            switch rotation {
            case .upright:
                normalizedTopLeft = topLeft
                normalizedTopRight = topRight
                normalizedBottomLeft = bottomLeft
                normalizedBottomRight = bottomRight
            case .rotated90:
                normalizedTopLeft = bottomLeft
                normalizedTopRight = topLeft
                normalizedBottomLeft = bottomRight
                normalizedBottomRight = topRight
            case .rotated180:
                normalizedTopLeft = bottomRight
                normalizedTopRight = bottomLeft
                normalizedBottomLeft = topRight
                normalizedBottomRight = topLeft
            case .rotated270:
                normalizedTopLeft = topRight
                normalizedTopRight = bottomRight
                normalizedBottomLeft = topLeft
                normalizedBottomRight = bottomLeft
            }
            
            return (normalizedTopLeft, normalizedTopRight, normalizedBottomLeft, normalizedBottomRight)
        }
        
        
        
        func displayRecognizedItemCoordinates(items: [RecognizedItem]) {
            for item in items {
                let itemCenterX = (item.bounds.topLeft.x + item.bounds.bottomRight.x) / 2
                let itemCenterY = (item.bounds.topLeft.y + item.bounds.bottomRight.y) / 2
                
                let label = UILabel()
                label.textColor = .red
                label.font = UIFont.systemFont(ofSize: 12)
                label.text = "(\(Int(itemCenterX)), \(Int(itemCenterY)))"
                label.sizeToFit()
                let center = convertToViewCoordinate(CGPoint(x: itemCenterX, y: itemCenterY))
                label.center = center
                label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                
                
                parent.scannerViewController.overlayContainerView.addSubview(label)
                coordinateLabels[item.id] = label
            }
        }
        
        func displayFrameCoords(frame: CGRect) {
            let label = UILabel()
            label.textColor = .blue
            label.font = UIFont.systemFont(ofSize: 12)
            label.text = "(\(Int(frame.origin.x)), \(Int(frame.origin.y))) Size: (\(Int(frame.size.width)), \(Int(frame.size.height)))"
            label.sizeToFit()
            // offset lable to not interfere with other lables
            label.center = CGPoint(x: frame.midX, y: frame.midY + 10)
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            
            
            parent.scannerViewController.overlayContainerView.addSubview(label)
            coordinateLabels[UUID()] = label
        }
        func convertToViewCoordinate(_ point: CGPoint) -> CGPoint {
            let viewWidth = parent.scannerViewController.view.bounds.width
            let viewHeight = parent.scannerViewController.view.bounds.height
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            let x = (point.x / screenWidth) * viewWidth
            let y = (point.y / screenHeight) * viewHeight
            
            return CGPoint(x: x, y: y)
        }
        
        
        /// Code to display an orientation label
        func displayFocusDimensions() {
            parent.displayCutoutDimensions()
        }
        
        @objc func onOrientationChange() {
            updateDeviceOrientationLabel()
            //displayFocusDimensions()
            updateFocusedViewBounds()
            
            
        }
        
        func displayOrientationLabel() {
            let orientationLabel = UILabel()
            orientationLabel.textColor = .white
            orientationLabel.font = UIFont.systemFont(ofSize: 14)
            orientationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            orientationLabel.frame.origin = CGPoint(x: 10, y: 10)
            parent.scannerViewController.view.addSubview(orientationLabel)
            self.deviceOrientationLabel = orientationLabel
            updateDeviceOrientationLabel()
        }
        
        func updateDeviceOrientationLabel() {
            guard let deviceOrientationLabel = deviceOrientationLabel else { return }
            let deviceOrientation = UIDevice.current.orientation
            deviceOrientationLabel.text = "Device Orientation: \(orientationString(deviceOrientation))"
            deviceOrientationLabel.sizeToFit()
        }
        func updateFocusedViewBounds() {
            guard let view = parent.scannerViewController.view, let focusedView = view.subviews.first(where: { $0 is FocusedView }) as? FocusedView else {
                return
            }
            
            guard let width = parent.focusedViewWidth, let height = parent.focusedViewHeight else { return }
            
            let viewXPosition: CGFloat = (view.bounds.width - width) / 2
            let viewYPosition: CGFloat = (view.bounds.height - height) / 2
            let focusBox = CGRect(x: viewXPosition, y: viewYPosition, width: width, height: height)
            
            focusedView.focusBox = focusBox
            focusedView.setNeedsDisplay()
        }
        
        func orientationString(_ orientation: UIDeviceOrientation) -> String {
            switch orientation {
            case .portrait: return "Portrait"
            case .portraitUpsideDown: return "Portrait Upside Down"
            case .landscapeLeft: return "Landscape Left"
            case .landscapeRight: return "Landscape Right"
            case .faceUp: return "Face Up"
            case .faceDown: return "Face Down"
            case .unknown: return "Unknown"
            @unknown default: return "Unknown"
            }
        }
        
    }
    
    func addTarget(to view: UIView) {
        let targetSize: CGFloat = 30.0
        let targetView = TargetView(frame: CGRect(x: (view.bounds.width - targetSize) / 2,
                                                  y: (view.bounds.height - targetSize) / 2,
                                                  width: targetSize,
                                                  height: targetSize))
        targetView.translatesAutoresizingMaskIntoConstraints = false
        targetView.isHidden = !isTargetVisible
        view.addSubview(targetView)
        
        NSLayoutConstraint.activate([
            targetView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            targetView.widthAnchor.constraint(equalToConstant: targetSize),
            targetView.heightAnchor.constraint(equalToConstant: targetSize)
        ])
    }
}
extension CGRect {
    func boundingBox() -> CGRect {
        return CGRect(
            x: self.minX,
            y: self.minY,
            width: self.width,
            height: self.height
        )
    }
}



class RoundedRectLabel: UIView {
    let label = UILabel()
    let cornerRadius: CGFloat = 5.0
    let padding: CGFloat = 5
    var text: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
        
        layer.borderColor = UIColor.green.cgColor
        layer.borderWidth = 2.0
        layer.cornerRadius = cornerRadius
        backgroundColor = UIColor.clear
    }
    
    func setText(text: String) {
        label.text = text
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TargetView: UIView {
    let crosshairSize: CGFloat = 30.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        let horizontalLine = UIView(frame: CGRect(x: 0, y: crosshairSize / 2 - 1, width: crosshairSize, height: 2))
        horizontalLine.backgroundColor = .yellow
        addSubview(horizontalLine)
        
        let verticalLine = UIView(frame: CGRect(x: crosshairSize / 2 - 1, y: 0, width: 2, height: crosshairSize))
        verticalLine.backgroundColor = .yellow
        addSubview(verticalLine)
    }
}

class FocusedView: UIView {
    var focusBox: CGRect?
    
    init(focus: CGRect?) {
        super.init(frame: .zero)
        self.focusBox = focus
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        backgroundColor?.setFill()
        UIRectFill(rect)
        guard let cutout = focusBox else { return }
        
        let path = UIBezierPath(rect: cutout)
        let intersection = rect.intersection(cutout)
        UIRectFill(intersection)
        
        UIColor.clear.setFill()
        UIGraphicsGetCurrentContext()?.setBlendMode(.copy)
        path.fill()
    }
}

