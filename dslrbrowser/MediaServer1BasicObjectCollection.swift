//
//  MediaServer1ItemCollection.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 25/11/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation

open class MediaServer1BasicObjectCollection {
    
    var items = [String: MediaServer1ItemObject]()
    var foldersFetched :Set<String> = Set<String>()
    var cameraKey : String
    
    init(withCameraKey cameraKey:String) {
        self.cameraKey = cameraKey
    }
    
    func addItem(withObject mediaServer1BasicObject:MediaServer1ItemObject) {
        if (!items.keys.contains(mediaServer1BasicObject.objectID)) {
            items[mediaServer1BasicObject.objectID] = mediaServer1BasicObject;
        }
    }
    
    func getItems() -> [MediaServer1ItemObject] {
        return [MediaServer1ItemObject] (items.values)
    }
    
    func setFolderFetched(withFolderId objectId:String) {
        if (!foldersFetched.contains(objectId)) {
            foldersFetched.insert(objectId)
        }
    }
    
    func isFolderFetched(withFolderId objectId:String) -> Bool {
        return foldersFetched.contains(objectId)
    }
    
    func getItemAt(_ position: Int) -> MediaServer1ItemObject {
        var i=0
        for item in items.values {
            if (i == position) {
                return item
            }
            i += 1
        }
        
        return MediaServer1ItemObject.init()
    }
    
    func getImageURL(withObjectId objectId:String, quality: Int) -> String {
        if ( items.keys.contains(objectId) ) {
            let item = items[objectId]
            return MediaServer1BasicObjectCollection.getImageURL(fromObject: item!, quality: quality)
        }
        
        return ""
    }
    
    static func getImageURL(fromObject object:MediaServer1ItemObject, quality: Int) -> String {
        let uriDictionary : [String: String] = object.uriCollection as! [String: String]
        var url : String = ""
        if (object.uriCollection.count >= quality+1) {
            for protocolInfo in uriDictionary.keys {
                let protocolInfos:[String] = protocolInfo.split{$0 == ";"}.map(String.init)
                let uri = uriDictionary[protocolInfo]
                if (protocolInfos.count > 1 && protocolInfos[0] == ImageQuality.IMAGE_QUALITY_PROTOCOL_INFO[quality]) {
                    print("Found protocolInfo quality ", protocolInfos[0])
                    url = uri!
                    break
                }
            }
            //no protocol info was found, take the first value as at least one shall be available
            if (url == "") {
                url = uriDictionary.values.first!
            }
        }
        else if ( object.uriCollection.count >= 1 ) {
            url = uriDictionary.values.first!            
        }
        
        return url
    }
    
    func getImageURLAt(withPosition position:Int, quality: Int) -> String {
        if (items.count >= position ) {
            var i=0
            for item in items.values {
                if (i==position) {
                    return getImageURL(withObjectId: item.objectID, quality: quality)
                }
                i += 1
            }
            //let item = ([MediaServer1ItemObject] (items.values))[position]
            //return getImageURL(withObjectId: item.objectID, quality: quality)
        }
        
        return ""
    }
    
    func getImageTitleAt(withPosition position: Int) -> String {
        if (items.count >= position ) {
            var i=0
            for item in items.values {
                if (i==position) {
                    return item.title
                }
                i += 1
            }
            //let item = ([MediaServer1ItemObject] (items.values))[position]
            //return getImageURL(withObjectId: item.objectID, quality: quality)
        }
        
        return ""
    }
    
}
