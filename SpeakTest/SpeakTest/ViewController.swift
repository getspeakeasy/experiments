//
//  ViewController.swift
//  SpeakTest
//
//  Created by Levi McCallum on 8/20/14.
//  Copyright (c) 2014 Enigma Labs. All rights reserved.
//

import UIKit
import SpeakKit

let PickerBottomOffset: CGFloat = 75.0

class ViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fontButton: UIButton!
    @IBOutlet weak var imageButton: UIButton!

    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!

    weak var imagePickerView: ImagePickerView!
    weak var postView: PostView!
    
    var bodyText: String!
    var searchResults: [[String: AnyObject]] = []
    
    var imageSearch: ImageSearch!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "background"))
        setupKeyboardObservers()

        bodyText = "What if every country has ninjas, but we only know about the Japanese ones because they’re rubbish?"
        postView = setupPostView()

        let tapGesture = UITapGestureRecognizer(target: self, action: "tappedScrollView:")
        scrollView.addGestureRecognizer(tapGesture)
        scrollView.contentSize = postView.frame.size
        scrollView.delegate = self
        
        imagePickerView = setupImagePicker()
    }
    
    deinit {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        nc.removeObserver(self, name: UIKeyboardDidHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: "keyboardDidHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func setupPostView() -> PostView {
        var postView = PostView(frame: CGRect(x: 0, y: 20, width: 320, height: 568))
        postView.postText = bodyText
        postView.backgroundImage = UIImage(named: "ninja")
        scrollView.addSubview(postView)
        postView.spk_setAnchorPointInPlace(CGPoint(x: 0.5, y: 0))
        return postView
    }
    
    var imagePickerViewSize: CGSize {
        return CGSize(width: self.view.bounds.size.width, height: 170)
    }
    
    var imagePickerViewOrigin: CGPoint {
        return CGPoint(x: 0, y: view.bounds.size.height - (imagePickerViewSize.height + PickerBottomOffset))
    }
    
    func setupImagePicker() -> ImagePickerView {
        let imagePickerFrame = CGRect(origin: imagePickerViewOrigin, size: imagePickerViewSize)
        println("Image picker frame: \(imagePickerFrame)")
        
        let imagePicker = ImagePickerView(frame: imagePickerFrame)
        imagePicker.dataSource = self
        imagePicker.delegate = self
        view.addSubview(imagePicker)

        imagePicker.spk_setAnchorPointInPlace(CGPoint(x: 0.63, y: 1.0))
        imagePicker.hidden = true
        
        return imagePicker
    }

    // MARK: Keyboard handling
    
    func keyboardDidShow(note: NSNotification) {
        let keyboardFrame: NSValue! = note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        let keyboardHeight = CGRectGetHeight(keyboardFrame.CGRectValue())
        println("Keyboard height: \(keyboardHeight)")

        let duration = (note.userInfo![UIKeyboardAnimationDurationUserInfoKey]! as NSNumber).doubleValue
        let curve = (note.userInfo![UIKeyboardAnimationCurveUserInfoKey]! as NSNumber).integerValue
        
        let options = UIViewAnimationOptions(UInt(curve << 16))
        
        if imagePickerView.hidden == false {
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: {
                var toFrame = self.imagePickerView.frame
                toFrame.origin.y = self.view.bounds.size.height - (toFrame.size.height + keyboardHeight)
                self.imagePickerView.frame = toFrame
            }, completion: nil)
            return
        }
        
        UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: options, animations: {
            self.postView.transform = CGAffineTransformMakeScale(0.8, 0.8)
            self.scrollView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: keyboardHeight, right: 0)
            self.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            self.scrollView.contentSize = self.postView.frame.size
        }, completion: nil)
    }
    
    func keyboardDidHide(note: NSNotification) {
        let keyboardFrame: NSValue! = note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        let keyboardHeight = CGRectGetHeight(keyboardFrame.CGRectValue())
        let duration = (note.userInfo![UIKeyboardAnimationDurationUserInfoKey]! as NSNumber).doubleValue
        let curve = (note.userInfo![UIKeyboardAnimationCurveUserInfoKey]! as NSNumber).integerValue
        
        let options = UIViewAnimationOptions(UInt(curve << 16))
        
        if imagePickerView.hidden == false {
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: {
                var toFrame = self.imagePickerView.frame
                toFrame.origin.y = self.imagePickerViewOrigin.y
                self.imagePickerView.frame = toFrame
            }, completion: nil)
            return
        }
        
        UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: options, animations: {
            self.postView.transform = CGAffineTransformIdentity
            self.scrollView.contentInset = UIEdgeInsetsZero
            self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero
        }) { completed in }
    }
    
    func tappedScrollView(gesture: UITapGestureRecognizer) {
        postView.resignFirstResponder()
        imagePickerView?.resignFirstResponder()
    }
    
    @IBAction func toggleImagePicker(sender: UIButton) {
        if imagePickerView.hidden {
            // View doesn't use AutoLayout, initially inserts itself as the bottom view
            view.bringSubviewToFront(imagePickerView)
            
            imagePickerView.transform = CGAffineTransformMakeScale(0.01, 0.01)
            imagePickerView.hidden = false
            self.imageButton.selected = true

            UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: nil, animations: {
                self.imagePickerView.transform = CGAffineTransformIdentity
            }, completion: nil)
            
            UIView.animateWithDuration(0.3, delay: 0.1, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self.postView.transform = CGAffineTransformMakeScale(0.6, 0.6)
                self.scrollView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
                self.scrollView.contentSize = self.postView.frame.size
                self.scrollViewBottomConstraint.constant = 244
                self.view.layoutIfNeeded()
            }, completion: { completed in
                self.postView.editable = false
            })
        } else {
            UIView.animateWithDuration(0.2, animations: {
                self.imagePickerView.transform = CGAffineTransformMakeScale(0.01, 0.01)

                self.postView.transform = CGAffineTransformIdentity
                self.scrollView.contentInset = UIEdgeInsetsZero
                self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero

                self.scrollViewBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }, completion: { completed in
                self.postView.editable = true
                self.imagePickerView.hidden = true
                self.imageButton.selected = false
            })
        }
    }
    
    @IBAction func changeFont(sender: UIButton) {
    }

}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        println("Content offset: \(scrollView.contentOffset)")
        println("Content size: \(scrollView.contentSize)")
        println("Post view frame: \(postView.frame)")
        println("Post view position: \(postView.layer.position)")
        println("Post view anchor point: \(postView.layer.anchorPoint)")
    }
}

