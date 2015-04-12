//
//  PostTextView
//  SpeakKit
//
//  Created by Levi McCallum on 8/25/14.
//  Copyright (c) 2014 Enigma Labs. All rights reserved.
//

import UIKit

public class PostTextView: UIView {

    public weak var textView: UITextView!
    
    var layoutManager: NSLayoutManager!
    var textContainer: NSTextContainer!
    var textStorage: NSTextStorage!

    var lineHeight: CGFloat = 33.0

    public var text: String? {
        didSet {
            if text == nil { return }
            let attributedText = NSMutableAttributedString(string: text!, attributes: [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: UIColor.whiteColor(),
            ])
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .Center
            paragraphStyle.minimumLineHeight = lineHeight
            attributedText.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))

            let shadow = NSShadow()
            shadow.shadowColor = UIColor(white: 0, alpha: 0.75)
            shadow.shadowBlurRadius = 6.5
            shadow.shadowOffset = CGSize(width: 0, height: 2)
            attributedText.addAttribute(NSShadowAttributeName, value: shadow, range: NSRange(location: 0, length: attributedText.length))

            textStorage.beginEditing()
            textStorage.replaceCharactersInRange(NSRange(location: 0, length: textStorage.length), withAttributedString: attributedText)
            textStorage.endEditing()

            println("Text storage: \(textStorage.string)")
        }
    }
    
    var editable: Bool = true {
        didSet {
            textView.editable = editable
            textView.selectable = editable
        }
    }

    var font: UIFont!
    var lineRects: [CGRect]?

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        backgroundColor = UIColor.clearColor()
        contentMode = .Redraw
        
        font = UIFont(name: "HelveticaNeue-Bold", size: 28)

        let textViewFrame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: 568.0 - 40.0)
//        println("Text View Frame: \(textViewFrame)")

        layoutManager = NSLayoutManager()
        layoutManager.delegate = self

        textStorage = NSTextStorage()

        textContainer = NSTextContainer(size: textViewFrame.size)
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let textView = UITextView(frame: CGRectZero, textContainer: textContainer)
        textView.textAlignment = NSTextAlignment.Center
        textView.backgroundColor = UIColor.clearColor()
        textView.setTranslatesAutoresizingMaskIntoConstraints(false)
        textView.returnKeyType = .Done
        textView.scrollEnabled = false
        addSubview(textView)
        self.textView = textView

        var constraints: [AnyObject] = []
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[textView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["textView": textView])
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[textView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["textView": textView])
        addConstraints(constraints)
    }
    
    public override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        if let rects = lineRects {
            for rect in rects {
//                println("Drawing line fragment rect: \(rect)")
                UIColor(white: 0, alpha: 0.5).setFill()
                CGContextFillRect(context, rect)
            }
        }
        super.drawRect(rect)
    }
    
    public override func intrinsicContentSize() -> CGSize {
        var height: CGFloat
        if let lineRects = lineRects {
            height = CGRectGetMinY(lineRects.first!) + CGRectGetMaxY(lineRects.last!) + font.lineHeight
        } else {
            height = font.lineHeight
        }
        return CGSize(width: UIViewNoIntrinsicMetric, height: height)
    }
    
    public override func resignFirstResponder() -> Bool {
        if textView.isFirstResponder() {
            return textView.resignFirstResponder()
        }
        return super.resignFirstResponder()
    }
}

extension PostTextView: NSLayoutManagerDelegate {
    public func layoutManager(layoutManager: NSLayoutManager!, didCompleteLayoutForTextContainer textContainer: NSTextContainer!, atEnd layoutFinishedFlag: Bool) {
        if text != nil {
//            println("Layout manager completed layout. at end? \(layoutFinishedFlag)")
            lineRects = relativeLineFragmentRects()
            setNeedsDisplay()
            invalidateIntrinsicContentSize()
        }
    }
}

