//
//  CVEventCall.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 17.10.2020.
//

import Foundation
import AVFoundation
import Combine

public class CVEventCall: NSObject {

    public static let shared = CVEventCall()
    private var eventKVOToken: NSKeyValueObservation?

    private override init() {
        // Singleton pattern
    }

    deinit {
        self.stopListening()
    }

    public func sendCommand(eventID: CVEventID, data: Any?) -> Future<CVResultModel?, Never> {
        switch eventID {
        case .detectFrame:
            return Future { promise in
                promise(.success(self.detectFrame(data: data)))
            }
        case .detectBarcode:
            return Future { promise in
                promise(.success(self.detectBarcode(data: data)))
            }
        default:
            return Future { promise in
                promise(.success(nil))
            }
        }
    }

    public func listen(eventID: CVEventID) -> PassthroughSubject<CVResultModel?, Never> {
        let subject = PassthroughSubject<CVResultModel?, Never>()
        switch eventID {
        case .lastProcessedImage:
            self.eventKVOToken = CVWrapper.observe(\.lastProcessedFrame, options: [.old, .new]) { (_, image) in
                guard let newImage = image.newValue else {
                    NSLog("\(String(describing: type(of: self))):::::\(#function)> Newly processed image did not recognize")
                    return
                }
                let res = CVResultModel(eventID: .lastProcessedImage, data: newImage, error: nil)
                subject.send(res)
            }
        default:
            break
        }
        return subject
    }

    public func stopListening() {
        if eventKVOToken != nil {
            eventKVOToken?.invalidate()
        }
    }

    private func detectFrame(data: Any?) -> CVResultModel? {
        if let image = data as? UIImage {
            CVWrapper.analyzeFrame(image)
            //TODO: return recognized ROI in result model
            return CVResultModel(eventID: .detectFrame, data: CVWrapper.lastBoundingBox)
        } else {
            NSLog("\(String(describing: type(of: self))):::::\(#function)> Given data is not UIImage")
            return nil
        }
    }

    private func detectBarcode(data: Any?) -> CVResultModel? {
        guard let image = data as? UIImage else {
            NSLog("\(String(describing: type(of: self))):::::\(#function)> Given data is not UIImage")
            return nil
        }
        CVWrapper.detectBarcode(image)
        return CVResultModel(eventID: .detectBarcode, data: CVWrapper.lastBoundingBox)
    }
}
