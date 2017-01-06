//
//  PTPCameraCollectionManager.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 05/01/17.
//  Copyright © 2017 Andras Bekesi. All rights reserved.
//

import Foundation

open class PTPCameraCollectionManager {
    
    static var devices = [String : BasicUPnPDevice]()
    
    static func getCameraKeyFor(section:Int) -> String {
        var i=0
        for key in devices.keys {
            if (i==section) {
                return key
            }
            i += 1
        }
        return ""
    }
    
}
