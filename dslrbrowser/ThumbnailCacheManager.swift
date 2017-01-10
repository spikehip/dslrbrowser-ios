//
//  ThumbnailCacheManager.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 10/01/17.
//  Copyright © 2017 Andras Bekesi. All rights reserved.
//

import Foundation
import Photos
import CoreData

open class ThumbnailCacheManager {

    private var dc:DataController
    private var thumbnails = [String : String]()
    private var previews = [String : String]()
    private var isRefreshRunning:Bool
    
    open static let defaultManager:ThumbnailCacheManager = {
        let instance = ThumbnailCacheManager()
        return instance
    }()
    
    init() {
        dc = DataController()
        dc.waitUntilInitialized()
        isRefreshRunning = false
        refresh()
     }
    
    func getThumbnailKeyFor(cameraKey: String, title: String) -> String {
        return ((cameraKey + title).data(using: .utf8)?.base64EncodedString())!
    }
    
    open func cleanUpDatabase() {
        print("Cleaning up downloaded item database")
        let photoEntityFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoEntity")
        do {
            let entities = try self.dc.managedObjectContext.fetch(photoEntityFetchRequest) as! [PhotoEntity]
            print("Query download database map found ",entities.count, " entities")
            for entity in entities {
                let assets:PHFetchResult<PHAsset> = PHAsset.fetchAssets(withLocalIdentifiers: [entity.localIdentifier!], options: nil)
                if (assets.count == 0) {
                    self.dc.managedObjectContext.delete(entity)
                    print("Removed ", entity.localIdentifier ?? "???")
                }
            }
            
            try self.dc.managedObjectContext.save()
            
        }
        catch {
            print("Error cleaning database", error)
        }
        print("Finished cleaning up downloaded item database")
    }
    
    open func refresh() {
        if (!isRefreshRunning) {
            isRefreshRunning = true
            let backgroundQueue = DispatchQueue(label: "hu.bikeonet.dslrbrowser.photocollectionviewcontroller.thumbnailcache", qos: .background)
            backgroundQueue.async {
                //query downloaded image list from app's sqlite database
                let photoEntityFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoEntity")
                do {
                    let entities = try self.dc.managedObjectContext.fetch(photoEntityFetchRequest) as! [PhotoEntity]
                    print("Query download database map found ",entities.count, " entities")
                    var isDatabaseChanged:Bool = false
                    for entity in entities {
                        print("Refreshing thumbnail cache for entity ", entity)
                        //query Photos framework to check if image is still in photo roll
                        let assets:PHFetchResult<PHAsset> = PHAsset.fetchAssets(withLocalIdentifiers: [entity.localIdentifier!], options: nil)
                        if (assets.count > 0) {
                            print("Entity found in photo roll, generating thumbnail cache")
                            //check if a thumbnail is already cached in the filesystem
                            //and request a thumbnail image otherwise
                            self.checkThumbnailImage(entity: entity, asset: assets[0])
                            
                            //check if a preview is already cached in the filesystem
                            //and request a preview image otherwise
                            self.checkPreviewImage(entity: entity, asset: assets[0])
                        }
                        else {
                            //remove deleted image from database
                            print("Entity not found in photo roll, cleaning up database entries")
                            let thumbnailKey = self.getThumbnailKeyFor(cameraKey: entity.cameraKey!, title: entity.title!)
                            if (self.thumbnails.keys.contains(thumbnailKey)) {
                                self.thumbnails.removeValue(forKey: thumbnailKey)
                            }
                            if (self.previews.keys.contains(thumbnailKey)) {
                                self.previews.removeValue(forKey: thumbnailKey)
                            }
                            self.dc.managedObjectContext.delete(entity)
                            CameraCollectionManager.removeFinishedDownloadFor(cameraKey: entity.cameraKey!, title: entity.title!)
                            isDatabaseChanged = true
                        }
                    }
                    if (isDatabaseChanged) {
                        try self.dc.managedObjectContext.save()
                    }
                } catch {
                    print("Failed to fetch photos: \(error)")
                }
                
                print("ThumbnailCacheManager refresh() finished")
                self.isRefreshRunning = false
            }
        }
    }
    
