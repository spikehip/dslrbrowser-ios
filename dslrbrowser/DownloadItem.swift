//
//  DownloadItem.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 20/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation

open class DownloadItem {
 
    var url:URL
    var item:MediaServer1ItemObject
    var delegate : DownloadSessionDelegate
    
    init(withURL url:String, item: MediaServer1ItemObject) {
        self.url = URL.init(string: url)!
        self.item = item
        self.delegate = DownloadSessionDelegate.init(withItem: item)
    }
    
    open func download() {
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: url.absoluteString)
        backgroundSessionConfiguration.sessionSendsLaunchEvents = true
        backgroundSessionConfiguration.isDiscretionary = true
        
        let session = URLSession(configuration: backgroundSessionConfiguration, delegate: self.delegate, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        DownloadSessionDelegateFactory.sharedInstance.registerDelegate(withIdentifier: url.absoluteString, delegate: self.delegate)
        
        task.resume()
    }
        
}
