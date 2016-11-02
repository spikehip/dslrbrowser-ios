//
//  ImageQuality.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 08/12/15.
//  Copyright © 2015 Andras Bekesi. All rights reserved.
//

import Foundation

public struct ImageQuality {
    static let IMAGE_QUALITY_LOW : Int = 0                  //640x480
    static let IMAGE_QUALITY_ORIGINAL_ROTATED : Int = 1     //5472x3648
    static let IMAGE_QUALITY_THUMBNAIL : Int = 2            //160x120
    static let IMAGE_QUALITY_HIGH : Int = 3                 //1632x1088
    
    static let IMAGE_QUALITY_PROTOCOL_INFO : [String] =
    ["http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_SM",
     "http-get:*:image/jpeg:",
     "http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_TN",
     "http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_LRG"
    ]
    
    //0 => 640x480
    //1 => 5472x3648
    //2 => 160x120
    //3 => 1632x1088
}
