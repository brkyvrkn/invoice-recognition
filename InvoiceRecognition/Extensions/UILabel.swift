//
//  UILabel.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

import UIKit

extension UILabel {

    func startBlink() {
        UIView.animate(withDuration: 0.8,
                       delay:0.0,
                       options:[.allowUserInteraction, .curveEaseInOut, .autoreverse, .repeat],
                       animations: { self.alpha = 0 },
                       completion: nil)
    }

    func stopBlink() {
        layer.removeAllAnimations()
        alpha = 1
    }

    func setLeftAttachtedText(_ image: UIImage?, text: String) {
        guard let safeImage = image else {
            attributedText = NSAttributedString(string: text)
            return
        }
        let icon = NSTextAttachment()
        let centerY = (font.capHeight - safeImage.size.height).rounded() / 2

        icon.image = safeImage
        icon.bounds = CGRect(origin: .init(x: .zero, y: centerY), size: safeImage.size)

        let attrStr = NSAttributedString(string: "  " + text)
        let mutAttrStr = NSMutableAttributedString(attachment: icon)
        mutAttrStr.append(attrStr)

        attributedText = mutAttrStr
    }
}
