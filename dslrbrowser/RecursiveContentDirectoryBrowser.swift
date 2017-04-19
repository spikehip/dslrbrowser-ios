
//
//  RecursiveContentDirectoryBrowser.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 31/10/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation
import CoreData

class RecursiveContentDirectoryBrowser {
    
    var contentDirectory: SoapActionsContentDirectory1
    var items = [MediaServer1BasicObject]()
    var sortCriteria: String
    var cameraKey : String
    var itemCollection : MediaServer1BasicObjectCollection
    let dc:DataController = DataController()
    
    init(withContentDirectory directory:SoapActionsContentDirectory1, deviceBaseUrl: String) {
        contentDirectory = directory
        cameraKey = deviceBaseUrl
        itemCollection = CameraCollectionManager.getItemCollectionFor(cameraKey: cameraKey)
        
        sortCriteria = ""
        let outSortCaps : NSMutableString = NSMutableString.init()
        contentDirectory.getSortCapabilities(withOutSortCaps: outSortCaps)
        print("["+cameraKey+"]" ,"Found sorting capabilities", outSortCaps)
        
        let deviceCapabilities: DeviceCapabilities = DeviceCapabilities.init(withDevice: CameraCollectionManager.devices[cameraKey]!)
        
        if (deviceCapabilities.hasBuiltInTransmitter()) {
            if (outSortCaps.range(of: "dc:date").location != NSNotFound ) {
                sortCriteria = "+dc:date"
            }            
            if (outSortCaps.range(of: "dc:title").location != NSNotFound ) {
                sortCriteria = "+dc:title"
            }
        }
        print("["+cameraKey+"]" ,"Using sorting flags", sortCriteria)
        dc.waitUntilInitialized()
    }
    
    func browseTree() {
        browseLevel(fromObjectId: "0")
    }
    
    func browseLevel(fromObjectId objectId:String) {
        print("["+cameraKey+"]" , "Browsing level with objectId: ", objectId)
        let nodes = getNodesInLevel(fromObjectId: objectId)
        print("["+cameraKey+"]" ,"Found \(nodes.count) nodes and counting a total of \(itemCollection.items.count) items")
        //itemCollection.setFolderFetched(withFolderId: objectId)
        
        for node in nodes {
            if (node.isContainer && !itemCollection.isFolderFetched(withFolderId: node.objectID)) {
                print("["+cameraKey+"]" ,"Recursive browsing node ",node.objectID)
                    browseLevel(fromObjectId: node.objectID)
            }
            else if (node.isContainer && itemCollection.isFolderFetched(withFolderId: node.objectID)){
                print("["+cameraKey+"]" ,"Folder already fetched ",node.objectID)
            }
        }
    }
    
    func getNodesInLevel(fromObjectId objectId:String) -> [MediaServer1BasicObject] {
        let m_playList = NSMutableArray.init(capacity: 1)
        let outResult : NSMutableString = NSMutableString.init()
        let outNumberReturned : NSMutableString = NSMutableString.init()
        let outTotalMatches : NSMutableString = NSMutableString.init()
        let outUpdateId : NSMutableString = NSMutableString.init()
        var nodes = [MediaServer1BasicObject]()
        
        contentDirectory.browse(withObjectID: objectId, browseFlag: "BrowseDirectChildren", filter: "*", startingIndex: "0", requestedCount: "100", sortCriteria: sortCriteria, outResult: outResult, outNumberReturned: outNumberReturned, outTotalMatches: outTotalMatches, outUpdateID: outUpdateId)
        
        // some transmitter does not like the sort criteria defined and may freeze.
        // if this is the case the outNumberReturned and outTotalMatches strings are empty. 
        // TODO: make this code a bit nicer
        if ( outTotalMatches.length == 0 && outNumberReturned.length == 0 ) {
            print("["+cameraKey+"]" ,"TODO: do something with invalid responses where outNumberReturned and outTotalMatches are empty strings", outUpdateId)
        }
        
        print("["+cameraKey+"]" ,"browseWithObjectID returned total number of \(outNumberReturned) items of \(outTotalMatches) matches")
        
        let didl : Data = outResult.data(using: String.Encoding.utf8.rawValue)!
        let parser : MediaServerBasicObjectParser = MediaServerBasicObjectParser.init(mediaObjectArray: m_playList, itemsOnly: false)
        
        parser.parse(from: didl)
        
        for item in m_playList {
            if (!(item as AnyObject).isContainer) {
                let image:MediaServer1ItemObject = item as! MediaServer1ItemObject
                itemCollection.addItem(withObject: image)
                let photoEntityFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoEntity")
                photoEntityFetchRequest.predicate = NSPredicate.init(format: "cameraKey == %@ and title == %@", self.cameraKey, image.title)
                do {
                    let fetchedPhotoEntities = try dc.managedObjectContext.fetch(photoEntityFetchRequest) as! [PhotoEntity]
                    for entity in fetchedPhotoEntities {
                        print("["+cameraKey+"]" ,"Found item registered as downloaded ",entity.localIdentifier ?? "???")
                    }
                    if (fetchedPhotoEntities.count > 0) {
                        CameraCollectionManager.addFinishedDownloadFor(cameraKey: self.cameraKey, title: image.title)
                    }
                } catch {
                    print("["+cameraKey+"]" , "Failed to fetch photos:", error)
                    fatalError("Failed to fetch photos: \(error)")
                }
                
            }
            else {
                let obj:MediaServer1BasicObject = item as! MediaServer1BasicObject
                nodes.append(obj)
            }
        }
        
        return nodes
    }
    
    func getItems() -> [MediaServer1BasicObject] {
        return items
    }
    
}
