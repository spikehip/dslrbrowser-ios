//
//  DownloadSessionDelegate.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 25/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation
import Photos
import CoreData
import CoreLocation

typealias CompleteHandlerBlock = () -> ()

class DownloadSessionDelegate : NSObject, URLSessionDelegate, URLSessionDownloadDelegate, CLLocationManagerDelegate {
    
    var handlerQueue: [String : CompleteHandlerBlock] = [String:CompleteHandlerBlock]()
    var item:MediaServer1ItemObject
    var geoLocation:CLLocation?
    var hasLocationFromPhone:Bool = false
    let locationManager:CLLocationManager = CLLocationManager()
    let prefs = UserDefaults.standard
    
    init(withItem item:MediaServer1ItemObject) {
        self.item = item
        super.init()
        let status = CLLocationManager.authorizationStatus()
        if (status == CLAuthorizationStatus.authorizedAlways ||
            status == CLAuthorizationStatus.authorizedWhenInUse ) {
            //request current location
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        if (locations.count > 0) {
            geoLocation = locations[locations.count - 1]
            hasLocationFromPhone = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        hasLocationFromPhone = false
        print("Location update failed:", error.localizedDescription)
    }
    
    func cleanUp(withURLs urlList:[URL]) {
        print("Cleaning up \(urlList)")
        do {
            for location in urlList{
                print("Attempting to remove \(location.path)")
                try FileManager.default.removeItem(atPath: location.path)
            }
        }
        catch {
            print(error)
        }
        
    }
    
    //MARK: session delegate
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("session error: \(error?.localizedDescription ?? "unknown error" ).")
        
    }
    
//    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
//        completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
//    }
    
    func addAssetToPhotoLibrary(_ location: URL) {
        let photoLibrary = PHPhotoLibrary.shared()
        let dc:DataController = DataController()
        var assetIdentifier:String = ""
        
        photoLibrary.performChanges(
            {() -> Void in
                print("Photos creating request for image at url \(location.absoluteString)")
                
                let insertGPS = self.prefs.bool(forKey: "insertGPS")
                let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: location)
                assetIdentifier = creationRequest?.placeholderForCreatedAsset?.localIdentifier ?? ""

                if (insertGPS && self.hasLocationFromPhone && creationRequest?.location == nil) {
                    creationRequest?.location = self.geoLocation
                }
                
                let cameraKey = CameraCollectionManager.getCameraKeyFor(mediaItem: self.item)
                let photoEntity:PhotoEntity = NSEntityDescription.insertNewObject(forEntityName: "PhotoEntity", into: dc.managedObjectContext) as! PhotoEntity
                photoEntity.cameraKey = cameraKey
                photoEntity.localIdentifier = assetIdentifier
                photoEntity.title = self.item.title
                print("Database entity prepared: ", photoEntity)
                
            }, completionHandler: {
                (success: Bool, error: Error?) -> Void in
                if (success) {
                    print("Photos change success \(success)");
                    do {
                        dc.waitUntilInitialized()
                        try dc.managedObjectContext.save()
                        print("PhotoEntity persisted ")
                        let downloadToAlbum:Bool = self.prefs.bool(forKey: "downloadToAlbum")
                        if (downloadToAlbum) {
                            let assets:PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                            if let asset:PHAsset = assets.firstObject {
                                self.addAssetToAlbum(withAsset: asset)
                            }
                        }
                    }
                    catch {
                        print("Error persisting PhotoEntity ", error)
                    }
                }
                else {
                    print("Photos change error \(error?.localizedDescription ?? "unknown error")")
                }
                
                self.cleanUp(withURLs: [location])
        })
    }
    
