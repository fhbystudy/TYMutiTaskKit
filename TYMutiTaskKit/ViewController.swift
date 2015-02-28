//
//  ViewController.swift
//  TYMutiTaskKit
//
//  Created by Tonny.hao on 2/10/15.
//  Copyright (c) 2015 Tonny.hao. All rights reserved.
//

import UIKit

let dataSourceURL = NSURL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")

class ViewController: UIViewController {

    lazy var photos = NSDictionary(contentsOfURL:dataSourceURL!)!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        var priority:Int64 = 0
        for (key,value) in photos
        {
            priority += 2
            if (value as String).hasPrefix("http://") {
                var taskParam = TYDlImageTaskParam(url: value as String)
                var task = TYDownloadImageTask(param: taskParam)
                task.priority = priority
                task.taskID = value as String
                TYTaskManager.sharedInstance.addTask(task)
            }
            
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

