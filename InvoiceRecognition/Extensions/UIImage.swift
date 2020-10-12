//
//  UIImage.swift
//  PersonTracking
//
//  Created by Berkay Vurkan on 20.09.2019
//  Copyright © 2019 Temp. All rights reserved.
//

import Foundation


extension UIImage {

    func saveToDocuments(filename:String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        if let data = self.jpegData(compressionQuality: 1.0), !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try data.write(to: fileURL)
                NSLog("\(String(describing: type(of: self))):::::\(#function)> File saved to %@", fileURL.path)
            } catch {
                NSLog("\(String(describing: type(of: self))):::::\(#function)> Error saving file to documents, %@", error.localizedDescription)
            }
        }
    }

    func rotate(radian: CGFloat) -> UIImage {
        let rotatedsize = CGRect(origin: .zero, size: size).applying(CGAffineTransform(rotationAngle: radian)).integral.size
        UIGraphicsBeginImageContext(rotatedsize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedsize.width / 2, y: rotatedsize.height / 2)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radian)
            draw(in: CGRect(x: -origin.y, y: -origin.x, width: size.width, height: size.height))
            let rotated = UIGraphicsGetImageFromCurrentImageContext()
            return rotated ?? self
        }
        return self
    }
}
