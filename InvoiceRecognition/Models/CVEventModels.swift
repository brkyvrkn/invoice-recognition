//
//  CVEventModels.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 17.10.2020.
//

import Foundation

public enum CVEventID: Equatable, Hashable {

    case detectFrame
    case detectBarcode
    case invoiceRecognized
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
