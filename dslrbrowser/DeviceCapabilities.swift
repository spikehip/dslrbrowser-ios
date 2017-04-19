//
//  DeviceCapabilities.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 19/04/17.
//  Copyright © 2017 Andras Bekesi. All rights reserved.
//

import Foundation

class DeviceCapabilities {
    
    var device:MediaServer1Device
    var devicesWithTransmitter:[String] = ["6D", "5D Mark IV", "750D", "1300D", "760D", "70D", "80D", "M3", "M10", "IXUS 180", "IXUS 285 HS", "SX420 IS", "SX620 HS", "SX610 HS", "N2", "SX540 HS", "SX720 HS", "SX530 HS", "SX710 HS", "G9 X", "SX60 HS", "G7 X"]
    
    init(withDevice cameraDevice:MediaServer1Device) {
        self.device = cameraDevice
    }
    
    func hasBuiltInTransmitter() -> Bool {
        let friendlyName = self.device.friendlyName ?? "N/A"
        
        for deviceWithTransmitter:String in devicesWithTransmitter {
            if (friendlyName.uppercased().contains(deviceWithTransmitter.uppercased())) {
                return true
            }
        }
        
        return false
    }
    
}
