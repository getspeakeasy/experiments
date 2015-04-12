//
//  ImageResultCollectionViewCell.swift
//  SpeakTest
//
//  Created by Levi McCallum on 9/4/14.
//  Copyright (c) 2014 Enigma Labs. All rights reserved.
//

import UIKit

@IBDesignable public class ImageResultCollectionViewCell: UICollectionViewCell {
    
    public var thumbnailImage: UIImage! {
        didSet {
            thumbnailView.image = thumbnailImage
        }
    }
    
    public var textPreviewImage: UIImage! {
        didSet {
            textPreviewView.image = textPreviewImage
        }
    }
    
    weak var thumbnailView: UIImageView!
    weak var textPreviewView: UIImageView!
    weak var selectedBorder: CALayer!
    
    // TODO: Replace with class computed property when available
    public class func reuseIdentifier() -> String {
       return "ImageResultCell"
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override public func prepareForReuse() {
        self.selectedBorder.hidden = !selected
    }
    
    func setup() {
        contentView.layer.cornerRadius = 2.0
        backgroundColor = UIColor.clearColor()

        self.thumbnailView = createImageView()
        self.textPreviewView = createImageView()
    
        var selectedBorder = CALayer()
        selectedBorder.frame = contentView.bounds
        selectedBorder.borderWidth = 2
        selectedBorder.borderColor = tintColor.CGColor
        selectedBorder.hidden = !selected
        contentView.layer.addSublayer(selectedBorder)
        self.selectedBorder = selectedBorder
    }
    
    func createImageView() -> UIImageView {
        let imageView = UIImageView(frame: self.bounds)
        imageView.contentMode = UIViewContentMode.ScaleToFill
        contentView.addSubview(imageView)
        return imageView
    }
    
    public func toggleSelection(selected: Bool) {
        selectedBorder.hidden = !selected
    }
    
}
