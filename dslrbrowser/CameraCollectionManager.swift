//
//  CameraCollectionManager.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 08/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation

open class CameraCollectionManager {
    
    static var cameras = [String : MediaServer1BasicObjectCollection]()
    static var devices = [String : MediaServer1Device]()
    static var downloads = [String: [String]]()
    
    static func getItemCollectionFor(cameraKey:String) -> MediaServer1BasicObjectCollection {
        if ( !cameras.keys.contains(cameraKey)) {
            cameras[cameraKey] = MediaServer1BasicObjectCollection.init(withCameraKey: cameraKey)
        }
        
        return cameras[cameraKey]!
    }
    
    static func removeItemCollectionFor(cameraKey:String) {
        cameras.removeValue(forKey: cameraKey)
    }
    
    static func getCameraKeyFor(section:Int) -> String {
        var i=0
        for key in cameras.keys {
            if (i==section) {
                return key
            }
            i += 1
        }
        return ""
    }
    
    static func getIndexPathFor(cameraKey:String) -> IndexPath {
        var i=0
        for key in cameras.keys {
            if (key == cameraKey) {
                break;
            }
            i += 1
        }
        return IndexPath.init(row: 0, section: 0)
    }
    
    static func getCamerasCount() -> Int {
        return cameras.count
    }
    
    static func getImageCountFor(cameraKey:String) -> Int {
        if (cameras.keys.contains(cameraKey)) {
            return cameras[cameraKey]!.items.count
        }
        return 0
    }
    
    static func getTotalImageCount() -> Int {
        var i=0
        for cameraKey in cameras.keys  {
            i+=(cameras[cameraKey]?.items.count)!
        }
        return i
    }
    
    static func addFinishedDownloadFor(cameraKey:String, title: String) {
        if ( !downloads.keys.contains(cameraKey) ) {
            downloads[cameraKey] = [String]()
        }
        
        downloads[cameraKey]!.append(title)
    }
    
    static func isDownloadFinishedFor(title:String, cameraKey:String) -> Bool {
        if (downloads.keys.contains(cameraKey)) {
            return (downloads[cameraKey]?.contains(title))!
        }
        
        return false
    }
    
    static func getDownloadCountFor(cameraKey:String) -> Int {
        if (downloads.keys.contains(cameraKey)) {
            return downloads[cameraKey]!.count
        }
        return 0
    }
    
    static func getDownloadProgressFor(cameraKey:String) -> Float {
        let total = Float(CameraCollectionManager.getImageCountFor(cameraKey: cameraKey))
        let cnt = Float(CameraCollectionManager.getDownloadCountFor(cameraKey: cameraKey))
        if ( total > 0 ) {
            return cnt / total
        }
        else {
            return 0.0
        }
    }
    
    static func getCameraKeyFor(mediaItem item: MediaServer1ItemObject) -> String {
        let url1:String = MediaServer1BasicObjectCollection.getImageURL(fromObject: item, quality: ImageQuality.IMAGE_QUALITY_THUMBNAIL)
        let url:URL = URL.init(string: url1)!
        let key = url.scheme! + "://" + url.host!
//            + ":" + url.port!.stringValue
        
        return key
    }
}
