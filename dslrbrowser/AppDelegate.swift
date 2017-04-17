//
//  AppDelegate.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 11/10/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
//    var delegate : DownloadSessionDelegate = DownloadSessionDelegate.sharedInstance

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Set user preference defaults
        let prefs = UserDefaults.standard
        let prefsDictionary:Dictionary = prefs.dictionaryRepresentation()
        if ( !prefsDictionary.keys.contains("insertGPS") ) {
            prefs.set(false, forKey: "insertGPS")
        }
        if ( !prefsDictionary.keys.contains("useOnlyCanon") ) {
            prefs.set(true, forKey: "useOnlyCanon")
        }
        if ( !prefsDictionary.keys.contains("downloadToAlbum") ) {
            prefs.set(false, forKey: "downloadToAlbum")
        }
        if ( !prefsDictionary.keys.contains("generateAlbumName") ) {
            prefs.set(true, forKey: "generateAlbumName")
        }
        if ( prefs.bool(forKey: "generateAlbumName") ) {
            prefs.set(DownloadToAlbumController.generateAlbumName(), forKey: "albumName")
        }
        
        

        ThumbnailCacheManager.defaultManager.refresh()
        
        /*
         let assets:PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
         assets.enumerateObjects({ asset,_,_ in
         print(asset)
         print(asset.localIdentifier)
         let options:PHImageRequestOptions = PHImageRequestOptions.init()
         options.isSynchronous = true
         PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: {
         data,_,_,info in
         print(info)
         })
         })
         */
         /*
 <PHAsset: 0x17fbd790> 3F4CEF0A-8C11-483D-BBD2-A27EC3310579/L0/001 mediaType=1/0, sourceType=1, (3648x5472), creationDate=2016-08-20 13:29:47 +0000, location=1, hidden=0, favorite=0
 3F4CEF0A-8C11-483D-BBD2-A27EC3310579/L0/001
 Optional([AnyHashable("PHImageResultWantedImageFormatKey"): 9999, AnyHashable("PHImageResultOptimizedForSharing"): 0, AnyHashable("PHImageResultIsPlaceholderKey"): 0, AnyHashable("PHImageFileSandboxExtensionTokenKey"): f9994d8f875db567ed6c04afa6a30ed6bda8869c;00000000;00000000;0000001a;com.apple.app-sandbox.read;00000001;01000002;0000000000aac0a3;/private/var/mobile/Media/DCIM/100APPLE/IMG_0608.JPG, AnyHashable("PHImageResultIsDegradedKey"): 0, AnyHashable("PHImageResultDeliveredImageFormatKey"): 9999, AnyHashable("PHImageResultIsInCloudKey"): 0, AnyHashable("PHImageFileUTIKey"): public.jpeg, AnyHashable("PHImageFileURLKey"): file:///var/mobile/Media/DCIM/100APPLE/IMG_0608.JPG, AnyHashable("PHImageFileDataKey"): <PLXPCShMemData: 0x17fb8180> bufferLength=5230592 dataLength=5228792, AnyHashable("PHImageFileOrientationKey"): 2])
        */
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("Maybe clear up the caches at this point")
        let cacheDirectory:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        do {
            let files:[String] = try FileManager.default.contentsOfDirectory(atPath: cacheDirectory.path)
            for file in files {
                if (file.hasPrefix("dslrbrowser")) {
                    let cacheFile:URL = URL.init(fileURLWithPath: cacheDirectory.path + "/" + file )
                    try FileManager.default.removeItem(atPath: cacheFile.path)
                    print("Cache item ", cacheFile.path, " cleared")
                }
            }
        }
        catch {
            print("Error cleaning cache")
        }
        
        ThumbnailCacheManager.defaultManager.cleanUpDatabase()
    }
    
    func application(_ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            print("performFetchWithCompletionHandler called")
            completionHandler(UIBackgroundFetchResult.noData)
    }

    //MARK: background session handling
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("-- handleEventsForBackgroundURLSession --")
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
        let delegate : DownloadSessionDelegate = DownloadSessionDelegateFactory.sharedInstance.getDelegate(forIdentifier: identifier)
        
        let backgroundSession = URLSession(configuration: backgroundConfiguration, delegate: delegate, delegateQueue: nil)
        print("Rejoining session \(backgroundSession)")
        
        delegate.addCompletionHandler(completionHandler, identifier: identifier)
    }


}