    func checkThumbnailImage(entity: PhotoEntity, asset: PHAsset) {
        let filename:String = "dslrbrowser_phassetthumbnail_" + (entity.localIdentifier!.data(using: .utf8)?.base64EncodedString())! + ".png"
        let cacheDirectory:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        let cacheFileName:URL = URL.init(fileURLWithPath: cacheDirectory.path + "/" + filename )
        let thumbnailKey = self.getThumbnailKeyFor(cameraKey: entity.cameraKey!, title: entity.title!)
        
        if ( FileManager.default.fileExists(atPath: cacheFileName.path) ) {
            self.thumbnails[thumbnailKey] = cacheFileName.path
        }
        else {
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            option.resizeMode = PHImageRequestOptionsResizeMode.fast
            option.isNetworkAccessAllowed = false
            option.version = PHImageRequestOptionsVersion.current
            manager.requestImage(for: asset, targetSize: CGSize(width: 80, height: 60), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                print(info ?? "???")
                UIGraphicsBeginImageContext((result?.size)!)
                result?.draw(in: CGRect(x: 0, y: 0, width: (result?.size.width)!, height: (result?.size.height)!))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                let png = UIImagePNGRepresentation(newImage!)
                if (png != nil) {
                    FileManager.default.createFile(atPath: cacheFileName.path, contents: png, attributes: nil)
                }
                UIGraphicsEndImageContext()
            })
        }
    }
    
    func checkPreviewImage(entity: PhotoEntity, asset: PHAsset) {
        let filename:String = "dslrbrowser_phassetpreview_" + (entity.localIdentifier!.data(using: .utf8)?.base64EncodedString())! + ".png"
        let cacheDirectory:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        let cacheFileName:URL = URL.init(fileURLWithPath: cacheDirectory.path + "/" + filename )
        let thumbnailKey = self.getThumbnailKeyFor(cameraKey: entity.cameraKey!, title: entity.title!)
        
        if ( FileManager.default.fileExists(atPath: cacheFileName.path) ) {
            self.previews[thumbnailKey] = cacheFileName.path
        }
        else {
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            option.resizeMode = PHImageRequestOptionsResizeMode.fast
            option.isNetworkAccessAllowed = false
            option.version = PHImageRequestOptionsVersion.current
            manager.requestImage(for: asset, targetSize: CGSize(width: 640, height: 480), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                print(info ?? "???")
                UIGraphicsBeginImageContext((result?.size)!)
                result?.draw(in: CGRect(x: 0, y: 0, width: (result?.size.width)!, height: (result?.size.height)!))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                let png = UIImagePNGRepresentation(newImage!)
                if (png != nil) {
                    FileManager.default.createFile(atPath: cacheFileName.path, contents: png, attributes: nil)
                }
                UIGraphicsEndImageContext()
            })
        }
    }
    
    open func isThumbnailAvailableFor(cameraKey: String, title: String) -> Bool {
        let key = getThumbnailKeyFor(cameraKey: cameraKey, title: title)
        return thumbnails.keys.contains(key)
    }

    open func isPreviewAvailableFor(cameraKey: String, title: String) -> Bool {
        let key = getThumbnailKeyFor(cameraKey: cameraKey, title: title)
        return previews.keys.contains(key)
    }
    
    
    open func getThumbnailImageFor(cameraKey: String, title: String) -> UIImage {
        let key = getThumbnailKeyFor(cameraKey: cameraKey, title: title)
        let path = thumbnails[key]
        let data = FileManager.default.contents(atPath: path!)!
        if (data.count > 0) {
            return UIImage(data: data)!
        }
        
        return #imageLiteral(resourceName: "camera_wifi")
    }
    
    open func getPreviewImageFor(cameraKey: String, title: String) -> UIImage {
        let key = getThumbnailKeyFor(cameraKey: cameraKey, title: title)
        let path = previews[key]
        let data = FileManager.default.contents(atPath: path!)!
        if (data.count > 0) {
            return UIImage(data: data)!
        }
        
        return #imageLiteral(resourceName: "camera_wifi")
    }
    
    open func generateThumbsFor(entity: PhotoEntity) {
        let assets:PHFetchResult<PHAsset> = PHAsset.fetchAssets(withLocalIdentifiers: [entity.localIdentifier!], options: nil)
        if (assets.count > 0) {
            //check if a thumbnail is already cached in the filesystem
            //and request a thumbnail image otherwise
            self.checkThumbnailImage(entity: entity, asset: assets[0])
            
            //check if a preview is already cached in the filesystem
            //and request a preview image otherwise
            self.checkPreviewImage(entity: entity, asset: assets[0])
        }        
    }
    
}
