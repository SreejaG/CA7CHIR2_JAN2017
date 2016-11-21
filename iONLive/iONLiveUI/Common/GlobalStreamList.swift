
import UIKit

class GlobalStreamList: NSObject {
    var imageDataSource: [[String:Any]] = [[String:Any]]()
    var GlobalStreamDataSource: [[String:Any]] = [[String:Any]]()
    var operationQueue = OperationQueue()
    var operation2 : BlockOperation = BlockOperation()
    
    class var sharedInstance: GlobalStreamList
    {
        struct Singleton
        {
            static let instance = GlobalStreamList()
            private init() {
            }
        }
        return Singleton.instance
    }
    
    func cancelOperationQueue()
    {
        operationQueue.cancelAllOperations()
        operation2.cancel()
    }
    
    func initialiseCloudData( startOffset : Int ,endValueLimit :Int){
        imageDataSource.removeAll()
        GlobalStreamDataSource.removeAll()
        let defaults = UserDefaults.standard
        let userId = defaults.value(forKey: userLoginIdKey) as! String
        let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        let startValue = "\(startOffset)"
        let endValueCount = String(endValueLimit)
        ImageUpload.sharedInstance.getSubscribedChannelMediaDetails(userName: userId, accessToken: accessToken, limit: endValueCount, offset: startValue, success: { (response) in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) in
            self.authenticationFailureHandlerStream(error: error, code: message)
        }
    }
    
