//
//  PhotoCollectionViewController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 14/10/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import UIKit

let reuseIdentifier = "ThumbnailCell"

class PhotoCollectionViewController: UICollectionViewController {
    
    var titleToPositionMap : [String: IndexPath] = [String: IndexPath]()
    var indexToProgressMap : [IndexPath : Float] = [IndexPath: Float]()
    var isLowOnMemory : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DownloadProgress"), object: nil, queue: OperationQueue.main, using: { (notification: Notification) -> Void in
            let progress: DownloadProgressNotification = notification.object as! DownloadProgressNotification
            print("Progress of item \(progress.item.title) is \(progress.calculateProgressPercent())%")
            if let indexPath: IndexPath = self.titleToPositionMap[progress.item.title]
            {
                self.indexToProgressMap[indexPath] = progress.calculateProgress()
                if let cell:UICollectionViewCell = self.collectionView?.cellForItem(at: indexPath) {
                    if (( self.collectionView?.visibleCells.contains(cell) ) != nil) {
                        if let progressView = cell.viewWithTag(2000) as? UIProgressView {
                            progressView.progress = progress.calculateProgress()
                        }
                    }
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.parent!.tabBarItem.badgeValue = nil        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        isLowOnMemory = true
        self.collectionView?.reloadData()
        print("Maybe consider to implement this")
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return CameraCollectionManager.getCamerasCount()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let cameraKeyForSection = CameraCollectionManager.getCameraKeyFor(section: section)
        let count = CameraCollectionManager.getItemCollectionFor(cameraKey: cameraKeyForSection).getItems().count
        return count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as UICollectionViewCell
        let cameraKeyForSection:String = CameraCollectionManager.getCameraKeyFor(section: (indexPath as NSIndexPath).section)
        let imageCollection:MediaServer1BasicObjectCollection = CameraCollectionManager.getItemCollectionFor(cameraKey: cameraKeyForSection)
        
        // Configure the cell
        let title: String = imageCollection.getImageTitleAt(withPosition: (indexPath as NSIndexPath).item)
        if let imageView : UIImageView = cell.viewWithTag(1000) as? UIImageView,
            let activityIndicatorView = cell.viewWithTag(3000) as? UIActivityIndicatorView,
            let progressView = cell.viewWithTag(2000) as? UIProgressView,
            let url : URL = URL(string: imageCollection.getImageURLAt(withPosition: (indexPath as NSIndexPath).item, quality: ImageQuality.IMAGE_QUALITY_THUMBNAIL))
        {
            self.titleToPositionMap[title] = indexPath
            print("Background loading image for ", (indexPath as NSIndexPath).item, " from ", url)
            progressView.progress = 0.0
            imageView.image = #imageLiteral(resourceName: "lens")
            activityIndicatorView.startAnimating()
            let backgroundQueue = DispatchQueue(label: "hu.bikeonet.dslrbrowser.photocollectionviewcontroller.thumbnail", qos: .background)
            if (!isLowOnMemory) {
                backgroundQueue.async {
                    let data = try? Data(contentsOf: url)
                    DispatchQueue.main.async {
                        if ( data == nil || data!.count > 100000) {
                            activityIndicatorView.stopAnimating()
                            progressView.setProgress(0, animated: false)
                            //TODO: icon for broken connection
                            if ( data == nil ) {
                                imageView.image = #imageLiteral(resourceName: "camera_wifi")
                            }
                            else {
                                //TODO: icon for excessive thumbnail image
                                print("Thumbnail image size(b) ", data!.count, " exceeds limit.")
                                imageView.image = #imageLiteral(resourceName: "camera")
                            }
                        }
                        else {
                            let image : UIImage = UIImage(data: data!)!
                            imageView.image = image
                            activityIndicatorView.stopAnimating()
                            if let progress:Float = self.indexToProgressMap[indexPath] {
                                progressView.setProgress(progress, animated: true)
                            }
                            else {
                                progressView.setProgress(0, animated: false)
                            }
                            print("Loaded image ", (indexPath as NSIndexPath).item, " from ", url, " size(b) ", data!.count)
                        }
                    }
                }
            }
            
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let cameraKey:String = CameraCollectionManager.getCameraKeyFor(section: (indexPath as NSIndexPath).section)
        
        if ( cameraKey != "" ) {
        
            if ( kind == UICollectionElementKindSectionHeader ) {
                let device:MediaServer1Device = CameraCollectionManager.devices[cameraKey]!
                let supplementaryView = (collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath))
                let label:UILabel = supplementaryView.viewWithTag(1000) as! UILabel
                label.text = device.friendlyName
                
                return supplementaryView
            }
            
            if ( kind == UICollectionElementKindSectionFooter ) {
                let supplementaryView = (collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionFooter", for: indexPath))
                let label:UILabel = supplementaryView.viewWithTag(1000) as! UILabel
                let total = CameraCollectionManager.getImageCountFor(cameraKey: cameraKey)
                label.text = "Total: "+String(total)
                
                return supplementaryView
            }
            
        }
        
        return UICollectionReusableView.init()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UICollectionViewCell
        let indexPath : IndexPath = (self.collectionView?.indexPath(for: cell))!
        let cameraKeyForSection:String = CameraCollectionManager.getCameraKeyFor(section: (indexPath as NSIndexPath).section)
        let imageCollection:MediaServer1BasicObjectCollection = CameraCollectionManager.getItemCollectionFor(cameraKey: cameraKeyForSection)

        let imageData :MediaServer1ItemObject = imageCollection.getItemAt((indexPath as NSIndexPath).item)
        segue.destination.navigationItem.title = imageData.title
        let detailViewController : PhotoDetailViewController = (segue.destination as! PhotoDetailViewController)
        detailViewController.imageData = imageData
        detailViewController.cameraKey = cameraKeyForSection
        
        print("Segue identifier ", segue.identifier ?? "empty")
        
        if (segue.identifier == "photoDetailPreview") {
            if let downloadButton : UIButton = segue.destination.view.viewWithTag(2000) as? UIButton,
                let progressView:UIProgressView = segue.destination.view.viewWithTag(3000) as? UIProgressView{
                downloadButton.isHidden = true
                progressView.isHidden = true
            }
        }
        
        
        if let imageView : UIImageView = segue.destination.view.viewWithTag(1000) as? UIImageView,
            let url : URL = URL(string: imageCollection.getImageURLAt(withPosition: (indexPath as NSIndexPath).item, quality: ImageQuality.IMAGE_QUALITY_LOW))
        {
            let backgroundQueue = DispatchQueue(label: "hu.bikeonet.dslrbrowser.photocollectionviewcontroller.peek", qos: .userInteractive)
            
            backgroundQueue.async {
                let data = try? Data(contentsOf: url)
                if ( data != nil ) {
                    DispatchQueue.main.async {
                        let image : UIImage = UIImage(data: data!)!
                        imageView.image = image
                        let size = data!.count / 1024 / 1024
                        print("Loaded image to peek view", (indexPath as NSIndexPath).item, " from ", url, " size(Mb) ", size)
                    }
                }
            }
        }
        
    }
}
