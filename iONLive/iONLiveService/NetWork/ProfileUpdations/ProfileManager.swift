
import UIKit

class ProfileManager: NSObject,URLSessionDelegate,URLSessionTaskDelegate, URLSessionDataDelegate {
    
    class var sharedInstance: ProfileManager {
        struct Singleton {
            static let instance = ProfileManager()
        }
        return Singleton.instance
    }
    
    //Method to get user details, success and failure block
    func getUserDetails(userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getProfileDataAPIUrl(userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            if let responseObject = response as? [String:AnyObject]
            {
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error code from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    func resetPassword(userName: String, accessToken: String, resetPassword: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.getResetPasswordAPIUrl(userName: userName, accessToken: accessToken), parameters: ["newPassword":resetPassword], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error code from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    func getSubUserProfileImage(userName: String, accessToken: String, subscriberUserName: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?){
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getSubscriberProfileImageAPIUrl(userName: userName, accessToken: accessToken, subscriberUserName: subscriberUserName), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error code from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    func uploadProfileImage(userName: String, accessToken: String, profileImage: NSData, actualImageUrl: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?){
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.getProfileImageUploadAPIUrl(userName: userName, accessToken: accessToken, actualImageUrl: actualImageUrl), parameters: nil, constructingBodyWith: { (formData: AFMultipartFormData!) -> Void in
            formData.appendPart(withFileData: profileImage as Data, name: "Photo", fileName: "photo.jpg", mimeType: "image/jpeg")
        },success: { (operation, response) -> Void in
            if let responseObject = response as? [String:AnyObject]
            {
                success?(responseObject as AnyObject?)
            }
            else
            {
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil),
                         "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            var failureErrorCode:String = ""
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    func updateUserDetails(userName: String, accessToken: String, email: String, location: String, mobNo: String,fullName: String, timeZone: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?){
        
        var paramet = NSMutableDictionary()
        if(fullName == ""){
            paramet  = ["email":email,"mobileNumber":mobNo,"timeZone": timeZone]
        }
        else{
            paramet  = ["email":email,"mobileNumber":mobNo,"fullName":fullName,"timeZone": timeZone]
        }
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.getProfileImageAPIUrl(userName: userName, accessToken: accessToken), parameters: paramet, success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error code from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    //Method to get user details, success and failure block
    func getUploadProfileImageURL(userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.getProfileUploadAPIUrl(userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            if let responseObject = response as? [String:AnyObject]
            {
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            var failureErrorCode:String = ""
            //get the error code from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    
    //Method to get profile updation notification details, success and failure block
    func getUpdationProfileImage(userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getProfileUpdationNotificationAPIUrl(userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            if let responseObject = response as? [String:AnyObject]
            {
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            var failureErrorCode:String = ""
            //get the error code from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
}
