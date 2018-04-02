//
//  WindowInfoCollectionViewItem.swift
//  CatDetectr
//
//  Created by Sophos on 2018-03-31.
//  Copyright © 2018 Sophos. All rights reserved.
//

import Cocoa

class WindowInfoCollectionViewItem: NSCollectionViewItem {
    @IBOutlet weak var labelAppName: NSTextField!
    @IBOutlet weak var labelWindowName: NSTextField!
    @IBOutlet weak var labelIssue: NSTextField!
    @IBOutlet weak var levelConfidence: NSLevelIndicator!
    @IBOutlet weak var imgScreencap: NSImageView!
    @IBOutlet weak var labelPid: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
