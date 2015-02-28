//
//  TYTaskManager.swift
//  TYMutiTaskKit
//
//  Created by Tonny.hao on 2/12/15.
//  Copyright (c) 2015 Tonny.hao. All rights reserved.
//

import UIKit


private var concurrentContext = 0
private var serialContext = 1
private let kMutiTaskQueque = "tonny.hao.TYMutiTaskQueque"


class TYTaskManager: NSObject {
    
   private var concurrentQueque:NSOperationQueue = NSOperationQueue()
   private var serialQueque:NSOperationQueue {
        var serialThreadQueque = NSOperationQueue()
        serialThreadQueque.maxConcurrentOperationCount = 1
        return serialThreadQueque
    }
    
    private let workQueue = dispatch_queue_create(kMutiTaskQueque, DISPATCH_QUEUE_SERIAL)
    private var concurrentArray:[TYBaseTask] = []
    private var serialArray:[TYBaseTask] = []
    
    var concurrentNum:NSInteger = 5 {
        didSet {
            self.concurrentQueque.maxConcurrentOperationCount = self.concurrentNum
        }
    }
    
    // A shared instance of `TYTaskManager`
    class var sharedInstance: TYTaskManager {
        struct Singleton {
            static let instance = TYTaskManager()
        }
        return Singleton.instance
    }
    
    required override init() {
        super.init()
        concurrentQueque.addObserver(self, forKeyPath:"operationCount", options: .New, context: &concurrentContext)
        serialQueque.addObserver(self, forKeyPath:"operationCount", options: .New, context: &serialContext)

    }
    
    deinit{
        
    }
    
    func resumeAll() {
        self.serialQueque.suspended = false
        self.concurrentQueque.suspended = false
    }
    
    func PauseAll() {
        self.serialQueque.suspended = true
        self.concurrentQueque.suspended = true
    }
    
    func stopAll() {
        self.serialQueque.cancelAllOperations()
        self.concurrentQueque.cancelAllOperations()
    }
    
    
     override func observeValueForKeyPath(keyPath:String,ofObject:AnyObject,change:[NSObject:AnyObject],context:UnsafeMutablePointer<Void>){
        if(context == &concurrentContext){
            println("Changed to:\(change[NSKeyValueChangeNewKey]!)")
            var newOperationCount: AnyObject = change[NSKeyValueChangeNewKey]!
            var newNumber = (newOperationCount as NSNumber).integerValue
            if newNumber < self.concurrentNum {
                fetchConcurrentTask()
            }
            
        } else if (context == &serialContext) {
            println("Changed to:\(change[NSKeyValueChangeNewKey]!)")
        }
    }
    
    func setConcurrenceNum(aNum:Int){
        self.concurrentNum = aNum
    }
    
