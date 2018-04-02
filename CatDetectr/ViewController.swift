//
//  ViewController.swift
//  CatDetectr
//
//  Created by Sophos on 2018-03-23.
//  Copyright © 2018 Sophos. All rights reserved.
//

import Cocoa
import Quartz
import Vision


enum CatDetectorResult {
    case NoImageCaptured
    case AnalysisError
    case WindowTooSmall
    case NoError
}
class WindowInfo {
    let windowId:CGWindowID
    let windowTitle:String
    let appName:String
    let size:NSSize
    let pid:pid_t
    var confidence:VNConfidence
    var image:CGImage?
    var analysisResult:CatDetectorResult
    init(windowId:CGWindowID, windowTitle:String,appName:String, size:NSSize, pid:pid_t) {
        self.windowId = windowId
        self.windowTitle = windowTitle
        self.appName = appName
        self.pid = pid
        self.size = size
        self.confidence = 0
        self.analysisResult = .NoError
    }
    var resultString:String {
        switch analysisResult {
        case .AnalysisError:
            return "Analysis Error"
        case .NoImageCaptured:
            return "Couldn't Capture Image"
        case .WindowTooSmall:
            return "Window is invisible or too smal"
        case .NoError:
            return ""
        }
    }
}

class ViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    let ModelInputSize = CGSize(width: 224, height: 224)
    @IBOutlet weak var labelWindowCount: NSTextField!
    @IBOutlet weak var collectionView: NSCollectionView!

    @IBOutlet weak var toggleAutomaticRefresh: NSButton!
    
    @IBOutlet weak var dropdownRefreshPeriod: NSPopUpButton!
    @IBOutlet weak var refrehPeriods: NSMenu!
    @IBOutlet weak var refresh1s: NSMenuItem!
    @IBOutlet weak var refresh2s: NSMenuItem!
    @IBOutlet weak var refresh5s: NSMenuItem!
    
    var checkTimer:Timer?
    var model:VNCoreMLModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = try! VNCoreMLModel(for: CMLCatDetector().model)
        updateWindowInfos()
    }
    
    @IBAction func toggleRefreshAction(_ sender: NSButton) {
        if sender.state == .on {
            startAutomaticRefresh()
        }
        else {
            checkTimer?.invalidate()
        }
    }
    
    func startAutomaticRefresh() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(selectedRefreshPeriod), repeats: true, block: { (trimer) in
            self.updateWindowInfos()
        })
    }
    var selectedRefreshPeriod: Int {
        if dropdownRefreshPeriod.selectedItem == refresh1s {
            return 1
        }
        if dropdownRefreshPeriod.selectedItem == refresh2s {
            return 2
        }
        if dropdownRefreshPeriod.selectedItem == refresh5s {
            return 5
        }
        return 1
    }
    
    @IBAction func changeRefreshPeriod(_ sender: NSPopUpButton) {
        if toggleAutomaticRefresh.state == .on {
            checkTimer?.invalidate()
            startAutomaticRefresh()
        }
    }
    
    
    func analyzeImage(_ image:CGImage, completionHandler:@escaping (VNRequest, Error?)->(Void)) {
        let request = VNCoreMLRequest(model: model, completionHandler: completionHandler)
        request.preferBackgroundProcessing = true
        request.imageCropAndScaleOption = .scaleFit
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try! handler.perform([request])
    }
    
    
    var windowInfos:[WindowInfo] = []
    var images:[NSImage] = []
   
    func updateWindowInfos() {
        windowInfos = []
        images = []
        if let windowsInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly,.excludeDesktopElements], kCGNullWindowID) {
            for windowInfo in (windowsInfo as Array) {
                let info = windowInfo as! [String:Any]
                let windowId:CGWindowID = info[kCGWindowNumber as String] as! CGWindowID
                let windowTitle:String? = info[kCGWindowName as String] as? String
                let appName:String = info[kCGWindowOwnerName as String] as! String
                let pid:pid_t = info[kCGWindowOwnerPID as String] as! pid_t
                let sizeInfo = info[kCGWindowBounds as String] as! [String:Any]
                //                CGRectMakeWithDictionaryRepresentation(sizeInfo, <#T##rect: UnsafeMutablePointer<CGRect>##UnsafeMutablePointer<CGRect>#>)
                let height = sizeInfo["Height"] as! CGFloat
                let width = sizeInfo["Width"] as! CGFloat
                
                
                let windowInfo = WindowInfo(windowId: windowId, windowTitle: windowTitle ?? "", appName: appName, size: NSSize(width: width, height: height), pid:pid)
//                windowInfos.append(windowInfo)
                
                if let windowCap = CGWindowListCreateImage(CGRect.null, [.optionIncludingWindow], windowId, []) {
                    if height >= ModelInputSize.height, width >= ModelInputSize.width,
                        appName != "Dock", appName != "Notification Center"{
            
                        windowInfos.append(windowInfo)
                        windowInfo.image = windowCap
                        analyzeImage(windowCap, completionHandler: { (request, error) -> (Void) in
                            guard let results = request.results as? [VNClassificationObservation],
                                let result = results.first(where: { (classification) -> Bool in
                                    classification.identifier == "cat"
                                })
                                else {
                                    print("errors classifying image for window \(windowId)")
                                    windowInfo.analysisResult = .AnalysisError
                                    self.updateUI()
                                    return
                            }
                            
                            windowInfo.confidence = result.confidence
                            self.updateUI()
                            if result.confidence > VNConfidence(0.95) {
                                self.notifyAboutWindow(windowInfo)
                            }
                        })
                    }
                    else {
//                        windowInfo.analysisResult = .WindowTooSmall
                    }
                }
                else {
//                    windowInfo.analysisResult = .NoImageCaptured
                }
            }
        }
        self.labelWindowCount.stringValue = "Analyzed \(windowInfos.count) windows"
        
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func notifyAboutWindow(_ windowInfo:WindowInfo) {
        DispatchQueue.main.async {
            let notification = NSUserNotification()
            notification.title = "Cat Detected!"
            notification.subtitle = "App: \(windowInfo.appName) (\(windowInfo.pid))"
            notification.informativeText = "Title: \(windowInfo.windowTitle)"
            notification.identifier = "\(windowInfo.windowId)"
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    @IBAction func doAction(_ sender: Any) {
        updateWindowInfos()
    }
    
    //MARK:- NSCollectionViewDataSource
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return windowInfos.count
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "WindowInfoCollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? WindowInfoCollectionViewItem,
            windowInfos.count > indexPath.item
        else {return item}
        let windowInfo = windowInfos[indexPath.item]
        
        if let cgImage = windowInfo.image {
            collectionViewItem.imgScreencap.image = NSImage(cgImage: cgImage, size: windowInfo.size)
        }
        collectionViewItem.labelIssue.stringValue = windowInfo.resultString
        collectionViewItem.labelAppName.stringValue = windowInfo.appName
        collectionViewItem.labelWindowName.stringValue = windowInfo.windowTitle
        collectionViewItem.labelPid.stringValue = "\(windowInfo.pid)"
        collectionViewItem.levelConfidence.integerValue = Int(windowInfo.confidence * 100)
        print(windowInfo.confidence)
        return collectionViewItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        for indexPath in indexPaths {
            if indexPath.item < windowInfos.count {
                let info = windowInfos[indexPath.item]
                self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "ShowDetailedImage"), sender: info)
            }
        }
    }

    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        if segue.identifier?.rawValue == "ShowDetailedImage", let detailsVc = segue.destinationController as? DetailedImageViewController, let info = sender as? WindowInfo {
            if let img = info.image {
                detailsVc.image = NSImage(cgImage: img, size: info.size)
            }
        }
        super.prepare(for: segue, sender: sender)
    }
}

