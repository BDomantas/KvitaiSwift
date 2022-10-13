//
//  ScannerView.swift
//  kvitai
//
//  Created by Domantas Bernatavicius on 2022-07-02.
//

import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    @Environment(\.managedObjectContext) var moc

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: ScannerView

        private let completionHandler: ([Receipt]?) -> Void

        init(_ parent: ScannerView, completion: @escaping ([Receipt]?) -> Void) {
            self.completionHandler = completion
            self.parent = parent
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completionHandler(nil)
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            completionHandler(nil)
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let recognizer = TextRecognizer(cameraScan: scan, moc: parent.moc, withCompletionHandler: completionHandler)
            recognizer.reconizeText()
            controller.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self, completion: onScannedDocument)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func onScannedDocument(scannedDoccuments: [Receipt]?) {
        try? moc.save()
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
}