extension PostTextView {
    func relativeLineFragmentRects() -> [CGRect] {
        var lineRects: [CGRect] = []

        let glyphRange = layoutManager.glyphRangeForTextContainer(textContainer)
        layoutManager.enumerateLineFragmentsForGlyphRange(glyphRange) { rect, usedRect, textContainer, lineGlyphRange, stop in
            if let lineRect = self.lineRect(forRect: usedRect, lineGlyphRange: lineGlyphRange) {
//                println("Line rect: \(lineRect)")
                lineRects.append(lineRect)
            }
        }
        
        return lineRects
    }

    var currentFont: UIFont {
        return textStorage.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: nil) as UIFont
    }

    var glyphHeight: CGFloat {
        return currentFont.ascender + padding
    }

    var padding: CGFloat {
        return 4.0
    }

    func lineRect(forRect rect: CGRect, lineGlyphRange: NSRange) -> CGRect? {
        // Prevent rendering of one-off line highlights with no text
        if lineGlyphRange.length == 1 { return nil }
//        self.debug_traceCharacterTypesIn(lineGlyphRange)
        return CGRect(origin: lineRectOrigin(rect), size: lineRectSize(rect, lineGlyphRange: lineGlyphRange))
    }

    func lineRectWidth(rect: CGRect, lineGlyphRange: NSRange) -> CGFloat {
        // automatic line wrap will insert .Elastic then .Null before the next line. Remove the .Elastic rectangle
        // from the current line to make for a nicer rectangle
        var lineWidth = rect.width
        var elasticIndex = NSMaxRange(lineGlyphRange) - 1
        var prevIndex = elasticIndex - 1
        var elasticProperty = self.layoutManager.propertyForGlyphAtIndex(elasticIndex)
        var prevProperty = self.layoutManager.propertyForGlyphAtIndex(prevIndex)

        // When a double line break is manually inserted, the elastic glyph is actually the 3rd last in the line.
        // Here we handle that edge case by looking behind
        if elasticProperty == NSGlyphProperty.Elastic ||
           (elasticProperty == NSGlyphProperty.ControlCharacter && prevProperty == NSGlyphProperty.Elastic) {
            if prevProperty == NSGlyphProperty.Elastic { elasticIndex = prevIndex }

            var whiteSpaceRect = self.layoutManager.boundingRectForGlyphRange(NSRange(location: elasticIndex, length: 1), inTextContainer: self.textContainer)
//            println("Line width: \(lineWidth)")
            lineWidth -= whiteSpaceRect.size.width
//            println("Adjusted line width: \(lineWidth)")
        }

        return lineWidth
    }

    func lineRectOrigin(rect: CGRect) -> CGPoint {
        return CGPoint(x: rect.origin.x, y: lineRectYOrigin(rect))
    }

    func lineRectYOrigin(rect: CGRect) -> CGFloat {
        return CGRectGetMaxY(rect) - glyphHeight - currentFont.descender + padding / 2.0
    }

    func lineRectSize(rect: CGRect, lineGlyphRange: NSRange) -> CGSize {
        return CGSize(width: lineRectWidth(rect, lineGlyphRange: lineGlyphRange), height: glyphHeight)
    }

    // Identify types of characters, for debugging
    func debug_traceCharacterTypesIn(lineGlyphRange: NSRange) {
        for idx in lineGlyphRange.location...NSMaxRange(lineGlyphRange) {
            self.layoutManager.enumerateEnclosingRectsForGlyphRange(NSRange(location: idx, length: 1), withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), inTextContainer: self.textContainer, usingBlock: {
                rect, stop in
                print("Encosing rect for glyph \(idx): \(rect) ")
                switch self.layoutManager.propertyForGlyphAtIndex(idx) {
                    case .Null:
                        println("Property type: Null")
                    case .ControlCharacter:
                        println("Property type: ControlCharacter")
                    case .Elastic:
                        println("Property type: Elastic")
                    case .NonBaseCharacter:
                        println("Property type: Non Base Character")
                }
            })
        }
    }
}