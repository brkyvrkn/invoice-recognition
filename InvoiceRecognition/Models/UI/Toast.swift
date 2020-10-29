//
//  Toast.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 28.10.2020.
//

import Foundation

public enum ToastTime {
    case veryShort
    case short
    case long
    case veryLong

    var duration: Double {
        get {
            switch self {
            case .veryShort: return 1;
            case .short: return 1.5;
            case .long: return 2.5;
            case .veryLong: return 5;
            }
        }
    }
}

public class Toast: Component {
    var message: String
    var time: ToastTime

    init(message: String, time: ToastTime) {
        self.message = message
        self.time = time
        super.init(tag: 4000)
    }
}
