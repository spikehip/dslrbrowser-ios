//
//  DownloadProgressNotification.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 28/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation

class DownloadProgressNotification {
    var item: MediaServer1ItemObject
    var bytesWritten:Float64
    var totalBytesWritten:Float64
    var totalBytesExpectedToWrite:Float64
    
    init(withItem item:MediaServer1ItemObject, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite:Int64) {
        self.item = item
        self.bytesWritten = Float64(bytesWritten)
        self.totalBytesWritten = Float64(totalBytesWritten)
        self.totalBytesExpectedToWrite = Float64(totalBytesExpectedToWrite)
    }
    
    func calculateProgressPercent() -> Float64 {
        return (100.0*totalBytesWritten) / totalBytesExpectedToWrite
    }
    
    func calculateProgress() -> Float {
        return Float(totalBytesWritten / totalBytesExpectedToWrite)
    }
    
}