    func authenticationSuccessHandler(response:Any?)
    {
        if let json = response as? [String: Any]
        {
            let responseArr = json["objectJson"] as! [AnyObject]
            if(responseArr.count == 0)
            {
                UserDefaults.standard.setValue("Empty", forKey: "EmptyMedia")
            }
            for index in 0 ..< responseArr.count
            {
                UserDefaults.standard.setValue("NotEmpty", forKey: "EmptyMedia")
                
                let mediaId = String(responseArr[index]["media_detail_id"] as! Int)
                let mediaType =  responseArr[index]["gcs_object_type"] as! String
                let userid = responseArr[index][userIdKey] as! String
                let time = responseArr[index]["last_updated_time_stamp"] as! String
                let channelName =  responseArr[index]["channel_name"] as! String
                let channelIdSelected =  String(responseArr[index]["channel_detail_id"] as! Int)
                let notificationType : String = "likes"
                var vDuration = String()
                
                if(mediaType == "video"){
                    let videoDurationStr = responseArr[index]["video_duration"] as! String
                    vDuration = FileManagerViewController.sharedInstance.getVideoDurationInProperFormat(duration: videoDurationStr)
                }
                else{
                    vDuration = ""
                }
                let actualUrlBeforeNullChk =  UrlManager.sharedInstance.getFullImageForStreamMedia(mediaId: mediaId)
                let mediaUrlBeforeNullChk =  UrlManager.sharedInstance.getMediaURL(mediaId: mediaId)
                let pulltorefreshId = String(responseArr[index][pullTorefreshKey] as! Int)
                imageDataSource.append([stream_mediaIdKey:mediaId, mediaUrlKey:mediaUrlBeforeNullChk, stream_mediaTypeKey:mediaType,actualImageKey:actualUrlBeforeNullChk,notificationKey:notificationType,userIdKey:userid,timestamp:time,stream_channelNameKey:channelName, pullTorefreshKey : pulltorefreshId, channelIdkey:channelIdSelected,"createdTime":time,videoDurationKey:vDuration])
            }
            if(imageDataSource.count > 0){
                operation2 = BlockOperation (block: {
                    self.downloadMediaFromGCS()
                })
                self.operationQueue.addOperation(operation2)
            }
            else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stream"), object:"failure")
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    
    func authenticationFailureHandlerStream(error: NSError?, code: String)
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stream"), object:"failure")
        if !RequestManager.sharedInstance.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                
            }
            else{
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url as NSString
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (_ result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        do {
            let data = try NSData(contentsOf: downloadURL as URL,options: NSData.ReadingOptions())
            if let imageData = data as NSData? {
                if let mediaImage1 = UIImage(data: imageData as Data)
                {
                    mediaImage = mediaImage1
                }
                else{
                    
                    mediaImage = UIImage(named: "thumb12")!
                }
                completion(mediaImage)
            }
            else
            {
                completion(UIImage(named: "thumb12")!)
            }
            
        } catch {
            completion(UIImage(named: "thumb12")!)
        }
    }
    
    func downloadMediaFromGCS(){
        for i in 0 ..< imageDataSource.count
        {
            if imageDataSource.count > 0 && imageDataSource.count > i
            {
                if imageDataSource[i][stream_mediaIdKey] != nil
                {
                    var imageForMedia : UIImage = UIImage()
                    let mediaIdForFilePathStr = self.imageDataSource[i][stream_mediaIdKey] as! String
                    let mediaIdForFilePath = mediaIdForFilePathStr + "thumb"
                    let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
                    let savingPath = parentPath! + "/" + mediaIdForFilePath
                    let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(mediaPath: savingPath)
                    if fileExistFlag == true{
                        let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(mediaPath: savingPath)
                        imageForMedia = mediaImageFromFile!
                        if(self.imageDataSource.count > 0)
                        {
                            self.GlobalStreamDataSource.append([stream_mediaIdKey:self.imageDataSource[i][stream_mediaIdKey]!, mediaUrlKey:imageForMedia,stream_thumbImageKey:imageForMedia ,stream_streamTockenKey:"",actualImageKey:self.imageDataSource[i][actualImageKey]!,userIdKey:self.imageDataSource[i][userIdKey]!,notificationKey:self.imageDataSource[i][notificationKey]!,timestamp :self.imageDataSource[i][timestamp]!,stream_mediaTypeKey:self.imageDataSource[i][stream_mediaTypeKey]!,stream_channelNameKey:self.imageDataSource[i][stream_channelNameKey]!,channelIdkey:self.imageDataSource[i][channelIdkey]!,pullTorefreshKey:self.imageDataSource[i][pullTorefreshKey] as! String,"createdTime":self.imageDataSource[i]["createdTime"] as! String,videoDurationKey:self.imageDataSource[i][videoDurationKey] as! String])
                        }
                    }
                    else{
                        if(imageDataSource.count > 0)
                        {
                            let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
                            if(mediaUrl != ""){
                                let url: NSURL = convertStringtoURL(url: mediaUrl)
                                downloadMedia(downloadURL: url, key: "ThumbImage", completion: { (result) -> Void in
                                    if(result != UIImage()){
                                        let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                                        if imageDataFromresult != nil
                                        {
                                            let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                                            let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                                            let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                                            if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                                            }
                                            else{
                                                imageForMedia = result
                                                if(self.imageDataSource.count > 0)
                                                {
                                                    self.GlobalStreamDataSource.append([stream_mediaIdKey:self.imageDataSource[i][stream_mediaIdKey]!, mediaUrlKey:imageForMedia, stream_thumbImageKey:imageForMedia ,stream_streamTockenKey:"",actualImageKey:self.imageDataSource[i][actualImageKey]!,userIdKey:self.imageDataSource[i][userIdKey]!,notificationKey:self.imageDataSource[i][notificationKey]!,timestamp :self.imageDataSource[i][timestamp]!,stream_mediaTypeKey:self.imageDataSource[i][stream_mediaTypeKey]!,stream_channelNameKey:self.imageDataSource[i][stream_channelNameKey]!,channelIdkey:self.imageDataSource[i][channelIdkey]!,pullTorefreshKey:self.imageDataSource[i][pullTorefreshKey] as! String,"createdTime":self.imageDataSource[i]["createdTime"] as! String,videoDurationKey:self.imageDataSource[i][videoDurationKey] as! String])
                                                }
                                                
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
                }
            }
        }
        if(GlobalStreamDataSource.count > 0){
            GlobalStreamDataSource.sort(by: { p1, p2 in
                let time1 = p1[timestamp] as! String
                let time2 = p2[timestamp] as! String
                return time1 > time2
            })
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stream"), object:"success")
    }
    
    func getPullToRefreshData()
    {
        imageDataSource.removeAll()
        let userId = UserDefaults.standard.value(forKey: userLoginIdKey) as! String
        let accessToken = UserDefaults.standard.value(forKey: userAccessTockenKey) as! String
        let sortList : Array = GlobalStreamList.sharedInstance.GlobalStreamDataSource
        var subIdArray : [Int] = [Int]()
        for i in 0  ..< sortList.count
        {
            let subId = sortList[i][pullTorefreshKey] as! String
            subIdArray.append(Int(subId)!)
        }
        if(subIdArray.count > 0)
        {
            let subid = subIdArray.max()!
            ChannelManager.sharedInstance.getUpdatedMediaDetails(userName: userId, accessToken:accessToken,timestamp : "\(subid)",success: { (response) in
                self.authenticationSuccessHandler(response: response)
                
            }) { (error, message) in
                self.authenticationFailureHandlerStream(error: error, code: message)
            }
        }
    }
    
    func getMediaByOffset(subId : String)
    {
        let userId = UserDefaults.standard.value(forKey: userLoginIdKey) as! String
        let accessToken = UserDefaults.standard.value(forKey: userAccessTockenKey) as! String
        GlobalStreamList.sharedInstance.imageDataSource.removeAll()
        ChannelManager.sharedInstance.getOffsetMediaDetails(userName: userId, accessToken:accessToken,timestamp : subId ,success: { (response) in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) in
            self.authenticationFailureHandlerStream(error: error, code: message)
        }
    }
}
