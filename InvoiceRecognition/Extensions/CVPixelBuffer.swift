//
//  CVPixelBuffer.swift
//  PersonTracking
//
//  Created by Berkay Vurkan on 18.09.2019
//  Copyright © 2019 Temp. All rights reserved.
//

import Foundation
import UIKit

extension CVPixelBuffer {
    
    func convertPixelBufferToCGImage() -> CGImage? {
        do {
            CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
            defer {
                CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
            }
            let address = CVPixelBufferGetBaseAddressOfPlane(self, 0)
            let bytes = CVPixelBufferGetBytesPerRow(self)
            let width = CVPixelBufferGetWidth(self)
            let height = CVPixelBufferGetHeight(self)
            let color = CGColorSpaceCreateDeviceRGB()
            let bits = 8
            let info = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
            guard let context = CGContext(data: address, width: width, height: height, bitsPerComponent: bits, bytesPerRow: bytes, space: color, bitmapInfo: info) else {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Could not create an CGContext")
                return nil
            }
            guard let image = context.makeImage() else {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Could not create an CGImage")
                return nil
            }
            return image
        }
    }
}
