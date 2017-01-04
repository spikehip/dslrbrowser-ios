//
//  CameraTableViewController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 04/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



class CameraTableViewController: UITableViewController, UPnPDBObserver {

    let reuseIdentifier = "CameraCell"
    let manager = UPnPManager.getInstance()
    //var cameras : [String : MediaServer1Device] = [String : MediaServer1Device]()
    var camerasAlreadyBrowsing : [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DownloadFinished"), object: nil, queue: OperationQueue.main, using: { (notification: Notification) -> Void in
            print("Download Finished Notification Received")
            let progress: DownloadProgressNotification = notification.object as! DownloadProgressNotification
            let cameraKey:String = CameraCollectionManager.getCameraKeyFor(mediaItem: progress.item)
            let indexPath: IndexPath = CameraCollectionManager.getIndexPathFor(cameraKey: cameraKey) as IndexPath
            CameraCollectionManager.addFinishedDownloadFor(cameraKey: cameraKey, title: progress.item.title)

            if let cell = self.tableView.cellForRow(at: indexPath) {
                if let progress : UIProgressView = cell.viewWithTag(2000) as? UIProgressView,
                let progressLabel: UILabel = cell.viewWithTag(5000) as? UILabel {
                    let total = CameraCollectionManager.getImageCountFor(cameraKey: cameraKey)
                    let dl = CameraCollectionManager.getDownloadCountFor(cameraKey: cameraKey)
                    let dlprgrs = CameraCollectionManager.getDownloadProgressFor(cameraKey: cameraKey)
                    progressLabel.text = String(dl)+"/"+String(total)
                    progress.setProgress(dlprgrs, animated: true)
                }
            }
        })
        
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(CameraTableViewController.refreshView), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl!)
        
        let db: UPnPDB = manager!.db
        db.add(self)
        let response = manager?.ssdp.searchSSDP
        print("manager?.ssdp.searchSSDP response:", response ?? 0)
    }
    
    func refreshView(sender:AnyObject) {
        let response = manager?.ssdp.searchSSDP
        print("refresh: manager?.ssdp.searchSSDP response:", response ?? 0)
        
        for key in CameraCollectionManager.devices.keys {
            print("Refreshing Device Contents", key)
            let device:MediaServer1Device = CameraCollectionManager.devices[key]!
            browseCamera(device: device, deviceBaseUrl: key)
        }
        
        reloadAllCollectionViews()
        
        refreshControl?.endRefreshing()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let cameraKey = CameraCollectionManager.getCameraKeyFor(section: (indexPath as NSIndexPath).row)
        let device:MediaServer1Device = CameraCollectionManager.devices[cameraKey]!
        //let device : MediaServer1Device = cameras[getKeyAt(cameras, indexPath: indexPath)]!
        
        if let iconView : UIImageView = cell.viewWithTag(1000) as? UIImageView,
            let progress : UIProgressView = cell.viewWithTag(2000) as? UIProgressView,
            let cameraModel : UILabel = cell.viewWithTag(3000) as? UILabel,
        let description: UILabel = cell.viewWithTag(4000) as? UILabel,
        let progressLabel: UILabel = cell.viewWithTag(5000) as? UILabel
        {
            cameraModel.text = device.friendlyName
            description.text = device.modelDescription
            progress.setProgress(CameraCollectionManager.getDownloadProgressFor(cameraKey: cameraKey), animated: false)
            let total = CameraCollectionManager.getImageCountFor(cameraKey: cameraKey)
            let dl = CameraCollectionManager.getDownloadCountFor(cameraKey: cameraKey)
            progressLabel.text = String(dl)+"/"+String(total)
            
            DispatchQueue.global().async {
                let port : NSNumber = NSNumber(value: device.baseURL.port!)
                var baseUrl : String = device.baseURL.scheme!+"://"+device.baseURL.host!
                baseUrl += ":" + (port == 0 ? "80" : port.stringValue)
                if ( device.smallIconURL != nil ) {
                    let url : URL = URL(string: baseUrl+device.smallIconURL)!
                    let data = try? Data(contentsOf: url)
                    if ( data != nil ) {
                        let deviceIcon : UIImage = UIImage(data: data!)!
                        DispatchQueue.main.async {
                            iconView.image = deviceIcon
                        }
                    }
                }
            }
            
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CameraCollectionManager.getCamerasCount()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("Maybe consider to implement this")
    }
    
    func uPnPDBWillUpdate(_ sender: UPnPDB!) {
        print("upnp db will update" + sender.description)
    }
    
    func uPnPDBUpdated(_ sender: UPnPDB!) {
        print("upnp db updated ", sender.description)
        print("total number of devices in sender ", sender.rootDevices.count)
        var deviceUrls : [String] = [String]()
        
        //add new devices
        for device in sender.rootDevices {
            if ((device as AnyObject).isKind(of: MediaServer1Device.self)) {
                let manufacturer : String = (device as AnyObject).manufacturer
                if ( manufacturer.lowercased().range(of: "canon") != nil ) {
                    print("This is a canon camera, proceed scanning directory contents")
                    print("------------------------------------------------------------------------")
                    print("device.identifier: ",device)
                    print("device.friendlyName: ",(device as AnyObject).friendlyName)
                    print("device.manufacturer, device.manufacturerUrl: ", (device as AnyObject).manufacturer, (device as AnyObject).manufacturerURL)
                    print("device.smallIconURL: ", (device as AnyObject).smallIconURL)
                    print("device.modelName, device.modelDescription: ", (device as AnyObject).modelName, (device as AnyObject).modelDescription)
                    print("------------------------------------------------------------------------")
                    
                    let deviceBaseUrl : String = getBaseUrlString(device as! BasicUPnPDevice)
                    deviceUrls.append(deviceBaseUrl)
                    
                    if (camerasAlreadyBrowsing.contains(deviceBaseUrl)) {
                        print("Already browsing ", deviceBaseUrl)
                    }
                    else {
                        //start browsing
                        //cameras[deviceBaseUrl] = (device as! MediaServer1Device)
                        CameraCollectionManager.initializeItemCollectionFor(cameraKey: deviceBaseUrl)
                        CameraCollectionManager.devices[deviceBaseUrl] = (device as! MediaServer1Device)
                        camerasAlreadyBrowsing.append(deviceBaseUrl)
                        
                        browseCamera(device: device as! MediaServer1Device, deviceBaseUrl: deviceBaseUrl)
                    }
                    
                }
                else {
                    print("This is NOT a canon camera, proceed scanning directory contents")
                    print("------------------------------------------------------------------------")
                    print("device.identifier: ",device)
                    print("device.friendlyName: ",(device as AnyObject).friendlyName)
                    print("device.manufacturer, device.manufacturerUrl: ", (device as AnyObject).manufacturer, (device as AnyObject).manufacturerURL)
                    print("device.smallIconURL: ", (device as AnyObject).smallIconURL)
                    print("device.modelName, device.modelDescription: ", (device as AnyObject).modelName, (device as AnyObject).modelDescription)
                    print("------------------------------------------------------------------------")
                    
                    let deviceBaseUrl : String = getBaseUrlString(device as! BasicUPnPDevice)
                    deviceUrls.append(deviceBaseUrl)
                    
                    CameraCollectionManager.initializeItemCollectionFor(cameraKey: deviceBaseUrl)
                    CameraCollectionManager.devices[deviceBaseUrl] = (device as! MediaServer1Device)
                    
                    browseCamera(device: device as! MediaServer1Device, deviceBaseUrl: deviceBaseUrl)
                }
            }
        }
        
        //remove signed off devices
        for key in CameraCollectionManager.cameras.keys {
            if (!deviceUrls.contains(key)) {
                print("Device ",key," signed off.")
                if ( camerasAlreadyBrowsing.contains(key)) {
                    camerasAlreadyBrowsing.remove(at: camerasAlreadyBrowsing.index(of: key)!)
                }
                CameraCollectionManager.removeItemCollectionFor(cameraKey: key)
                CameraCollectionManager.devices.removeValue(forKey: key)
            }
        }
        
        //UPnPManager.GetInstance().DB.removeObserver(self)
        reloadAllCollectionViews()
    }
    
    func browseCamera(device: MediaServer1Device, deviceBaseUrl: String) {
        DispatchQueue.global().async {
            let recursiveCDBrowser : RecursiveContentDirectoryBrowser = RecursiveContentDirectoryBrowser.init(withContentDirectory: (device as AnyObject).contentDirectory, deviceBaseUrl: deviceBaseUrl)
            
            recursiveCDBrowser.browseTree()
            
            DispatchQueue.main.async {
                let badgeValue = CameraCollectionManager.getImageCountFor(cameraKey: deviceBaseUrl)
                if (self.tabBarController?.selectedIndex != 1) {
                    let tabArray = self.tabBarController?.tabBar.items as NSArray!
                    let tabItem = tabArray?.object(at: 1) as! UITabBarItem
                    tabItem.badgeValue = String(badgeValue)
                }
                if ( self.camerasAlreadyBrowsing.contains(deviceBaseUrl)) {
                    self.camerasAlreadyBrowsing.remove(at: self.camerasAlreadyBrowsing.index(of: deviceBaseUrl)!)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func reloadAllCollectionViews() {
        DispatchQueue.main.async {
            //reload tab1 camera table view data
            self.tableView.reloadData()
            
            if (self.tabBarController?.selectedIndex == 1) {
                let photosTabNavigationController : UINavigationController = self.tabBarController?.selectedViewController as! UINavigationController
                if ( photosTabNavigationController.topViewController!.isKind(of: UICollectionViewController.self) ) {
                    let photosTabCollectionViewController : UICollectionViewController = photosTabNavigationController.topViewController as! UICollectionViewController
                    photosTabCollectionViewController.collectionView?.reloadData()
                } else {
                    if (photosTabNavigationController.viewControllers[0].isKind(of: UICollectionViewController.self)) {
                        let photosTabCollectionViewController : UICollectionViewController = photosTabNavigationController.viewControllers[0] as! UICollectionViewController
                        photosTabCollectionViewController.collectionView?.reloadData()
                    }
                }
            }
            
            if (self.tabBarController?.selectedIndex == 0) {
                if ( self.tabBarController?.viewControllers?.count > 2 ) {
                    if (( self.tabBarController?.viewControllers![1].isKind(of: UINavigationController.self) ) != nil) {
                        let photosTabNavigationController : UINavigationController = self.tabBarController?.viewControllers![1] as! UINavigationController
                        let photosTabCollectionViewController : UICollectionViewController = photosTabNavigationController.viewControllers[0] as! UICollectionViewController
                        photosTabCollectionViewController.collectionView?.reloadData()
                    }
                }
            }
            
        }
    }
    
    func getBaseUrlString(_ device: BasicUPnPDevice) -> String {
//        let port : NSNumber = device.baseURL.port!
        let baseUrl : String = device.baseURL.scheme!+"://"+device.baseURL.host!
//        baseUrl += ":" + (port == 0 ? "80" : port.stringValue)
        
        return baseUrl
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UITableViewCell
        if let indexPath : IndexPath = self.tableView.indexPath(for: cell),
         let cameraKeyForSection:String = CameraCollectionManager.getCameraKeyFor(section: (indexPath as NSIndexPath).section),
         let camera :MediaServer1Device = CameraCollectionManager.devices[cameraKeyForSection]
        {
            let detailViewController = segue.destination as! CameraDetailViewController
            detailViewController.cameraKey = cameraKeyForSection
            segue.destination.navigationItem.title = camera.friendlyName
            
            if let imageView : UIImageView = segue.destination.view.viewWithTag(1000) as? UIImageView,
                let label1 : UILabel = segue.destination.view.viewWithTag(2000) as? UILabel,
                let label2 : UILabel = segue.destination.view.viewWithTag(3000) as? UILabel,
                let label3 : UILabel = segue.destination.view.viewWithTag(6000) as? UILabel,
                let progress : UIProgressView = segue.destination.view.viewWithTag(4000) as? UIProgressView
            {
                let iconView : UIImageView = (cell.viewWithTag(1000) as? UIImageView)!
                imageView.image = iconView.image
                label1.text = camera.friendlyName
                let total = CameraCollectionManager.getImageCountFor(cameraKey: cameraKeyForSection)
                let dl = CameraCollectionManager.getDownloadCountFor(cameraKey: cameraKeyForSection)
                let dlprgrs = CameraCollectionManager.getDownloadProgressFor(cameraKey: cameraKeyForSection)
                label2.text = "Downloaded "+String(dl)+"/"+String(total)
                progress.setProgress(dlprgrs, animated: true)
                var desc : String = camera.manufacturer + ", "+camera.manufacturerURL.absoluteString + "\n"
                desc = desc + camera.modelName+" "+camera.modelDescription + "\n"
                desc = desc + "Local address: " + getBaseUrlString(camera)
                label3.numberOfLines = 0
                label3.text = desc
            }
        }
    }
    
    
    /*
    func getKeyAt(fromHash: [String : MediaServer1Device], indexPath: NSIndexPath) -> String {
        var i=0
        for key in fromHash.keys {
            if ( i == indexPath.item ) {
                return key
            }
            i++
        }
        return ""
    }
    */
}

