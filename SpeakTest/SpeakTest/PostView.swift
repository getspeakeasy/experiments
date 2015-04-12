//
//  PostView.swift
//  SpeakKit
//
//  Created by Levi McCallum on 8/25/14.
//  Copyright (c) 2014 Enigma Labs. All rights reserved.
//

import UIKit

@IBDesignable public class PostView: UIView {
    
    @IBInspectable public var backgroundImage: UIImage! {
        didSet {
            imageView.image = backgroundImage.spk_resizeToBackground(backgroundSize: intrinsicContentSize())
        }
    }
    
    @IBInspectable public var postText: String! {
        didSet {
            textView.text = postText
        }
    }
    
    @IBInspectable public var editable: Bool = true {
        didSet {
            textView.editable = editable
        }
    }
    
    private weak var imageView: UIImageView!
    private weak var textView: PostTextView!
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        clipsToBounds = true
        // TODO: Add shadow
        // TODO: Add corner radius
        
        imageView = createImageView()
        textView = createTextView()

        addConstraints(subviewConstraints)
    }
    
    private func createImageView() -> UIImageView {
        var imageView = UIImageView()
        imageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        imageView.contentMode = .ScaleAspectFill
        addSubview(imageView)
        return imageView
    }
    
    private func createTextView() -> PostTextView {
        var textView = PostTextView(frame: CGRectZero)
        textView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(textView)
        return textView
    }

    var subviewConstraints: [AnyObject] {
        var constraints: [AnyObject] = []
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[image(>=320)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["image": imageView])
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[image]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["image": imageView])
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-[textView]-|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["textView": textView])
        constraints.append(NSLayoutConstraint(item: textView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0))
        return constraints
    }

    public override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 320.0, height: 568.0)
    }
    
    // MARK: First responder

    override public func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }

}

public extension PostView {
    public func textImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
//        println("Text View: \(textView)")
        let drawSuccess = textView.drawViewHierarchyInRect(textView.frame, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
