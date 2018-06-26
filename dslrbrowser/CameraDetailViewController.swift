//
//  CameraDetailViewController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 31/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation

class CameraDetailViewController: UIViewController {
    
    var cameraKey:String = ""
    var toBeDownloadedItems:[MediaServer1ItemObject] = [MediaServer1ItemObject]()
    
    override func viewDidLoad() {
        
        //Disable download all photos button if all photos are already downloaded
        //or there are no photos to download 
        if ( self.cameraKey.count > 0 ) {
            let total = CameraCollectionManager.getImageCountFor(cameraKey: self.cameraKey)
            let dlprgrs = CameraCollectionManager.getDownloadProgressFor(cameraKey: self.cameraKey)
            if (dlprgrs == 1.0 || total == 0) {
                if let downloadButton:UIButton = self.view.viewWithTag(5000) as? UIButton {
                    downloadButton.isEnabled = false
                }
            }
        }
        
        //add notification listener to update progress view upon a download has been completed
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DownloadFinished"), object: nil, queue: OperationQueue.main, using: { (notification: Notification) -> Void in
            if ( self.cameraKey.count > 0 ) {
                if let
                    label2 : UILabel = self.view.viewWithTag(3000) as? UILabel,
                    let progress : UIProgressView = self.view.viewWithTag(4000) as? UIProgressView
                {
                    let total = CameraCollectionManager.getImageCountFor(cameraKey: self.cameraKey)
                    let dl = CameraCollectionManager.getDownloadCountFor(cameraKey: self.cameraKey)
                    let dlprgrs = CameraCollectionManager.getDownloadProgressFor(cameraKey: self.cameraKey)
                    label2.text = "Downloaded "+String(dl)+"/"+String(total)
                    progress.setProgress(dlprgrs, animated: true)
                }
                
                self.downloadOneItemFromQueue()
            }
        })
    }
    
    @IBAction func downloadAllPhotosAction(_ sender: UIButton) {
        sender.isEnabled = false
        let photos = CameraCollectionManager.getItemCollectionFor(cameraKey: self.cameraKey)
        for objectID:String in photos.items.keys {
            if let item:MediaServer1ItemObject = photos.items[objectID] {
                if ( !CameraCollectionManager.isDownloadFinishedFor(title: item.title, cameraKey: self.cameraKey)) {
                    toBeDownloadedItems.append(item)
                }
            }
        }
        
        downloadOneItemFromQueue()
    }
    
    func downloadOneItemFromQueue() {
        if (toBeDownloadedItems.count > 0) {
            let item = toBeDownloadedItems.removeFirst()
            let url:String = MediaServer1BasicObjectCollection.getImageURL(fromObject: item, quality: ImageQuality.IMAGE_QUALITY_ORIGINAL_ROTATED)
            let downloadTask:DownloadItem = DownloadItem.init(withURL: url, item: item)
            downloadTask.download()
        }
    }
    
}
