
import Foundation

class LiveStreamingManager: NSObject {
    
    class var sharedInstance: LiveStreamingManager {
        struct Singleton {
            static let instance = LiveStreamingManager()
        }
        return Singleton.instance
    }
    
    //PRAGMA MARK:- initialiseLiveStreaming
    //Method to initialize live streaming with userid, tocken, success and failure block
    func initialiseLiveStreaming(loginId loginId: String, tocken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().POST(UrlManager.sharedInstance.liveStreamingAPIUrl(), parameters: ["userName":loginId,"access_token": tocken], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code:"ResponseInvalid")
            }
            
            }, failure: { (operation, error) -> Void in
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                //The credentials were wrong or the network call failed
                failure?(error: error, code:failureErrorDesc)
        })
    }
    
    //PRAGMA MARK:- startLiveStreaming
    //Method to start live streaming with user tocken and stream tocken, success and failure block
    func startLiveStreaming(loginId loginId: String, accesstocken: String,streamTocken:String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.liveStreamingAPIUrl() + "/" + streamTocken, parameters: ["userName":loginId,"access_token":accesstocken,"action":"startStream"],success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            }, failure: { (operation, error) -> Void in
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                failure?(error: error, code:failureErrorDesc)
        })
    }
    
    //PRAGMA MARK:- stopLiveStreaming
    //Method to start live streaming with user tocken and stream tocken, success and failure block
    func stopLiveStreaming(loginId loginId: String, accesstocken: String,streamTocken:String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.liveStreamingAPIUrl() + "/" + streamTocken, parameters: ["userName":loginId,"access_token":accesstocken,"action":"stopStream"],success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            }, failure: { (operation, error) -> Void in
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                failure?(error: error, code:failureErrorDesc)
        })
    }
    
    
    //PRAGMA MARK:- getAllLiveStreams
    
    func getAllLiveStreams(loginId loginId: String, accesstocken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.liveStreamingAPIUrl(), parameters: ["userName":loginId,"access_token":accesstocken], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            },failure: { (operation, error) -> Void in
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                failure?(error: error, code:failureErrorDesc)
        })
    }
    
    //PRAGMA MARK:- Default Stream Mapping
    
    func defaultStreamMapping(loginId loginId: String, accesstocken: String, streamTockn: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().POST(UrlManager.sharedInstance.liveStreamingAPIUrl() + "/" + streamTockn, parameters: ["userName":loginId,"access_token":accesstocken], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            },failure: { (operation, error) -> Void in
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                failure?(error: error, code:failureErrorDesc)
        })
    }
}