//
//  Speakeasy.swift
//  ImageSearch
//
//  Created by Levi McCallum on 8/29/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import UIKit
import Alamofire

public typealias ImageCompletionHandler = ([ImageResult]?, NSError?) -> Void

public class ImageSearch {

    let query: String

    var images: [ImageResult] = [] {
        didSet {
            completionHandler?(nil)
        }
    }
    var error: NSError? {
        didSet {
            completionHandler?(error)
        }
    }
    
    var completionHandler: ((NSError?) -> ())?
    
    var downloading: [ImageResult: Request] = [:]
    
    public var count: Int {
        return images.count
    }
    
    public init(query: String) {
        self.query = query
    }
    
    public func loadResults(data: [[String: AnyObject]]) {
        images = data.map({ ImageResult(result: $0) })
    }
    
    public func completion(handler: (NSError?) -> ()) -> ImageSearch {
        completionHandler = handler
        return self
    }
    
    // MARK: Image downloading
    
    public func resultAtIndexPath(indexPath: NSIndexPath) -> ImageResult {
        return images[indexPath.item]
    }
    
    public func imageAtIndexPath(indexPath: NSIndexPath, imageType type: ImageResultType) -> UIImage? {
        return imageAtIndexPath(indexPath, imageType: type, completionHandler: nil)
    }
    
    public func imageAtIndexPath(indexPath: NSIndexPath, imageType type: ImageResultType, completionHandler: ((UIImage!, NSError!) -> ())?) -> UIImage? {
        let imageResult = resultAtIndexPath(indexPath)
        if let image = imageResult.imageWithType(type) {
            return image
        }
        
        if downloading[imageResult] == nil && completionHandler != nil {
            println("Downloading :: \(imageResult.thumbnailURL) || \(indexPath)")
            downloading[imageResult] = imageResult.fetchImageWithType(type) { image, error in
                println("Downloaded :: \(imageResult.thumbnailURL) || \(imageResult.thumbnailType)")
                if let image = image {
                    completionHandler?(image, error)
                    self.downloading.removeValueForKey(imageResult)
                } else {
                    println("Error fetching image: \(imageResult): \(error)")
                }
            }
        }

        return nil
    }
    
    // MARK: Cancel
    
    public func cancelDownloads() {
        for (imageResult, request) in downloading {
            request.cancel()
            downloading.removeValueForKey(imageResult)
        }
    }
}

public class Speakeasy {
    let API_HOST = "api.gospeakeasy.com"
    let API_VERSION = "v1"
    
    public class var sharedInstance: Speakeasy {
        struct Singleton {
            static let instance = Speakeasy()
        }
        return Singleton.instance
    }
    
    var searchEndpoint: String {
        return "http://\(API_HOST)/\(API_VERSION)/photos/search.json"
    }
    
    public func searchImages(queries: [String], body: String) -> ImageSearch {
        let params = queryParams(queries, body: body)
        let search = ImageSearch(query: params["query"]! as String)
        Alamofire.request(.POST, searchEndpoint, parameters: params) .responseJSON { (request, response, json, error) in
            if let json = json as? [NSObject: AnyObject] {
                let images = json["images"]! as [[String: AnyObject]]
                search.loadResults(images)
            } else {
                search.error = error
            }
        }
        return search
    }
    
    public func searchImages(query: String, body: String) -> ImageSearch {
        return searchImages([query], body: body)
    }
    
    private func queryParams(queries: [String], body: String) -> [String: String] {
        let query = ",".join(queries)
        return ["query": query, "body": body]
    }
}

public func searchImages(query: String, #body: String) -> ImageSearch {
    return Speakeasy.sharedInstance.searchImages(query, body: body)
}
