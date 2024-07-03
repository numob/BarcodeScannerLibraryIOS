//
//  DocumentPicker.swift
//  BarcodeScannerApp
//
//  Created by Wei Chen on 7/2/24.
//

import Foundation
import SwiftUI
import PDFKit

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentUrl: (URL) -> Void
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image])
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onDocumentUrl(url)
            }
        }
        
        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
