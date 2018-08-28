//
//  FeedbackViewController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 20/04/17.
//  Copyright © 2017 Andras Bekesi. All rights reserved.
//

import Foundation
import WebKit

class FeedbackViewController : UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        let feedbackUrl:String = "https://github.com/spikehip/dslrbrowser-ios/issues"
        webView.load(URLRequest(url: URL(string: feedbackUrl)!))        
    }
    
}