    func addAssetToAlbum(withAsset asset:PHAsset) {
        let photoLibrary = PHPhotoLibrary.shared()
        let albumName:String = prefs.string(forKey: "albumName") ?? "DSLRBrowser items"
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        var assetCollectionLocalIdentifier:String = ""
        
        if ( collection.firstObject == nil) {
            //Create Album and add PhotoEntity to Album
            photoLibrary.performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                assetCollectionLocalIdentifier = createAlbumRequest.placeholderForCreatedAssetCollection.localIdentifier
            }, completionHandler: { success, error in
                if (success) {
                    let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetCollectionLocalIdentifier], options: nil)
                    print(collectionFetchResult)
                    let assetCollection:PHAssetCollection = collectionFetchResult.firstObject! as PHAssetCollection
                    self.addAssetToAlbum(withAsset: asset, toAlbum: assetCollection)
                }
            })
        }
        else {
            //Add PhotoEntity to Album
            let album:PHAssetCollection = collection.firstObject! as PHAssetCollection
            addAssetToAlbum(withAsset: asset, toAlbum: album)
        }
    }
    
    func addAssetToAlbum(withAsset asset:PHAsset, toAlbum album:PHAssetCollection) {
        let photoLibrary = PHPhotoLibrary.shared()
        photoLibrary.performChanges({
            guard let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
                else {
                    print("Error creating PHAssetCollectionChangeRequest for ", album.localizedTitle ?? "No Title")
                    return
            }
            addAssetRequest.addAssets([asset] as NSArray)
        }, completionHandler: { success, error in
            if (success) {
                print(asset, "saved into", album)
            }
        })

    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("session \(session) has finished the download task \(downloadTask) of URL \(location).")
        
//        let image : CIImage = CIImage(contentsOfURL: location)!
//        for property in image.properties.keys {
//            let value:String = image.properties[property] as! String
//            print("\(property) => \(value)")
//        }
        
        let downloadsURLS : [URL] = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        
        if ( downloadsURLS.count > 0 ) {
            var filename:String = item.title
            if (!item.title.uppercased().hasSuffix(".JPG")) {
                filename = item.title + ".JPG"
            }
            let destination : URL = URL.init(fileURLWithPath: downloadsURLS[0].path + "/"+filename)
            
            do {
                try FileManager.default.createDirectory(at: downloadsURLS[0], withIntermediateDirectories: true, attributes: nil)
                FileManager.default.createFile(atPath: destination.absoluteString, contents: nil, attributes: nil)
                try FileManager.default.moveItem(atPath: location.path, toPath: destination.path)
                if ( PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized ) {
                    PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) -> Void in
                        if (status == PHAuthorizationStatus.authorized) {
                            self.addAssetToPhotoLibrary(destination)
                        }
                        else {
                            print("Not authorized to save")
                            self.cleanUp(withURLs: [location, destination])
                        }
                    })
                }
                else {
                    addAssetToPhotoLibrary(destination)
                }
                
            }
            catch {
                print("error", error)
                //clean up
                cleanUp(withURLs: [location, destination])
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("\(item.title) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes.")
        //send notification about progress
        let progressNotification:DownloadProgressNotification = DownloadProgressNotification.init(withItem: item, bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadProgress"), object: progressNotification)
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("session \(session) download task \(downloadTask) resumed at offset \(fileOffset) bytes out of an expected \(expectedTotalBytes) bytes.")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            print("session \(session.configuration.identifier ?? "default session identifier") download completed \(item.title)")
            //DownloadFinished notification
            let progressNotification:DownloadProgressNotification = DownloadProgressNotification.init(withItem: item, bytesWritten: 0, totalBytesWritten: 0, totalBytesExpectedToWrite: 0)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadFinished"), object: progressNotification)
            
        } else {
            print("session \(session) download failed with error \(error?.localizedDescription ?? "unknown error")")
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("background session \(session) finished events.")
        
        if !session.configuration.identifier!.isEmpty {
            callCompletionHandlerForSession(session.configuration.identifier)
        }
    }
    
    //MARK: completion handler
    func addCompletionHandler(_ handler: @escaping CompleteHandlerBlock, identifier: String) {
        handlerQueue[identifier] = handler
    }
    
    func callCompletionHandlerForSession(_ identifier: String!) {
        if ( identifier != nil && !handlerQueue.isEmpty && handlerQueue.keys.contains(identifier)) {
            let handler : CompleteHandlerBlock = handlerQueue[identifier]!
            handlerQueue.removeValue(forKey: identifier)
            handler()
        }
        else {
            print("Completion handler for identifier \(identifier) not found")
        }
    }
}
