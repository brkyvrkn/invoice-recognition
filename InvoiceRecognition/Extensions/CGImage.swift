//
//  CGImage.swift
//  PersonTracking
//
//  Created by Berkay Vurkan on 18.09.2019
//  Copyright © 2019 Temp. All rights reserved.
//

import Foundation
import UIKit

extension CGImage {

    /// Extract and render the frame in the type of CGImage
    ///
    /// - Parameter buffer: object
    /// - Returns: Frame image with pre-defined resolution (1920x1080 by default)
    static func create(from buffer: CVPixelBuffer) -> CGImage? {
        let ci = CIImage(cvPixelBuffer: buffer)
        return create(from: ci)
    }

    static func create(from ci: CIImage) -> CGImage? {
        return CIContext(options: nil).createCGImage(ci, from: ci.extent)
    }

    func rotate(radian: CGFloat) -> CGImage {
        guard let rotatedCG = UIImage(cgImage: self).rotate(radian: radian).cgImage else {
            return self
        }
        return rotatedCG
    }
}
