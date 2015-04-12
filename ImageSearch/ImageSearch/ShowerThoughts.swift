//
//  ShowerThoughts.swift
//  ImageSearch
//
//  Created by Levi McCallum on 8/30/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import UIKit
import Alamofire

public class ShowerThoughts {
    public class func top(completion: ([String]) -> ()) {
        let endPoint = "http://www.reddit.com/r/Showerthoughts/top.json"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        Alamofire.request(.GET, endPoint, parameters: nil, encoding: .JSON)
                 .responseJSON { (request, response, json, error) -> Void in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let json = json as? NSDictionary {
                        let children = json["data"]!["children"]! as [AnyObject]
                        let thoughts = children.map { ($0 as NSDictionary)["data"]!["title"]! as String }
                        completion(thoughts)
                    }
                 }
    }
}
