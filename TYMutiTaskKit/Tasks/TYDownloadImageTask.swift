//
//  TYDownloadImageTask.swift
//  TYMutiTaskKit
//
//  Created by Tonny.hao on 2/10/15.
//  Copyright (c) 2015 Tonny.hao. All rights reserved.
//

import Foundation
import UIKit
//import Alamofire

class TYDlImageTaskParam: TYBaseTaskParam {
    
    let imageUrl:String!
    var isCached = true
    required init(url:String) {
        super.init()
        self.imageUrl = url;
    }
    
}

class TYDlImageTaskResponse: TYBaseTaskResponse {
    
}

class TYDownloadImageTask: TYBaseTask {
    
    let dlService:TYBaseNetworkService = TYBaseNetworkService()
    var innerTask:Request?
    
    override weak var taskDelegate:TYTaskProtocol? {
        didSet {
            if self.taskResponse == nil {
                self.taskResponse = TYDlImageTaskResponse(id:self.taskID)
            }
        }
    }
    
    
    required init(param:TYBaseTaskParam) {
       super.init(param: param)
        if isIOS8orLater {
            self.qualityOfService = .Background
            self.name = "TYDownloadImageTask"
        }
        self.completionBlock = {
            
            var taskParam = self.taskParam as TYDlImageTaskParam
            println("the finished image url is \(taskParam.imageUrl)")
            if self.taskDelegate != nil {
                self.taskDelegate?.taskFinished(self.taskResponse!)
            }
        }
    }
    
    convenience init(imageUrl:String) {
        var param = TYDlImageTaskParam(url: imageUrl)
        self.init(param:param);
    }
    
    override func entry() {
        if self.cancelled {
            return
        }
        super.entry()
        var isServiceFinished = false
        
        var taskParam = self.taskParam as TYDlImageTaskParam
        dlService.Get(taskParam.imageUrl, parameters: nil, isCached:taskParam.isCached, success: { (jsonObj:AnyObject?, requestTask:Request) -> () in
            
            var jsonDic: AnyObject? = jsonObj
            isServiceFinished = true
            println("dlService.Get image url is \(taskParam.imageUrl)")

            }) { (errorDes:String?, requestTask:Request) -> () in
                var errorInfo = errorDes
                isServiceFinished = true
                println("dlService.Get image failed: \(errorDes)")


        }
        while !isServiceFinished {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceReferenceDate:0.01))
        }
    }
    
     override func cancel() {
        if let dlTask = innerTask {
            // TODO : clear the cache if requirement needed
            dlTask.cancel()
        }
        super.cancel()
    }
   
}
