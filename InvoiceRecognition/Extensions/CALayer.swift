//
//  CALayer.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 18.10.2020.
//

import CoreGraphics

extension CALayer {

    private func roundCorners(radius: CGFloat) {
        self.cornerRadius = radius
        if shadowOpacity != .zero {
            setShadowWithRoundedCorners()
        }
    }

    func setShadowWithRoundedCorners() {
        if let contents = self.contents {
            masksToBounds = false
            sublayers?.filter{ $0.frame.equalTo(self.bounds) }
                .forEach{ $0.roundCorners(radius: self.cornerRadius) }
            self.contents = nil
            if let sublayer = sublayers?.first, sublayer.name == "CustomContent" {
                sublayer.removeFromSuperlayer()
            }
            let contentLayer = CALayer()
            contentLayer.name = "CustomContent"
            contentLayer.contents = contents
            contentLayer.frame = bounds
            contentLayer.cornerRadius = cornerRadius
            contentLayer.masksToBounds = true
            insertSublayer(contentLayer, at: 0)
        }
    }
}
