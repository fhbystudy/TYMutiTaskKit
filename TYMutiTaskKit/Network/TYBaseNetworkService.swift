//
//  TYBaseNetworkService.swift
//  TYMutiTaskKit
//
//  Created by Tonny.hao on 2/10/15.
//  Copyright (c) 2015 Tonny.hao. All rights reserved.
//

import UIKit
//import Alamofire

public typealias TYCompleteClosure = (AnyObject?,Request) -> ()
public typealias TYFailureClosure = (String?, Request) -> ()

class TYBaseNetworkService: NSObject {
    
    let requestTaskManager:Manager = {
        
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders()
        configuration.requestCachePolicy = .ReturnCacheDataElseLoad
        let manager = Manager(configuration: configuration)
        
        return manager
    }()
    let serializer = Request.JSONResponseSerializer(options: .AllowFragments)

    
    /**
    *  Default Get method,
    *
    *  @param urlString:String          the absolute url location for get request
    *  @param AnyObject]?               the Dictionary parameter
    *  @param success:TYCompleteClosure succeed closure
    *  @param failure:TYFailureClosure  failed closure
    *
    *  @return Request task for : Cancel ,resume ,or followed Cache operating
    */
    func Get(urlString:String ,parameters:[String : AnyObject]?,success:TYCompleteClosure,failure:TYFailureClosure)->Request {
        
        let requestTask = requestTaskManager.request(.GET, urlString, parameters: parameters)
            requestTask.response(serializer: serializer){ (request, response, string, error) in
            if  error != nil {
                success(response as AnyObject? ,requestTask)
            } else{
                failure(error?.description,requestTask)
            }
        }
        return requestTask
    }
    
    /**
    *  Get request， and content cache is distinct by boolean var isCached
    *
    *  @param urlString:String          the absolute url location for get request
    *  @param AnyObject]?               the Dictionary parameter
    *  @param isCached:Bool             whether the conente is cached!
    *  @param success:TYCompleteClosure succeed closure
    *  @param failure:TYFailureClosure  failed closure
    *
    *  @return  Request task for : Cancel ,resume ,or followed Cache operating
    */
    func Get(urlString:String ,parameters:[String : AnyObject]?,isCached:Bool, success:TYCompleteClosure,failure:TYFailureClosure)->Request {
        
        if isCached {
           self.requestTaskManager.session.configuration.requestCachePolicy = .ReturnCacheDataElseLoad
        }else{
            self.requestTaskManager.session.configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        }
        
        let requestTask = self.requestTaskManager.request(.GET, urlString, parameters: parameters)
        requestTask.response(serializer: serializer){ (request, response, string, error) in
            if  error != nil {
                success(response as AnyObject? ,requestTask)
            } else{
                failure(error?.description,requestTask)
            }
        }
        return requestTask
    }
    
    
    /**
    *  Default Post method,
    *
    *  @param urlString:String          the absolute url location for get request
    *  @param AnyObject]?               the Dictionary parameter
    *  @param success:TYCompleteClosure succeed closure
    *  @param failure:TYFailureClosure  failed closure
    *
    *  @return Request task for : Cancel ,resume ,or followed Cache operating
    */
    func Post(urlString:String ,parameters:[String : AnyObject]?,success:TYCompleteClosure,failure:TYFailureClosure)->Request{
        
        // Post method should not use catch!!!
        self.requestTaskManager.session.configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        
        let requestTask = self.requestTaskManager.request(.POST, urlString, parameters: parameters)
        requestTask.response(serializer: serializer){ (request, response, string, error) in
            if  error != nil {
                success(response as AnyObject? ,requestTask)
            } else{
                failure(error?.description,requestTask)
            }
        }
        return requestTask
    }

}
