//
//  DetailedImageViewController.swift
//  CatDetectr
//
//  Created by Sophos on 2018-03-31.
//  Copyright © 2018 Sophos. All rights reserved.
//

import Cocoa

class DetailedImageViewController: NSViewController {

    @IBOutlet weak var imgView: NSImageView!
    var image:NSImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imgView.image = image
        // Do view setup here.
    }
    
}
