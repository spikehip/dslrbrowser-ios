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
    var isSelectionMode : Bool = false
    
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
            progressView.setProgress(0, animated: false)
            imageView.image = #imageLiteral(resourceName: "lens")
            activityIndicatorView.startAnimating()
            let backgroundQueue = DispatchQueue(label: "hu.bikeonet.dslrbrowser.photocollectionviewcontroller.thumbnail", qos: .userInteractive)
            if (!isLowOnMemory) {
                backgroundQueue.async {
                    if (CameraCollectionManager.isDownloadFinishedFor(title: cameraKeyForSection, cameraKey: title)) {
                        DispatchQueue.main.async {
                            progressView.setProgress(1, animated: false)
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            if let progress:Float = self.indexToProgressMap[indexPath] {
                                progressView.setProgress(progress, animated: false)
                            }
                            else {
                                progressView.setProgress(0, animated: false)
                            }
                        }
                    }
                    
                    if (ThumbnailCacheManager.defaultManager.isThumbnailAvailableFor(cameraKey: cameraKeyForSection, title: title)) {
                        DispatchQueue.main.async {
                            progressView.setProgress(1, animated: false)
                            activityIndicatorView.stopAnimating()
                            imageView.image = ThumbnailCacheManager.defaultManager.getThumbnailImageFor(cameraKey: cameraKeyForSection, title: title)
                        }
                    }
                    else {
                        let filename:String = "dslrbrowser_thumbnail_" + (url.absoluteString.data(using: .utf8)?.base64EncodedString())! + ".jpg"
                        let cacheDirectory:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
                        let cacheFileName:URL = URL.init(fileURLWithPath: cacheDirectory.path + "/" + filename )
                    
                        var data:Data
                        if (FileManager.default.fileExists(atPath: cacheFileName.path)) {
                            //load file
                            data = FileManager.default.contents(atPath: cacheFileName.path)!
                        }
                        else {
                            //get file and save to cache
                            do {
                                data = try Data(contentsOf: url)
                                if ( data.count > 0 ) {
                                    FileManager.default.createFile(atPath: cacheFileName.path, contents: data, attributes: nil)
                                }
                            }
                            catch {
                                print("Failed to load thumbnail ", url)
                                data = Data()
                            }
                        }
                        
                        DispatchQueue.main.async {
                            if ( data.count == 0 || data.count > 100000) {
                                activityIndicatorView.stopAnimating()
                                //TODO: icon for broken connection
                                if ( data.count == 0 ) {
                                    imageView.image = #imageLiteral(resourceName: "camera_wifi")
                                }
                                else {
                                    //TODO: icon for excessive thumbnail image
                                    print("Thumbnail image size(b) ", data.count, " exceeds limit.")
                                    imageView.image = #imageLiteral(resourceName: "camera")
                                }
                            }
                            else {
                                let image : UIImage = UIImage(data: data)!
                                imageView.image = image
                                activityIndicatorView.stopAnimating()
                                print("Loaded image ", (indexPath as NSIndexPath).item, " from ", url, " size(b) ", data.count)
                            }
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
        let index:Int = (indexPath as NSIndexPath).item
        
        segue.destination.navigationItem.title = imageData.title
        let detailViewController : PhotoDetailViewController = (segue.destination as! PhotoDetailViewController)
        detailViewController.imageData = imageData
        detailViewController.cameraKey = cameraKeyForSection
        detailViewController.index = index
        
        print("Segue identifier ", segue.identifier ?? "empty")
        
        if (segue.identifier == "photoDetailPreview") {
            if let downloadButton : UIButton = segue.destination.view.viewWithTag(2000) as? UIButton,
                let progressView:UIProgressView = segue.destination.view.viewWithTag(3000) as? UIProgressView{
                downloadButton.isHidden = true
                progressView.isHidden = true
            }
        }
        
        if let url : URL = URL(string: imageCollection.getImageURLAt(withPosition: (indexPath as NSIndexPath).item, quality: ImageQuality.IMAGE_QUALITY_LOW))
        {
            detailViewController.url = url
        }
        
    }
    
    @IBAction func enterSelectionMode(_ sender: UIBarButtonItem) {
        if ( isSelectionMode ) {
            sender.title = "Select"
            isSelectionMode = false
        }
        else {
            sender.title = "Download"
            isSelectionMode = true
        }
    }
}
