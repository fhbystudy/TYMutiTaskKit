//
//  TYBaseTask.swift
//  TYMutiTaskKit
//
//  Created by Tonny.hao on 2/10/15.
//  Copyright (c) 2015 Tonny.hao. All rights reserved.
//

import Foundation
import UIKit

enum TaskErrorType: Int {
  case  None,
        Canceled,
        FeedBackError,
        UnkonwError,
        OtherError
}

class TYBaseTaskParam:NSObject {
     var type:Int32?
     var isAsynchronize:Bool = true
}



class TYBaseTaskResponse:NSObject {
    var taskID:String!
    var taskIsSuc = true
    var errorType:TaskErrorType? = .None
    
    /**
    *  the real content that return to outside
    *  @Discussion: [String:AnyObject] like (eg : succed:jsonDic, failed:errorObj),
    *  and currently the key must be 'succed' or 'failed', and the value can be any object.
    */
    var responseContent:[String:AnyObject]? = [kRespoinseKeySucced:""]
    
    required init(id:String) {
        super.init()
        taskID = id;
    }
}

@objc protocol TYTaskProtocol {
    
    func taskFinished(response:TYBaseTaskResponse)
}


class TYBaseTask: NSOperation {
    
    var taskID:String! = NSDate().description {
        didSet {
            if self.taskResponse != nil {
                self.taskResponse!.taskID = self.taskID
            }
        }
    }
     var priority:Int64!

     let taskParam:TYBaseTaskParam!
     var taskResponse:TYBaseTaskResponse?
     weak var taskDelegate:TYTaskProtocol?
    
     required init(param:TYBaseTaskParam) {
        super.init()
        self.taskParam = param
     }
    
    internal func entry() {
        if self.cancelled {
            return
        }
    }

    override func main() {
       autoreleasepool {
           self.entry();
        }
    }
    
    override func cancel() {
        if self.taskDelegate != nil {
            self.taskResponse?.taskIsSuc = false
            self.taskResponse?.errorType = .Canceled
            self.taskResponse?.responseContent = [kResponseKeyFailed:"task is canceld"]
            self.taskDelegate?.taskFinished(self.taskResponse!)
        }
        super.cancel()
    }
   
}
