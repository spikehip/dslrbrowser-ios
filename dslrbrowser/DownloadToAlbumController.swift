//
//  DownloadToAlbumController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 17/04/17.
//  Copyright © 2017 Andras Bekesi. All rights reserved.
//

import Foundation

class DownloadToAlbumController:UIViewController {

    @IBOutlet var switchAutoFill:UISwitch?
    @IBOutlet var albumName:UITextField?
    
    
    override func viewDidLoad() {
        let prefs = UserDefaults.standard
        let generateAlbumName = prefs.bool(forKey: "generateAlbumName")
        switchAutoFill?.setOn(generateAlbumName, animated: false)
        albumName?.text = prefs.string(forKey: "albumName")
        if (generateAlbumName) {
            albumName?.isEnabled = false
        }
        else {
            albumName?.isEnabled = true
        }
    }
    
    @IBAction func switchAutoFillChanged(sender: UISwitch) {
        let prefs = UserDefaults.standard
        prefs.set(sender.isOn, forKey: "generateAlbumName")
        if (sender.isOn) {
            let generatedName:String = DownloadToAlbumController.generateAlbumName()
            albumName?.text = generatedName
            albumName?.isEnabled = false
            prefs.set(generatedName, forKey: "albumName")
        }
        else {
            albumName?.text = ""
            albumName?.isEnabled = true
        }
    }
    
    @IBAction func textChanged(sender: UITextField) {
        let prefs = UserDefaults.standard
        let name : String = sender.text ?? DownloadToAlbumController.generateAlbumName()
        prefs.set(name, forKey: "albumName")
        showToast(message: name + " saved" )
    }
    
    static func generateAlbumName() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func showToast(message : String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height/2 - 17, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.green.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 2.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
}
