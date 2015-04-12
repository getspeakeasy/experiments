//
//  ViewController.swift
//  ImageSearch
//
//  Created by Levi McCallum on 8/26/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var thoughts = [
        "The word 'apart' is spelled together but means seperate. Meanwhile, 'a part' of something is spelled seperate and means together.",
        "If I touch my phone in the right places, a pizza will show up at my front door.",
        "War is pay to win.",
        "Glasses change how you look, and how you look.",
        "We can say anything we want about the Amish over the internet and they will never find out.",
        "People with bad spelling have the best passwords",
        "Every minute that goes by, there are 13.8 years of time lived by everyone of the earth's population",
        "There should be a gameshow where a girl tells 10 tinder matches to meet up at the same place and they have to compete to win her heart",
        "All those rappers that bought huge gold chains in the 80's and 90's actually made pretty prudent investments",
        "When The Simpsons first aired, I was 10 years old, the same age as Bart. Today, I am Homer's age",
        "Rap songs that reference dollar values won't adjust for inflation and the references will sound cheaper over time.",
        "This year's Penn State graduating class will be PEN15",
        "Kids born in the year 2000 will never have to worry about forgetting how old they are.",
        "The Star Wars title crawls are still floating through space.",
    ]
    
    var currentThought = 0
    
    var thumbURLs: [String] = [] {
        didSet {
            println("Image Search: Loaded \(thumbURLs.count) thumbnails")
            thumbnailDownloads = [:]
            downloaded = [:]
            resultsTableView.reloadData()
        }
    }
    
    var thumbnailDownloads: [NSIndexPath: String] = [:]
    var downloaded: [String: UIImage] = [:]
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var searchQueryLabel: UILabel!
    @IBOutlet weak var resultsTableView: UITableView!
    
    var tapGesture: UITapGestureRecognizer!
    var speakeasy: Speakeasy!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speakeasy = Speakeasy()
        
        textView.text = thoughts.first
        
        tapGesture = UITapGestureRecognizer(target: self, action: "tapGesture:")
        view.addGestureRecognizer(tapGesture)
        
        ShowerThoughts.top { thoughts in
            println("Shower Thoughts: Fetched \(countElements(thoughts)) thoughts")
            self.thoughts = thoughts
            self.resetFields()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        downloaded = [:]
    }
    
    func resetFields() {
        textView.text = thoughts.first
        currentThought = 0
    }
    
    func tapGesture(gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func downloadThumbnail(thumbnailURL: String, forIndexPath indexPath: NSIndexPath) {
        if thumbnailDownloads[indexPath] == nil {
            println("Downloading image: \(thumbnailURL)")
            thumbnailDownloads[indexPath] = thumbnailURL
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                let imageData = NSData(contentsOfURL: NSURL(string: thumbnailURL))
                let image = UIImage(data: imageData)
                dispatch_async(dispatch_get_main_queue()) {
                    let cell = self.resultsTableView.cellForRowAtIndexPath(indexPath) as? ImageTableViewCell
                    cell?.resultImageView.image = image
                    self.downloaded[thumbnailURL] = image
                }
            }
        }
    }
    
    func downloadVisibleRows() {
        if thumbURLs.count > 0 {
            if let visibleRows = resultsTableView.indexPathsForVisibleRows() as? [NSIndexPath] {
                for indexPath in visibleRows {
                    let thumbnail = thumbURLs[indexPath.row]
                    if downloaded[thumbnail] == nil {
                        downloadThumbnail(thumbnail, forIndexPath: indexPath)
                    }
                }
            }
        }
    }

    @IBAction func changeThought(sender: AnyObject) {
        currentThought++
        if currentThought == thoughts.count {
            currentThought = 0
        }
        textView.text = thoughts[currentThought]
        thumbURLs = []
    }

    @IBAction func processThought(sender: AnyObject) {
        let thought = textView.text
        let queryBuilder = QueryBuilder()
        let queries = queryBuilder.keywordsForThought(thought)
        searchQueryLabel.text = ", ".join(queries)
        speakeasy.searchPhotos(queries, body: thought) { (images, error) in
            if let images = images {
                self.thumbURLs = images.map({ $0["thumb_src"]! as String })
            } else {
                let errorAlert = UIAlertController(title: "Error fetching images", message: error?.localizedDescription, preferredStyle: .Alert)
                self.presentViewController(errorAlert, animated: true, completion: nil)
            }
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return thumbURLs.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ImageResultCell") as ImageTableViewCell
        let thumbnail = thumbURLs[indexPath.row]
        println("Thumbnail: \(thumbnail)")
        if let thumbImage = downloaded[thumbnail] {
            cell.resultImageView.image = thumbImage
        } else {
            cell.resultImageView.image = nil
            if tableView.decelerating == false && tableView.dragging == false {
                downloadThumbnail(thumbnail, forIndexPath: indexPath)
            }
        }
        return cell
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView!, willDecelerate decelerate: Bool) {
        if scrollView.decelerating == false {
            downloadVisibleRows()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView!) {
        downloadVisibleRows()
    }
    
}

