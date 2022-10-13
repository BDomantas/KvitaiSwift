//
//  TextRecognizer.swift
//  kvitai
//
//  Created by Domantas Bernatavicius on 2022-07-02.
//

import CoreData
import Foundation
import Vision
import VisionKit

final class TextRecognizer {
    let cameraScan: VNDocumentCameraScan
    let completionHandler: ([Receipt]?) -> Void
    let moc: NSManagedObjectContext

    init(cameraScan: VNDocumentCameraScan, moc: NSManagedObjectContext, withCompletionHandler completionHander: @escaping ([Receipt]?) -> Void) {
        self.cameraScan = cameraScan
        self.completionHandler = completionHander
        self.moc = moc
    }
    
    private var queue = DispatchQueue(label: "scan-code", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    func reconizeText() {
        queue.async {
            let images = (0 ..< self.cameraScan.pageCount).compactMap {
                self.cameraScan.imageOfPage(at: $0).cgImage
            }
            let imagesAndRequests = images.map { (image: $0, request: VNRecognizeTextRequest()) }
            let textPerPage = imagesAndRequests.compactMap {
                image, request -> Receipt? in
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    request.customWords = ["Moketi EUR", "PVM", "EUR", "suma", "kvitas"]
                    
                    try handler.perform([request])
                    guard let observations = request.results else { return nil }
                    return self.processTextObservation(textObservations: observations, image: image)
                } catch {
                    print(error)
                    return nil
                }
            }
            DispatchQueue.main.async {
                self.completionHandler(textPerPage)
            }
        }
    }
    
    func processTextObservation(textObservations: [VNRecognizedTextObservation], image: CGImage) -> Receipt? {
        var docSerialFirstHalf: (Int, String)?
        var docSerialSecondHalf: (Int, String)?
        var toPayLocation: Int?
        var docDate: Date?
        var docSum: String?
        var docRawData: [String] = []
        
        let serialPatter = #"[0-9]+/[0-9]+/[0-9]+"#
        let regex = try! NSRegularExpression(pattern: serialPatter)
        let types: NSTextCheckingResult.CheckingType = [.date]
        let detector = try! NSDataDetector(types: types.rawValue)

        for (index, element) in textObservations.enumerated() {
            guard let candidate = element.topCandidates(1).first else { continue }
            let text = candidate.string
            docRawData.append(text)
            
            // That uses the utf16 count to avoid problems with emoji and similar.
            let textRange = NSRange(location: 0, length: text.utf16.count)
            let match = regex.firstMatch(in: text, options: .init(), range: textRange)
            
            if let unWrappedMatch = match {
                docSerialSecondHalf = (index, text)
            }
            
            let matches = detector.firstMatch(in: text, options: .init(), range: NSRange(location: 0, length: text.count))
                            
            if let unwrappedMatch = matches {
                if [unwrappedMatch.resultType] == NSTextCheckingResult.CheckingType.date {
                    docDate = unwrappedMatch.date
                }
            }
            if text == "Moketi EUR" {
                toPayLocation = index
            }
        }
        
        if let serialLocation = docSerialSecondHalf?.0 {
            let secondHalfObservation = textObservations[serialLocation]
            docSerialFirstHalf = findOnTheSameLine(
                textObservations: textObservations,
                onSameLineAs: (serialLocation, secondHalfObservation)
            )
        }
        
        if let toPayTextLocation = toPayLocation {
            let secondHalfObservation = textObservations[toPayTextLocation]
            docSum = findOnTheSameLine(
                textObservations: textObservations,
                onSameLineAs: (toPayTextLocation, secondHalfObservation)
            ).1
        }
        
        print("SERIAL \(docSerialFirstHalf?.1) \(docSerialSecondHalf?.1)" ?? "2nd half serial not found")
        print("SUMA: \(docSum)" ?? "Sum not found")
        print("DATA \(docDate)" ?? "Date not found")
        
        let receipt = Receipt(context: moc)
                
        receipt.id = UUID()
        receipt.type = "IKI"
        receipt.image = UIImage(cgImage: image).pngData()
        receipt.date = docDate
        
        if let docSum = docSum {
            receipt.sum = (docSum.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".") as NSString).floatValue
            print(receipt.sum)
        }
        
        receipt.serial = docSerialFirstHalf?.1.replacingOccurrences(of: " ", with: "")
        receipt.longSerial = docSerialSecondHalf?.1.replacingOccurrences(of: " ", with: "")
        
        return receipt
    }
    
    func findOnTheSameLine(textObservations: [VNRecognizedTextObservation], onSameLineAs: (Int, VNRecognizedTextObservation)) -> (Int, String) {
        for textObservationLocation in stride(from: onSameLineAs.0 - 10, to: onSameLineAs.0 + 10, by: 1) {
            let currentObservation = textObservations[textObservationLocation]
            guard let candidate = currentObservation.topCandidates(1).first else { continue }
            let text = candidate.string
            if abs(currentObservation.bottomLeft.y - onSameLineAs.1.bottomLeft.y) < 0.01, textObservationLocation != onSameLineAs.0 {
                return (textObservationLocation, text)
            }
        }
        return (-1, "Not found")
    }
}
