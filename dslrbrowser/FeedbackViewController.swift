//
//  FeedbackViewController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 20/04/17.
//  Copyright © 2017 Andras Bekesi. All rights reserved.
//

import Foundation

class FeedbackViewController : UIViewController {
    
    override func viewDidLoad() {
        let feedbackUrl:String = "https://github.com/spikehip/dslrbrowser-ios/issues"
        (self.view as! UIWebView).loadRequest(URLRequest(url: URL(string: feedbackUrl)!))
    }
    
}
