//
//  ImageTableViewCell.swift
//  ImageSearch
//
//  Created by Levi McCallum on 9/5/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var resultImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
