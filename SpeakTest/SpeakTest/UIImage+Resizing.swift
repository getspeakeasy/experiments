//
//  UIImage+Resizing.swift
//  SpeakTest
//
//  Created by Levi McCallum on 8/28/14.
//  Copyright (c) 2014 Enigma Labs. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func spk_resizeToBackground(#backgroundSize: CGSize) -> UIImage {
        var image: UIImage = self

        let horizontalRatio = size.width / backgroundSize.width
        let verticalRatio = size.height / backgroundSize.height
        let ratio = min(horizontalRatio, verticalRatio)

        image = spk_scaleToFit(size: CGSize(width: size.width / ratio, height: size.height / ratio))
        
        let scaledOrigin = CGPoint(x: floor((image.size.width - backgroundSize.width) * 0.5), y: floor((image.size.height - backgroundSize.height) * 0.5))
        image = image.spk_crop(rect: CGRect(origin: scaledOrigin, size: backgroundSize))

        return image
    }

    func spk_crop(#rect: CGRect) -> UIImage {
        return UIImage(CGImage: CGImageCreateWithImageInRect(CGImage, rect))
    }

    func spk_scaleToFit(#size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        drawInRect(CGRect(origin: CGPointZero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}