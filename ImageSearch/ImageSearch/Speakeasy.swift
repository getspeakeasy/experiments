//
//  Speakeasy.swift
//  ImageSearch
//
//  Created by Levi McCallum on 8/29/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import UIKit
import Alamofire

public class Speakeasy {
    let API_HOST = "api.gospeakeasy.com"
    let API_VERSION = "v1"
    
    public func searchPhotos(queries: [String], body: String, completion: ([[String: AnyObject]]?, NSError?) -> Void) {
        let query = ",".join(queries)
        let params = ["query": query, "body": body]
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        Alamofire.request(.POST, "http://\(API_HOST)/\(API_VERSION)/photos/search.json", parameters: params)
                 .responseJSON { (request, response, json, error) in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let json = json as? [NSObject: AnyObject] {
                        let rawImages: AnyObject? = json["images"] // Swift doesn't let me downcase from a subscript :(
                        let images = rawImages as? [[String: AnyObject]]
                        println("Speakeasy: Images: \(images)")
                        completion(images, nil)
                    }
                 }
    }
}
