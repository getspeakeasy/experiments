//
//  UIView+AnchorPoint.swift
//  SpeakTest
//
//  Created by Levi McCallum on 9/6/14.
//  Copyright (c) 2014 Enigma Labs. All rights reserved.
//

import UIKit

extension UIView {
    // Changes the view layer's anchor point, while retaining the original position on screen.
    func spk_setAnchorPointInPlace(anchorPoint: CGPoint) {
        let newPoint = CGPoint(x: bounds.size.width * anchorPoint.x, y: bounds.size.height * anchorPoint.y)
        let oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y)
        var position = layer.position
        position.x = (position.x - oldPoint.x) + newPoint.x
        position.y = (position.y - oldPoint.y) + newPoint.y
        layer.position = position
        layer.anchorPoint = anchorPoint
    }
}
