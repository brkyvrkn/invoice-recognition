//
//  CVEventCall.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 17.10.2020.
//

import Foundation
import Combine

public class CVEventCall: NSObject {

    public static let shared = CVEventCall()

    private override init() {
        // Singleton pattern
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

    private func detectFrame(data: Any?) -> CVResultModel? {
        guard let image = data as? UIImage else {
            NSLog("\(String(describing: type(of: self))):::::\(#function)> Given data is not UIImage")
            return nil
        }
        var result = CVResultModel(eventID: .detectFrame, data: data)
        if let framePoints = CVWrapper.analyzeFrame(image) {
            result.data = framePoints
            result.eventID = .invoiceRecognized
            result.error = nil
            return result
        }
        return nil
    }

    private func detectBarcode(data: Any?) -> CVResultModel? {
        guard let image = data as? UIImage else {
            NSLog("\(String(describing: type(of: self))):::::\(#function)> Given data is not UIImage")
            return nil
        }
        var result = CVResultModel(eventID: .detectBarcode, data: data)
        CVWrapper.detectBarcode(image)
        return nil
    }
}
