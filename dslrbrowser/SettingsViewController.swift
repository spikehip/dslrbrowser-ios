//
//  SettingsViewController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 05/01/17.
//  Copyright © 2017 Andras Bekesi. All rights reserved.
//

import Foundation

class SettingsViewController:UITableViewController {

    @IBOutlet var switchOnlyCanon:UISwitch?
    @IBOutlet var switchInsertGPS:UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()
        let prefs = UserDefaults.standard
        switchOnlyCanon?.setOn(prefs.bool(forKey: "useOnlyCanon"), animated: false)
        switchInsertGPS?.setOn(prefs.bool(forKey: "insertGPS"), animated: false)
    }
    
    @IBAction func switchOnlyCanonChanged(sender: UISwitch) {
        let prefs = UserDefaults.standard
        prefs.set(sender.isOn, forKey: "useOnlyCanon")
    }
    
    
}
