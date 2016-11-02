//
//  DownloadSessionDelegateFactory.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 26/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation

class DownloadSessionDelegateFactory {

    var delegates: [String : DownloadSessionDelegate]? = nil
    
    static let sharedInstance:DownloadSessionDelegateFactory = {
        let instance = DownloadSessionDelegateFactory()
        return instance
    }()

    convenience init() {
        self.init(array: [String:DownloadSessionDelegate]())
    }
    
    init( array:[String:DownloadSessionDelegate] ) {
        delegates = array
    }
    
    func registerDelegate(withIdentifier identifier:String, delegate: DownloadSessionDelegate) {
        delegates?[identifier] = delegate
    }
    
    func getDelegate(forIdentifier identifier:String) -> DownloadSessionDelegate {
        return delegates![identifier]!
    }
}
