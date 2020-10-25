//
//  CVEventModels.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 17.10.2020.
//

import Foundation

///
public enum CVEventID: Equatable, Hashable {

    case detectFrame
    case detectBarcode
    case invoiceRecognized
    // lastProcessedImage has listener
    case lastProcessedImage

    public var keyPath: String {
        get {
            switch self {
            case .detectFrame:
                return "CV_DETECT_FRAME"
            case .detectBarcode:
                return "CV_DETECT_BARCODE"
            case .invoiceRecognized:
                return "CV_INVOICE_RECOGNIZED"
            case .lastProcessedImage:
                return "CV_LAST_PROCESSED_IMAGE"
            }
        }
    }

    public static func ==(_ lhs: CVEventID, _ rhs: CVEventID) -> Bool {
        return lhs.keyPath == rhs.keyPath
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.keyPath)
    }
}

public struct CVResultModel {
    var eventID: CVEventID
    var data: Any?
    var error: CVEventErrorModel?
}

public struct CVEventErrorModel: Error {
    var code: Int
    var message: String

    public static let dataIsNotUIImage = CVEventErrorModel(code: 1000, message: NSLocalizedString("Wrong data type", comment: ""))
    public static let invalidEvent = CVEventErrorModel(code: 1001, message: NSLocalizedString("Invalid event type", comment: ""))
}
