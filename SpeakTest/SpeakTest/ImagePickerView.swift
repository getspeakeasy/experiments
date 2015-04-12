//
//  ImagePicker.swift
//  SpeakTest
//
//  Created by Levi McCallum on 9/2/14.
//  Copyright (c) 2014 Enigma Labs. All rights reserved.
//

import UIKit

public protocol ImagePickerViewDataSource {
    func numberOfResultsForImagePicker(imagePicker: ImagePickerView) -> Int
    func previewTextOverlayForImagePicker(imagePicker: ImagePickerView) -> UIImage!
    func imagePicker(imagePicker: ImagePickerView, thumbnailImageForResultCellAtIndexPath indexPath: NSIndexPath) -> UIImage!
}

public protocol ImagePickerViewDelegate {
    func imagePicker(imagePicker: ImagePickerView, didSelectImageAtIndexPath indexPath: NSIndexPath)
    func imagePicker(imagePicker: ImagePickerView, didSearchWithQuery query: String)
}

public class ImagePickerView: UIView {

    var imageCollection: UICollectionView!
    var collectionLayout: UICollectionViewFlowLayout!
    var searchField: UITextField!
    
    public var dataSource: ImagePickerViewDataSource!
    public var delegate: ImagePickerViewDelegate?
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        backgroundColor = UIColor.whiteColor()
        drawTopBorder()
        
        searchField = setupSearchField()
        collectionLayout = setupCollectionLayout()
        imageCollection = setupCollectionView()
        addConstraints(subviewConstraints)
        
        imageCollection.registerClass(ImageResultCollectionViewCell.self, forCellWithReuseIdentifier: ImageResultCollectionViewCell.reuseIdentifier())
    }
    
    func drawTopBorder() {
        let topBorder = CALayer()
        topBorder.frame = CGRectMake(0, 0, bounds.size.width, 2)
        topBorder.backgroundColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1).CGColor
        layer.addSublayer(topBorder)
    }
    
    func setupCollectionView() -> UICollectionView {
        var collection = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionLayout)
        collection.dataSource = self
        collection.delegate = self
        collection.setTranslatesAutoresizingMaskIntoConstraints(false)
        collection.backgroundColor = UIColor.clearColor()

        addSubview(collection)
        
        return collection
    }
    
    func setupCollectionLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.itemSize = CGSize(width: 64, height: 113.6)
        layout.minimumInteritemSpacing = 8.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        return layout
    }
    
    func setupSearchField() -> UITextField {
        var field = UITextField(frame: CGRectZero)
        field.delegate = self
        field.setTranslatesAutoresizingMaskIntoConstraints(false)
        field.placeholder = "Change Search..."
        field.background = UIImage(named: "search_bg")
        field.textColor = UIColor(red: 18/255.0, green: 19/255.0, blue: 19/255.0, alpha: 1.0)
        field.backgroundColor = UIColor.whiteColor()
        field.returnKeyType = .Search
        
        let searchIcon = UIImage(named: "search_icon")
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: searchIcon.size.width + 30.0, height: searchIcon.size.height))
        let iconView = UIImageView(image: searchIcon)
        iconView.frame = CGRect(origin: CGPoint(x: 15.0, y: 0), size: iconView.frame.size)
        leftView.addSubview(iconView)
        field.leftView = leftView
        field.leftViewMode = .Always
        
        addSubview(field)

        return field
    }
    
    var subviewConstraints: [AnyObject] {
        var constraints: [AnyObject] = []
        let options = NSLayoutFormatOptions(0)

        constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[collection]|", options: options,
            metrics: nil,
            views: ["collection": imageCollection])
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[collection]-0-[field(38)]|", options: options,
            metrics: nil,
            views: ["collection": imageCollection, "field": searchField])
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[field]|", options: options,
            metrics: nil,
            views: ["field": searchField])

        return constraints
    }
    
    override public func resignFirstResponder() -> Bool {
        if searchField.isFirstResponder() {
            return searchField.resignFirstResponder()
        }
        return super.resignFirstResponder()
    }
    
    public func reloadData() {
        imageCollection.reloadData()
        imageCollection.setContentOffset(CGPointZero, animated: false)
    }
    
    // MARK: Set Thumbnail Image
    
    public func setThumbnailAtIndexPath(indexPath: NSIndexPath, thumbnail: UIImage) {
        let cell = imageCollection.cellForItemAtIndexPath(indexPath) as? ImageResultCollectionViewCell
        cell?.thumbnailImage = thumbnail
    }

}

extension ImagePickerView: UICollectionViewDataSource {

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfResultsForImagePicker(self)
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = ImageResultCollectionViewCell.reuseIdentifier()
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as ImageResultCollectionViewCell
        cell.textPreviewImage = dataSource.previewTextOverlayForImagePicker(self)
        cell.thumbnailImage = dataSource.imagePicker(self, thumbnailImageForResultCellAtIndexPath: indexPath)
        return cell
    }

}

extension ImagePickerView: UICollectionViewDelegateFlowLayout {

    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as ImageResultCollectionViewCell
        cell.toggleSelection(true)
        delegate?.imagePicker(self, didSelectImageAtIndexPath: indexPath)
    }

}

extension ImagePickerView: UITextFieldDelegate {
    public func textFieldDidBeginEditing(textField: UITextField) {
        textField.selectAll(self)
        UIMenuController.sharedMenuController().menuVisible = false
    }

    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        let query = searchField.text
        delegate?.imagePicker(self, didSearchWithQuery: query)
        return true
    }
}
