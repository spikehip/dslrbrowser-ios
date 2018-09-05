//
//  PhotoDetailViewController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 17/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var imageData : MediaServer1ItemObject?
    var cameraKey : String?
    var index : Int = 0
    var url : URL?
    
    // Preview action items.
    lazy var previewActions: [UIPreviewActionItem] = {
        
        func previewActionForTitle(_ title: String, style: UIPreviewActionStyle = .default) -> UIPreviewAction {
            return UIPreviewAction(title: title, style: style) { previewAction, viewController in
                guard let detailViewController = viewController as? PhotoDetailViewController,
                let item : MediaServer1ItemObject = detailViewController.imageData else { return }
                
                print("\(previewAction.title) triggered from `PhotoDetailViewController` for item: \(item.title)")
                if (previewAction.title == "Download") {
                    let url:String = MediaServer1BasicObjectCollection.getImageURL(fromObject: item, quality: ImageQuality.IMAGE_QUALITY_ORIGINAL_ROTATED)
                    let downloadItem : DownloadItem = DownloadItem.init(withURL: url, item: item)
                    downloadItem.download()
                }
            }
        }
        
        let downloadAction = previewActionForTitle("Download")
        //let quickShareAction = previewActionForTitle("Quick Share")
        /*
        let action2 = previewActionForTitle("Destructive Action", style: .Destructive)
        
        let subAction1 = previewActionForTitle("Sub Action 1")
        let subAction2 = previewActionForTitle("Sub Action 2")
        let groupedActions = UIPreviewActionGroup(title: "Sub Actions…", style: .Default, actions: [subAction1, subAction2] )
        */
        return [downloadAction]
    }()    
    // MARK: Preview actions
    
    override var previewActionItems : [UIPreviewActionItem] {
        return previewActions
    }

    @IBAction func downloadPhotoAction(_ sender: UIButton) {
        sender.isEnabled = false
        let url:String = MediaServer1BasicObjectCollection.getImageURL(fromObject: self.imageData!, quality: ImageQuality.IMAGE_QUALITY_ORIGINAL_ROTATED)
        let downloadItem : DownloadItem = DownloadItem.init(withURL: url, item: self.imageData!)
        downloadItem.download()
    }
    
    override func viewDidLoad() {
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DownloadProgress"), object: nil, queue: OperationQueue.main, using: { (notification: Notification) -> Void in
            let progress: DownloadProgressNotification = notification.object as! DownloadProgressNotification
            print("Progress of item \(progress.item.title) is \(progress.calculateProgressPercent())%")
            if let progressView = self.view.viewWithTag(3000) as? UIProgressView {
                progressView.setProgress(progress.calculateProgress(), animated: true)
            }
        })
        
        if let downloadButton:UIButton = self.view.viewWithTag(2000) as? UIButton,
            let progressView = self.view.viewWithTag(3000) as? UIProgressView
        {
            downloadButton.isHidden = false
            progressView.isHidden = false
            if (CameraCollectionManager.isDownloadFinishedFor(title: (imageData?.title)!, cameraKey: self.cameraKey!)) {
                downloadButton.isEnabled = false
                progressView.setProgress(1.0, animated: false)
            }
        }
        
        if ( url == nil ) {
            self.url = URL(string:CameraCollectionManager.getItemCollectionFor(cameraKey: self.cameraKey!).getImageURLAt(withPosition: self.index, quality: ImageQuality.IMAGE_QUALITY_LOW))
        }
        
        loadPreviewInBackground()
    }
    
    @IBAction func swipeLeft(_ sender: Any) {
    }    
    @IBAction func swipeRight(_ sender: Any) {
    }
    @IBAction func swipeDown(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let gesture:UISwipeGestureRecognizer = sender as! UISwipeGestureRecognizer
        
        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.left:
            if ( index < CameraCollectionManager.getTotalImageCount()-1 ) {
                return true
            }
            else {
                print("already at last item")
                return false
            }
        case UISwipeGestureRecognizerDirection.right:
            if (index > 0) {
                return true
            }
            else {
                print("already at first item")
                return false
            }
        default:
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let gesture:UISwipeGestureRecognizer = sender as! UISwipeGestureRecognizer
        let imageCollection:MediaServer1BasicObjectCollection = CameraCollectionManager.getItemCollectionFor(cameraKey: cameraKey!)

        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.left:
            (segue.destination as! PhotoDetailViewController).cameraKey = cameraKey
            (segue.destination as! PhotoDetailViewController).index = index+1
            let imageDataNext :MediaServer1ItemObject = imageCollection.getItemAt(index+1)
            (segue.destination as! PhotoDetailViewController).imageData = imageDataNext
            segue.destination.navigationItem.title = imageDataNext.title
            let url : URL = URL(string: imageCollection.getImageURLAt(withPosition: index+1, quality: ImageQuality.IMAGE_QUALITY_LOW))!
            (segue.destination as! PhotoDetailViewController).url = url
            print("segue swiping left")
            break
        case UISwipeGestureRecognizerDirection.right:
            let imageDataNext :MediaServer1ItemObject = imageCollection.getItemAt(index-1) 
            (segue.destination as! PhotoDetailViewController).imageData = imageDataNext
            (segue.destination as! PhotoDetailViewController).cameraKey = cameraKey
            (segue.destination as! PhotoDetailViewController).index = index-1
            segue.destination.navigationItem.title = imageDataNext.title
            let url : URL = URL(string: imageCollection.getImageURLAt(withPosition: index-1, quality: ImageQuality.IMAGE_QUALITY_LOW))!
            (segue.destination as! PhotoDetailViewController).url = url
            print("segue swiping right")
            break
        default:
            print("default swipe")
        }
    }
    
    private func loadPreviewInBackground() {
        if ( self.url != nil ) {
            let backgroundQueue = DispatchQueue(label: "hu.bikeonet.dslrbrowser.photocollectionviewcontroller.peek", qos: .userInteractive)
            let filename:String = "dslrbrowser_preview_" + (url!.absoluteString.data(using: .utf8)?.base64EncodedString())! + ".jpg"
            let cacheDirectory:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
            let cacheFileName:URL = URL.init(fileURLWithPath: cacheDirectory.path + "/" + filename )
            
            backgroundQueue.async {
                if (ThumbnailCacheManager.defaultManager.isPreviewAvailableFor(cameraKey: self.cameraKey!, title: (self.imageData?.title)!)) {
                    self.imageView.image = ThumbnailCacheManager.defaultManager.getPreviewImageFor(cameraKey: self.cameraKey!, title: (self.imageData?.title)!)
                }
                else {
                    var data:Data
                    if (FileManager.default.fileExists(atPath: cacheFileName.path)) {
                        //load file
                        data = FileManager.default.contents(atPath: cacheFileName.path)!
                    }
                    else {
                        //get file and save to cache
                        do {
                            data = try Data(contentsOf: self.url!)
                            if ( data.count > 0 ) {
                                FileManager.default.createFile(atPath: cacheFileName.path, contents: data, attributes: nil)
                            }
                        }
                        catch {
                            DispatchQueue.main.async {
                                self.imageView.image = #imageLiteral(resourceName: "camera_wifi")
                            }
                            data = Data(count: 0)
                        }
                    }
                    
                    if ( data.count > 0 && self.imageView != nil) {
                        DispatchQueue.main.async {
                            let image : UIImage = UIImage(data: data)!
                            self.imageView.image = image
                        }
                    }
                }
            }
        }
        else {
            self.imageView.image = #imageLiteral(resourceName: "camera_wifi")
        }
    }
    
}
