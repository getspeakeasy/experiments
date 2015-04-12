//
//  ImageResult.swift
//  SpeakKit
//
//  Created by Levi McCallum on 9/7/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import Foundation
import Alamofire

public enum ImageResultType {
    case FullSize
    case Thumbnail
}

public class ImageResult {

    public let URL: NSURL
    public let size: CGSize
    public let imageType: String
    public var image: UIImage?

    public let thumbnailURL: NSURL
    public let thumbnailSize: CGSize
    public let thumbnailType: String
    public var thumbnailImage: UIImage?

    public init(result: [String: AnyObject]) {
        URL = NSURL(string: result["src"]! as String)
        let width = (result["w"]! as NSString).floatValue
        let height = (result["h"]! as NSString).floatValue
        size = CGSize(width: CGFloat(width), height: CGFloat(height))
        imageType = result["src_type"]! as String

        thumbnailURL = NSURL(string: result["thumb_src"]! as String)
        let thumbnailWidth = (result["thumb_w"]! as NSString).floatValue
        let thumbnailHeight = (result["thumb_h"]! as NSString).floatValue
        thumbnailSize = CGSize(width: CGFloat(thumbnailWidth), height: CGFloat(thumbnailHeight))
        thumbnailType = result["thumb_type"]! as String
    }
    
    public func imageWithType(type: ImageResultType) -> UIImage? {
        switch type {
            case .FullSize:
                return image
            case .Thumbnail:
                return thumbnailImage
        }
    }
    
    public func fetchImageWithType(type: ImageResultType, completionHandler: (UIImage!, NSError!) -> ()) -> Request {
        let request = Alamofire.request(.GET, URLWithType(type).absoluteString!, parameters: nil, encoding: .URL)
        request.response { request, response, data, error in
            if let data = data as? NSData {
                let image = UIImage(data: data)
                switch type {
                    case .FullSize:
                        self.image = image
                    case .Thumbnail:
                        self.thumbnailImage = image
                }
                completionHandler(image, nil)
            } else {
                completionHandler(nil, error)
            }
        }
        return request
    }
    
    func URLWithType(type: ImageResultType) -> NSURL {
        switch type {
            case .FullSize:
                return URL
            case .Thumbnail:
                return thumbnailURL
        }
    }

}

extension ImageResult: Printable, Hashable {
    public var hashValue: Int {
        return thumbnailURL.absoluteString!.hashValue
    }
    
    public var description: String {
        return "<ImageResult\(size) URL:\(URL)>"
    }
}

public func ==(lhs: ImageResult, rhs: ImageResult) -> Bool {
    return lhs.thumbnailURL == rhs.thumbnailURL
}
