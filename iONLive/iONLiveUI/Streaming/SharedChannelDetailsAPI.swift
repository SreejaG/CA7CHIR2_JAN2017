
import UIKit

class SharedChannelDetailsAPI: NSObject {
    class var sharedInstance: SharedChannelDetailsAPI
    {
        struct Singleton
        {
            static let instance = SharedChannelDetailsAPI()
            private init() {}
        }
        return Singleton.instance
    }
    var operationQueue = OperationQueue()
    var imageDataSource: [[String:Any]] = [[String:Any]]()
    var selectedSharedChannelMediaSource: [[String:Any]] = [[String:Any]]()
    var userName:String!
    var channelName :String = String()
    func getSubscribedChannelData(channelId : String , selectedChannelName : String ,selectedChannelUserName :String , sharedCount : String)
    {
        if(channelName != "")
        {
            if channelName == selectedChannelName
            {
                selectedSharedChannelMediaSource.removeAll()
                imageDataSource.removeAll()
                let defaults = UserDefaults.standard
                let userId = defaults.value(forKey: userLoginIdKey) as! String
                let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
                channelName = selectedChannelName
                userName = selectedChannelUserName
                ImageUpload.sharedInstance.getChannelMediaDetails(channelId: channelId , userName: userId, accessToken: accessToken, limit: "27", offset: "0", success: { (response) -> () in
                    self.authenticationSuccessHandler(response: response)
                }) { (error, message) -> () in
                    self.authenticationFailureHandler(error: error, code: message)
                }
            }
            else{
                selectedSharedChannelMediaSource.removeAll()
                imageDataSource.removeAll()
                let defaults = UserDefaults.standard
                let userId = defaults.value(forKey: userLoginIdKey) as! String
                let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
                channelName = selectedChannelName
                userName = selectedChannelUserName
                ImageUpload.sharedInstance.getChannelMediaDetails(channelId: channelId , userName: userId, accessToken: accessToken, limit: "27", offset: "0", success: { (response) -> () in
                    self.authenticationSuccessHandler(response: response)
                }) { (error, message) -> () in
                    self.authenticationFailureHandler(error: error, code: message)
                }
            }
        }
        else{
            selectedSharedChannelMediaSource.removeAll()
            imageDataSource.removeAll()
            let defaults = UserDefaults.standard
            
            let userId = defaults.value(forKey: userLoginIdKey) as! String
            let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
            channelName = selectedChannelName
            userName = selectedChannelUserName
            ImageUpload.sharedInstance.getChannelMediaDetails(channelId: channelId , userName: userId, accessToken: accessToken, limit: "27", offset: "0", success: { (response) -> () in
                self.authenticationSuccessHandler(response: response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error: error, code: message)
            }
        }
    }
    
    func infiniteScroll(channelId : String , selectedChannelName : String ,selectedChannelUserName :String , channelMediaId : String)
    {
        let defaults = UserDefaults.standard
        let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        ImageUpload.sharedInstance.getInfinteScrollChannelMediaDetails(channelId: channelId, userName: selectedChannelUserName, accessToken: accessToken, channelMediaId: channelMediaId, success: { (response) in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) in
            self.authenticationFailureHandler(error: error, code: message)
            
        }
    }
    
    func getMedia(channelId : String , selectedChannelName : String ,selectedChannelUserName :String , sharedCount : String)
    {
        selectedSharedChannelMediaSource.removeAll()
        imageDataSource.removeAll()
        let defaults = UserDefaults.standard
        let userId = defaults.value(forKey: userLoginIdKey) as! String
        let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        channelName = selectedChannelName
        userName = selectedChannelUserName
        ImageUpload.sharedInstance.getChannelMediaDetails(channelId: channelId , userName: userId, accessToken: accessToken, limit: "27", offset: "0", success: { (response) -> () in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
        }
    }
    
    func pullToRefresh (channelId : String ,selectedChannelUserName :String , channelMediaId : String)
    {
        let accessToken = UserDefaults .standard.value(forKey: userAccessTockenKey) as! String
        ImageUpload.sharedInstance.getPullToRefreshChannelMediaDetails(channelId: channelId, userName: selectedChannelUserName, accessToken: accessToken, channelMediaId: channelMediaId, success: { (response) in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) in
            self.authenticationFailureHandler(error: error, code: message)
        }
    }
    
    func authenticationSuccessHandler(response:Any?)
    {
        imageDataSource.removeAll()
        if let json = response as? [String: Any]
        {
            let responseArr = json["MediaDetail"] as! [AnyObject]
//            print("response array in stream ======> \(responseArr)")
            for index in 0 ..< responseArr.count
            {
                let mediaId = String(responseArr[index]["media_detail_id"] as! Int)
                let mediaType =  responseArr[index]["gcs_object_type"] as! String
                let infiniteScrollId  = String(responseArr[index]["channel_media_detail_id"] as! Int)
                let notificationType : String = " likes"
                let time = responseArr[index]["created_time_stamp"] as! String
                let actualUrl =  UrlManager.sharedInstance.getFullImageForStreamMedia(mediaId: mediaId)
                let mediaUrl =  UrlManager.sharedInstance.getMediaURL(mediaId: mediaId)
                var vDuration = String()
                if(mediaType == "video"){
                    let videoDurationStr = responseArr[index]["video_duration"] as! String
                    vDuration = FileManagerViewController.sharedInstance.getVideoDurationInProperFormat(duration: videoDurationStr)
                }
                else{
                    vDuration = ""
                }
                imageDataSource.append([stream_mediaIdKey:mediaId, mediaUrlKey:mediaUrl, stream_mediaTypeKey:mediaType,actualImageKey:actualUrl,infiniteScrollIdKey: infiniteScrollId,notificationKey:notificationType,"createdTime":time,videoDurationKey:vDuration])
            }
            
            let responseArrLive = json["LiveDetail"] as! [AnyObject]
            
            for liveIndex in 0  ..< responseArrLive.count
            {
                let streamTocken = responseArrLive[liveIndex]["wowza_stream_token"] as! String
                let mediaId = String(responseArrLive[liveIndex]["live_stream_detail_id"] as! Int)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
                let currentDate = dateFormatter.string(from: NSDate() as Date)
                let notificationType : String = ""
                let mediaUrl =  UrlManager.sharedInstance.getLiveThumbUrlApi(liveStreamId: mediaId)
                var vDuration = String()
                vDuration = ""
                if(mediaUrl != ""){
                    let url: NSURL = convertStringtoURL(url: mediaUrl)
                    downloadMedia(downloadURL: url, key: "ThumbImage", completion: { (result) -> Void in
                        if(self.selectedSharedChannelMediaSource.count > 0)
                        {
                            if (self.selectedSharedChannelMediaSource[0][stream_mediaTypeKey] as! String != "live")
                            {
                                self.selectedSharedChannelMediaSource.insert([stream_mediaIdKey:mediaId, mediaUrlKey:mediaUrl, stream_thumbImageKey:result ,stream_streamTockenKey:streamTocken,actualImageKey:mediaUrl,notificationKey:notificationType,stream_mediaTypeKey:"live",infiniteScrollIdKey: "", userIdKey:self.userName, stream_channelNameKey:self.channelName,"createdTime":currentDate,videoDurationKey:vDuration], at: 0)
                            }
                        }
                        else{
                            self.selectedSharedChannelMediaSource.insert([stream_mediaIdKey:mediaId, mediaUrlKey:mediaUrl,stream_thumbImageKey:result ,stream_streamTockenKey:streamTocken,actualImageKey:mediaUrl,notificationKey:notificationType,stream_mediaTypeKey:"live",infiniteScrollIdKey: "", userIdKey:self.userName, stream_channelNameKey:self.channelName,"createdTime":currentDate,videoDurationKey:vDuration], at: 0)
                        }
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SharedChannelMediaDetail"), object:"success")
                    })
                }
            }
            
            if(imageDataSource.count > 0){
                if(self.selectedSharedChannelMediaSource.count > 0)
                {
                }
                
                let operation2 : BlockOperation = BlockOperation (block: {
                    self.downloadMediaFromGCS()
                })
                self.operationQueue.addOperation(operation2)
            }
            else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SharedChannelMediaDetail"), object:"failure")
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        if !RequestManager.sharedInstance.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SharedChannelMediaDetail"), object:"failure")
        }
        else if code.isEmpty == false {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                if let tokenValid = UserDefaults.standard.value(forKey: "tokenValid")
                {
                    if tokenValid as! String == "true"
                    {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SharedChannelMediaDetail"), object:code)
                    }
                }
            }
            else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SharedChannelMediaDetail"), object:"failure")
            }
        }
        else{
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SharedChannelMediaDetail"), object:"failure")
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (_ result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        
        // Data object to fetch weather data
        do {
            let data = try NSData(contentsOf: downloadURL as URL,options: NSData.ReadingOptions())
            if let imageData = data as NSData? {
                if let mediaImage1 = UIImage(data: imageData as Data)
                {
                    mediaImage = mediaImage1
                    completion(mediaImage)
                }
                else{
                    let failedString = String(data: imageData as Data, encoding: String.Encoding.utf8)
                    let fullString = failedString?.components(separatedBy: ",")
                    let errorString = fullString?[1].components(separatedBy: ":")
                    var orgString = errorString?[1]
                    orgString = orgString?.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
                    if((orgString == "USER004") || (orgString == "USER005") || (orgString == "USER006")){
                        if let tokenValid = UserDefaults.standard.value(forKey: "tokenValid")
                        {
                            if tokenValid as! String == "true"
                            {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SharedChannelMediaDetail"), object:orgString)
                            }
                        }
                    }
                }
            }
            else
            {
                completion(UIImage(named: "thumb12")!)
            }
            
        } catch {
            completion(UIImage(named: "thumb12")!)
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url as NSString
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    
    func downloadMediaFromGCS(){
        for i in 0 ..< imageDataSource.count
        {
            var imageForMedia : UIImage = UIImage()
            if(imageDataSource.count > 0 && imageDataSource.count > i)
            {
                let mediaidStrFile = imageDataSource[i][stream_mediaIdKey] as! String
                let mediaIdForFilePath = mediaidStrFile + "thumb"
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
                let savingPath = parentPath! + "/" + mediaIdForFilePath
                let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(mediaPath: savingPath)
                if fileExistFlag == true{
                    let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(mediaPath: savingPath)
                    imageForMedia = mediaImageFromFile!
                }
                else{
                    let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
                    if(mediaUrl != ""){
                        let url: NSURL = convertStringtoURL(url: mediaUrl)
                        downloadMedia(downloadURL: url, key: "ThumbImage", completion: { (result) -> Void in
                            if(result != UIImage()){
                                let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                                if(imageDataFromresult != nil){
                                    let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                                    let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                                    let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                                    if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                                    }
                                    else{
                                        _ = FileManagerViewController.sharedInstance.saveImageToFilePath(mediaName: mediaIdForFilePath, mediaImage: result)
                                    }
                                    imageForMedia = result
                                }
                                else{
                                    imageForMedia = UIImage(named: "thumb12")!
                                }
                            }
                            else{
                                imageForMedia = UIImage(named: "thumb12")!
                            }
                        })
                    }
                }
            }
            
            if(imageDataSource.count > 0 )
            {
                if(i < imageDataSource.count)
                {
                    self.selectedSharedChannelMediaSource.append([stream_mediaIdKey:self.imageDataSource[i][stream_mediaIdKey]!, mediaUrlKey:imageForMedia,stream_mediaTypeKey:self.imageDataSource[i][stream_mediaTypeKey]!,stream_thumbImageKey:imageForMedia,actualImageKey:self.imageDataSource[i][actualImageKey]!,infiniteScrollIdKey: self.imageDataSource[i][infiniteScrollIdKey]!,stream_streamTockenKey:"",notificationKey:self.imageDataSource[i][notificationKey]!,"createdTime":self.imageDataSource[i]["createdTime"] as! String,                videoDurationKey:self.imageDataSource[i][videoDurationKey] as! String])
                }
            }
        }
        
        if(imageDataSource.count > 0 )
        {
            if(selectedSharedChannelMediaSource.count > 0)
            {
                let type = selectedSharedChannelMediaSource[0][stream_mediaTypeKey] as! String
                if type == "live"
                {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
                    let currentDate = dateFormatter.string(from: NSDate() as Date)
                    selectedSharedChannelMediaSource[0]["createdTime"] = currentDate
                }
            }
            if(selectedSharedChannelMediaSource.count > 0){
                selectedSharedChannelMediaSource.sort(by: { p1, p2 in
                    let time1 = p1["createdTime"] as! String
                    let time2 = p2["createdTime"] as! String
                    return time1 > time2
                })
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SharedChannelMediaDetail"), object:"success")
    }
}