    /**
    *  from this method ,the task is added in the concurrent queque,and can be 
    *  processed base on task perioty and the task may not be processed immedately
    *
    *  @param aTask:TYBaseTask subclass object
    *
    *  @return boolean value indicate the add action whether succeed!
    */
    func addTask(aTask:TYBaseTask) -> Bool {
         var isAddSuc = true
         var isBlockFinished = -1
        dispatch_async(self.workQueue , {
            if self.concurrentArray.count < 1 {
                if self.concurrentQueque.operationCount < self.concurrentNum {
                    self.concurrentQueque.addOperation(aTask)
                    isBlockFinished = 1
                    return
                }
                self.concurrentArray.append(aTask)
                isBlockFinished = 1
                return
            }
            
            var filterArray = self.concurrentArray.filter({ (task:TYBaseTask) -> Bool in
                if task.taskID == aTask.taskID {
                    return true
                }else{
                    return false
                }
            })
            if filterArray.count < 1{
                self.concurrentArray.append(aTask)
            }else{
                var filterTask = filterArray[0]
                filterTask.priority = aTask.priority
                isAddSuc = false
            }
            isBlockFinished = 1

        })
        while isBlockFinished < 1  {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceReferenceDate:0.01))
        }
        return isAddSuc
    }
    
    /**
    *  if a task need to be processed immediately，we should use this method
    *
    *  @param aTask:TYBaseTask subclass object
    *
    *  @return boolean value indicate the add action whether succeed!
    */
    func addSyncTask(aTask:TYBaseTask) -> Bool {
        var isAddSuc = true
        var isBlockFinished = -1

        dispatch_async(self.workQueue , {
            if self.serialArray.count < 1 {
                self.serialArray.append(aTask)
                isBlockFinished = 1
                return
            }
            
            var filterArray = self.serialArray.filter({ (task:TYBaseTask) -> Bool in
                if task.taskID == aTask.taskID {
                    return true
                }else{
                    return false
                }
            })
            if filterArray.count < 1{
                self.serialArray.append(aTask)
            }else{
                var filterTask = filterArray[0]
                filterTask.priority = aTask.priority
                isAddSuc = false
            }
            isBlockFinished = 1
            
        })
        while isBlockFinished < 1  {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceReferenceDate:0.01))
        }
        return isAddSuc
    }
    
    /**
    *  remove the task in the queque or in the array
    *
    *  @param aTask:TYBaseTask subclass object
    *
    *  @return boolean value indicate the remove action whether succeed!
    */
    func removeTask(aTask:TYBaseTask) -> Bool {
        var isRemoveSuc = false
        var isBlockFinished = -1
         dispatch_async(self.workQueue , {
            //find the task from concurrent array (the task has not been added to concurrent thread queque)
            isRemoveSuc = self.removeTaskElementInArray(aTask, elementArray: &self.concurrentArray)
            
            /* find the task from concurrent thread queque, if finded,cancel the operation will cause the thread queque
            remove it form the queque
            */
            var quequeFilterArray = self.concurrentQueque.operations as [TYBaseTask]
            if quequeFilterArray.count > 0 {
                var index = -1
                var isFind = false
                for value:TYBaseTask in quequeFilterArray {
                    index += 1
                    if value.taskID == aTask.taskID {
                        isFind = true
                        value.cancel()
                        break
                    }
                }
                if isFind {
                    isRemoveSuc = true
                }
            }
            
            // find the task from serial array and remove it
            var isRemoveSerialSuc = self.removeTaskElementInArray(aTask, elementArray: &self.serialArray)
            if isRemoveSerialSuc {
                isRemoveSuc = isRemoveSerialSuc
            }
            isBlockFinished = 1
          })
        while isBlockFinished < 1  {
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceReferenceDate:0.01))
        }
        return isRemoveSuc
    }
    
    private func removeTaskElementInArray(aTask:TYBaseTask, inout elementArray:[TYBaseTask])->Bool{
        var isRemoveSuc = false
        var index = -1
        var isFind = false
        for value:TYBaseTask in elementArray {
            index += 1
            if value.taskID == aTask.taskID {
                isFind = true
                break
            }
        }
        if isFind {
            elementArray.removeAtIndex(index)
            isRemoveSuc = true
        }
       return isRemoveSuc
    }
    
    private func fetchConcurrentTask() {
        
        dispatch_async(self.workQueue , {
            println("courrent concurrent operate count is \(self.concurrentQueque.operationCount) ")
            if self.concurrentQueque.operationCount >= self.concurrentNum {
                return
            }
            if self.concurrentArray.count > 0 {
                println("concurrent array count is \(self.concurrentArray.count)")
                self.concurrentArray.sort({ (t1:TYBaseTask, t2:TYBaseTask) -> Bool in
                    if t1.priority < t1.priority {
                        return true
                    } else{
                        return false
                    }
                })
                var removedTask = self.concurrentArray.removeAtIndex(0)
                self.concurrentQueque.addOperation(removedTask)
                
            }
          
        })
    }
    
    private func fetchSerialTask() {
        dispatch_async(self.workQueue , {
            if self.serialArray.count > 0 {
                var count = self.serialArray.count
                var removedTask = self.serialArray.removeAtIndex(count-1)
                self.serialQueque.addOperation(removedTask)
            }
        })
    }
    
    /**
    *  query the task in the queque or in the array
    *
    *  @param aTaskId , task id that the unique indicating for the task
    *
    *  @return TYBaseTask that queryed task, return value maybe nil
    */
    func queryTask(aTaskId:String!) -> TYBaseTask? {
        var task:TYBaseTask?
        return  task;
    }
}
