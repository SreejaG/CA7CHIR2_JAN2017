
import UIKit

class ChannelManager: NSObject {
    
    class var sharedInstance: ChannelManager {
        struct Singleton {
            static let instance = ChannelManager()
        }
        return Singleton.instance
    }
    
    //Method to get Channel details, success and failure block
    func getChannelDetails(userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getAllChannelsAPIUrl(userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    //Method to get Channel details, success and failure block
    func getChannelContactDetails(channelId: String, userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getAllContactsChannelAPIUrl(channelId: channelId, userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            //Get and parse the response
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
    
    func getChannelNonContactDetails(channelId: String, userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getNonContactsChannelAPIUrl(channelId: channelId, userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func addChannelDetails(userName: String, accessToken: String, channelName: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.channelAPIUrl(), parameters: ["userName":userName, "access_token":accessToken, "channelName":channelName], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func updateChannelName(userName: String, accessToken: String, channelName: String, channelId: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.updateChannelsAPIUrl(chanelId: channelId, userName: userName, accessToken: accessToken), parameters: ["channelName":channelName], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getMediaInteractionDetails(userName: String, accessToken: String,limit:String,offset:String,success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getMediaInteractionNotifications(userName: userName, accessToken: accessToken, limit: limit, offset: offset), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func postMediaInteractionDetails(userName: String, accessToken: String, notifType: String, mediaDetailId: Int, channelId: Int, type: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.MediaInteractionUrl(), parameters: ["userName":userName, "access_token":accessToken, "notificationType":notifType, type:mediaDetailId,"channelId":channelId], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getChannelShared(userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getChannelSharedDetails(userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getDataByNotificationId(userName: String, accessToken: String, notificationId : String,success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getNotificationIdData(), parameters:  ["userName":userName, "access_token": accessToken,"notificationId" :notificationId ], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    //Method to delete Channel details, success and failure block
    func deleteChannelDetails(userName: String, accessToken: String, deleteChannelId:String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let ChanelIdInt : Int = Int(deleteChannelId)!
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.getAllChannelsAPIUrl(userName: userName, accessToken: accessToken), parameters: ["channelId": ChanelIdInt], success: { (operation, response) -> Void in
            
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
            var failureErrorDesc:String = ""
            //get the error message from API response if any
            if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorDesc = errorMessage
            }
            failure?(error as NSError?, failureErrorDesc)
        })
    }
    
    func inviteContactList(userName: String, accessToken: String, channelId: String, adduser: NSMutableArray, deleteUser: NSMutableArray, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.inviteContactsChannelAPIUrl(channelId: channelId), parameters: ["userName":userName, "access_token":accessToken, "addUser":adduser, "deleteUser":deleteUser], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func AddContactToChannel(userName: String, accessToken: String, channelId: String, adduser: NSMutableArray, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let ChanelIdInt : Int = Int(channelId)!
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.channelAPIUrl(), parameters: ["userName":userName, "access_token":accessToken, "channelId":ChanelIdInt, "addUser":adduser], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func enableDisableChannels(userName: String, accessToken: String, addChannel: NSMutableArray, deleteChannel: NSMutableArray, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.getAllChannelsAPIUrl(userName: userName, accessToken: accessToken), parameters: ["enableChannelId":addChannel, "disableChannelId":deleteChannel], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    
    //Method to delete Channel details, success and failure block
    func deleteContactDetails(userName: String, accessToken: String, channelId:String, contactName: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.getDeleteContactChannelAPIUrl(channelId: channelId, userName: userName, accessToken: accessToken, contactName: contactName), parameters: nil, success: { (operation, response) -> Void in
            
            
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
            var failureErrorDesc:String = ""
            //get the error message from API response if any
            if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorDesc = errorMessage
            }
            failure?(error as NSError?, failureErrorDesc)
        })
    }
    
    func getLoggedInDetails(userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getLoggedInDetails(userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getMediaLikeCountDetails(userName: String, accessToken: String, mediaId: String, mediaType: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _
        code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getMedialikeCountAPI(userName: userName, accessToken: accessToken), parameters: ["id":mediaId, "type": mediaType], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getUpdatedMediaDetails(userName: String, accessToken: String, timestamp: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getUpdatedMediaDetails(userName: userName, accessToken: accessToken,timeStamp: timestamp), parameters:nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getOffsetMediaDetails(userName: String, accessToken: String, timestamp: String,success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getOffsetDetails(userName: userName, accessToken: accessToken), parameters:["channelMediaId":timestamp, "limit": "20"], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getChannelSharedPullToRefresh(userName: String, accessToken: String, channelSubId : String,success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getChannelSharedDetailsPullToRefresh(userName: userName, accessToken: accessToken, channelSubId: channelSubId), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