// MARK: ImagePickerView Data Source & Delegate

extension ViewController: ImagePickerViewDataSource, ImagePickerViewDelegate {
    func numberOfResultsForImagePicker(imagePicker: ImagePickerView) -> Int {
        return imageSearch?.count ?? 0
    }
    
    func previewTextOverlayForImagePicker(imagePicker: ImagePickerView) -> UIImage! {
        return postView.textImage()
    }
    
    // SHARED OBJECT?
    // Create an instance. But it's a manager object....
    // Does the result return a manager object?
    // Manager needs to be able to know about past queries
    // Needs to download select images
    // Cache them
    // Cancel downloads
    // Clear cache
    // But retain original imageresult objects
    
    // This app doesn't need to know about the manager object
    // All it wants is to know how many images are available, and how to get those images
    
    func imagePicker(imagePicker: ImagePickerView, thumbnailImageForResultCellAtIndexPath indexPath: NSIndexPath) -> UIImage! {
        let thumbnail = imageSearch.imageAtIndexPath(indexPath, imageType: .Thumbnail) { image, error in
            if let image = image {
                imagePicker.setThumbnailAtIndexPath(indexPath, thumbnail: image)
            }
        }
        return thumbnail ?? UIImage(named: "thumb_placeholder")
    }
    
    func imagePicker(imagePicker: ImagePickerView, didSearchWithQuery query: String) {
        println("Search for: \(query)")
        imageSearch = SpeakKit.searchImages(query, body: bodyText).completion({ error in
            self.imagePickerView.reloadData()
        })
    }
    
    func imagePicker(imagePicker: ImagePickerView, didSelectImageAtIndexPath indexPath: NSIndexPath) {
        let fullImage = imageSearch.imageAtIndexPath(indexPath, imageType: .FullSize) { image, error in
            if let image = image {
                self.postView.backgroundImage = image
            } else {
                println("Error loading full size image: \(error)")
            }
        }

        if let thumbnail = imageSearch.imageAtIndexPath(indexPath, imageType: .Thumbnail) {
            let blurredThumbnail = thumbnail.applyBlurWithRadius(5.0, tintColor: UIColor.clearColor(), saturationDeltaFactor: 1.0, maskImage: nil)
            postView.backgroundImage = fullImage ?? blurredThumbnail
        }
    }
}
