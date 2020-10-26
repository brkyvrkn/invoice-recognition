//
//  DateFormatter.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 26.10.2020.
//

import Foundation

extension DateFormatter {

    static let imageDateNameFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd"
        return formatter
    }()
}
