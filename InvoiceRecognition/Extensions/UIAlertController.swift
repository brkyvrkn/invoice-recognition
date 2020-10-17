//
//  UIAlertController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 17.10.2020.
//

import UIKit
import Combine

extension UIAlertController {

    static func createSimpleAlert(title: String, message: String?) -> UIAlertController {
        let temp = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil)
        temp.addAction(okAction)
        return temp
    }
}
