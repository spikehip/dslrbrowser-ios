//
//  DownloadSessionDelegate.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 25/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation
import Photos

typealias CompleteHandlerBlock = () -> ()

class DownloadSessionDelegate : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    
    var handlerQueue: [String : CompleteHandlerBlock] = [String:CompleteHandlerBlock]()
    var item:MediaServer1ItemObject
    
    init(withItem item:MediaServer1ItemObject) {
        self.item = item
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
        print("session error: \(error?.localizedDescription).")
        
    }
    
//    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
//        completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
//    }
    
    func addAssetToPhotoLibrary(_ location: URL) {
        let photoLibrary = PHPhotoLibrary.shared()
        photoLibrary.performChanges(
            {() -> Void in
                print("Photos creating request for image at url \(location.absoluteString)")
                let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: location)
                let assetIdentifier = creationRequest?.placeholderForCreatedAsset?.localIdentifier
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier!], options: nil)
                if ( assets.count > 0 ) {
                    let asset = assets[0] 
                    print("created: \(asset.creationDate)")
                    print("modified: \(asset.modificationDate)")
                    if ( asset.canPerform(PHAssetEditOperation.properties)) {
                        let changeRequest = PHAssetChangeRequest(for: asset)
                        changeRequest.isFavorite = true
                    }
                    
                }
            }, completionHandler: {
                (success: Bool, error: Error?) -> Void in
                if (success) {
                    print("Photos change success \(success)");
                }
                else {
                    print("Photos change error \(error?.localizedDescription)")
                }
                
                self.cleanUp(withURLs: [location])
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
            print("session \(session.configuration.identifier) download completed \(item.title)")
            //DownloadFinished notification
            let progressNotification:DownloadProgressNotification = DownloadProgressNotification.init(withItem: item, bytesWritten: 0, totalBytesWritten: 0, totalBytesExpectedToWrite: 0)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "DownloadFinished"), object: progressNotification)
            
        } else {
            print("session \(session) download failed with error \(error?.localizedDescription)")
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
