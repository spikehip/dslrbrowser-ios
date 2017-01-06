//
//  PhotoDetailViewController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 17/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {
    
    var imageData : MediaServer1ItemObject?
    var cameraKey : String?
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
                progressView.setProgress(1.0, animated: true)
            }
        }
        
    }
    
}
