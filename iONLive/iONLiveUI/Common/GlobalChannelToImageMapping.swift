
import UIKit

class GlobalChannelToImageMapping: NSObject {
    
    var GlobalChannelImageDict : [String : [[String : Any]]] =  [String : [[String : Any]]]()
    var imageDataSource: [[String:Any]] = [[String:Any]]()
    
    var channelImageDataSource: [[String:Any]] = [[String:Any]]()
    var localDataSource: [[String:Any]] = [[String:Any]]()
    var dummy: [[String:Any]] = [[String:Any]]()
    var mediaUploadFailedDict: [[String:Any]] = [[String:Any]]()
    var mediaMappingFailedDict: [String] = [String]()
    
    var channelId : String!
    var channelDetailId : String = String()
    
    var dataSourceCount : Int = 0
    var filteredcount : Int = Int()
    
    let defaults = UserDefaults.standard
    
    var userId : String = String()
    var accessToken : String = String()
    
    class var sharedInstance: GlobalChannelToImageMapping
    {
        struct Singleton
        {
            static let instance = GlobalChannelToImageMapping()
            private init() {}
        }
        return Singleton.instance
    }
    
    func globalData(source :[[String:Any]])
    {
        let success = Notification.Name("success")
        NotificationCenter.default.addObserver(self, selector:#selector(GlobalChannelToImageMapping.display(notif:)), name: success, object: nil)
        dummy.removeAll()
        GlobalChannelImageDict.removeAll()
        dummy = source
        dataSourceCount = 0
        getMediaByChannelId()
    }
    
    func display(notif: NSNotification)
    {
        if (dataSourceCount < dummy.count - 1)
        {
            dataSourceCount  = dataSourceCount + 1
            getMediaByChannelId()
        }
        else if dataSourceCount == dummy.count - 1
        {
            let codeString = "Success"
            NotificationCenter.default.removeObserver(self, name: Notification.Name("success"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stopInitialising"), object:codeString)
        }
    }
    
    func getMediaByChannelId()
    {
        let totalMediaCount : Int = Int(dummy[dataSourceCount][totalMediaKey]  as! String)!
        let channelId : String =  dummy[dataSourceCount][channelIdKey] as! String
        self.channelDetailId = channelId
        self.initialise(totalMediaCount: totalMediaCount, channelid: channelId)
    }
    
    func initialise(totalMediaCount : Int, channelid : String){
        userId = defaults.value(forKey: userLoginIdKey) as! String
        accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        let startValue = "0"
        let endValue = String(totalMediaCount)
        channelDetailId = channelid
        
        if totalMediaCount <= 0
        {
            imageDataSource.removeAll()
            GlobalChannelImageDict.updateValue(imageDataSource, forKey: channelDetailId)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "success"), object:channelDetailId)
        }
        else{
            ImageUpload.sharedInstance.getOwnerChannelMediaDetails(channelId: channelid , userName: userId, accessToken: accessToken, limit: endValue, offset: startValue, success: { (response) -> () in
                self.authenticationSuccessHandler(response: response,id: channelid)
            }) { (error, message) -> () in
                return
            }
        }
    }
    
    func authenticationSuccessHandler(response:Any?, id:String)
    {
        if let json = response as? [String: Any]
        {
            imageDataSource.removeAll()
            let responseArr = json["MediaDetail"] as! [AnyObject]
            for index in 0 ..< responseArr.count
            {
                let mediaId = String(responseArr[index][mediaIdKey] as! Int)
                let channelMediaDetailId = String(responseArr[index][channelMediaIdKey] as! Int)
                let mediaType =  responseArr[index][mediaTypeKey] as! String
                var vDuration = String()
                if(mediaType == "video"){
                    let videoDurationStr = responseArr[index][videoDurationKey] as! String
                    vDuration = FileManagerViewController.sharedInstance.getVideoDurationInProperFormat(duration: videoDurationStr)
                }
                else{
                    vDuration = ""
                }
                let notificationType : String = "likes"
                let time = responseArr[index][mediaCreatedTimeKey] as! String
                imageDataSource.append([mediaIdKey:mediaId,channelMediaIdKey:channelMediaDetailId,mediaTypeKey:mediaType, notifTypeKey:notificationType, mediaCreatedTimeKey:time, progressKey:Float(3.0),videoDurationKey:vDuration])
            }
            if(imageDataSource.count > 0){
                imageDataSource.sort(by: { p1, p2 in
                    let time1 = Int(p1[mediaIdKey] as! String)
                    let time2 = Int(p2[mediaIdKey] as! String)
                    return time1! > time2!
                })
                GlobalChannelImageDict.updateValue(imageDataSource, forKey: channelDetailId)
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "success"), object:channelDetailId)
            }
        }
    }
    
    func downloadMediaFromGCS(chanelId: String, start: Int, end:Int, operationObj: BlockOperation){
        localDataSource.removeAll()
        for i in start ..< end
        {
            localDataSource.append(GlobalChannelImageDict[chanelId]![i])
        }
        if localDataSource.count > 0
        {
            for k in 0 ..< localDataSource.count
            {
                if operationObj.isCancelled == true{
                    return
                }
                if(k < localDataSource.count){
                    let requestManager = RequestManager.sharedInstance
                    if !requestManager.validConnection() {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "removeActivityIndicatorMyChannel"), object:nil)
                        return
                    }
                    var imageForMedia : UIImage = UIImage()
                    if let mediaIdChk = localDataSource[k][mediaIdKey]
                    {
                        let mediaId = String(describing: mediaIdChk)
                        let mediaIdForFilePath = "\(mediaId)thumb"
                        let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
                        let savingPath = parentPath! + "/" + mediaIdForFilePath
                        let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(mediaPath: savingPath)
                        if fileExistFlag == true{
                            let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(mediaPath: savingPath)
                            imageForMedia = mediaImageFromFile!
                        }
                        else{
                            let mediaUrl = UrlManager.sharedInstance.getThumbImageForMedia(mediaId: mediaId, userName: userId, accessToken: accessToken)
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
                            else{
                                imageForMedia = UIImage(named: "thumb12")!
                            }
                        }
                    }
                    else{
                        imageForMedia = UIImage(named: "thumb12")!
                    }
                    if localDataSource.count > 0
                    {
                        if k < localDataSource.count
                        {
                            localDataSource[k][tImageKey] = imageForMedia
                        }
                    }
                }
            }
            
            for j in 0 ..< GlobalChannelImageDict[chanelId]!.count
            {
                if j < GlobalChannelImageDict[chanelId]!.count
                {
                    let mediaIdChk = GlobalChannelImageDict[chanelId]![j][mediaIdKey] as! String
                    for element in localDataSource
                    {
                        let mediaIdFromLocal = element[mediaIdKey] as! String
                        if mediaIdChk == mediaIdFromLocal
                        {
                            if element[tImageKey] != nil
                            {
                                GlobalChannelImageDict[chanelId]![j][tImageKey] = element[tImageKey] as! UIImage
                            }
                        }
                    }
                }
            }
            localDataSource.removeAll()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "removeActivityIndicatorMyChannel"), object:nil)
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
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tokenExpired"), object:orgString)
                            }
                        }
                    }
                    else{
                        completion(UIImage(named: "thumb12")!)
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
    
    func nullToNil(value : Any?) -> Any? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    //add medias to channels when user capture an image
    func mapNewMediasToAllChannels(dataSourceRow: [String:Any])
    {
        for j in 0 ..< GlobalDataChannelList.sharedInstance.globalChannelDataSource.count
        {
            if j < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count
            {
                let chanId = GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][channelIdKey] as! String
                let sharedInd = Bool(GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][sharedOriginalKey] as! NSNumber)
                let chanName = GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][channelNameKey] as! String
                
                if(sharedInd == true || chanName == "Archive")
                {
                    if GlobalChannelImageDict[chanId] != nil
                    {
                        GlobalChannelImageDict[chanId]!.append(dataSourceRow)
                        GlobalChannelImageDict[chanId]!.sort(by: { p1, p2 in
                            let time1 = Int(p1[mediaIdKey] as! String)
                            let time2 = Int(p2[mediaIdKey] as! String)
                            return time1! > time2!
                        })
                        let mediaIdForFilePath = GlobalChannelImageDict[chanId]![0][mediaIdKey] as! String
                        GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][totalMediaKey] = "\(GlobalChannelImageDict[chanId]!.count)"
                        GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][latestMediaIdKey] = mediaIdForFilePath
                        GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][tImageKey] = downloadLatestMedia(mediaId: mediaIdForFilePath)
                        
                        if chanName == "Archive"
                        {
                            var archCount : Int = Int()
                            if let archivetotal =  UserDefaults.standard.value(forKey: ArchiveCount)
                            {
                                archCount = archivetotal as! Int
                            }
                            else{
                                archCount = 0
                            }
                            archCount = archCount + 1
                            UserDefaults.standard.set( archCount, forKey: ArchiveCount)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "setFullscreenImage"), object:nil)
                            
                        }
                    }
                }
            }
        }
        GlobalDataChannelList.sharedInstance.globalChannelDataSource.sort(by: { p1, p2 in
            let time1 = p1[ChannelCreatedTimeKey] as! String
            let time2 = p2[ChannelCreatedTimeKey] as! String
            return time1 > time2
        })
        
    }
    
    // Add media from one channel to other channels
    func addMediaToChannel(channelSelectedDict: [[String:Any]],  mediaDetailOfSelectedChannel : [[String:Any]])
    {
        for i in 0 ..< channelSelectedDict.count
        {
            if i < channelSelectedDict.count
            {
                let selectedChanelId = channelSelectedDict[i][channelIdKey] as! String
                var chkFlag = false
                var dataRowOfSelectedMediaArray : [String: Any] = [String:Any]()
                
                for element in mediaDetailOfSelectedChannel
                {
                    dataRowOfSelectedMediaArray = element
                    let mediaIdChk = element[mediaIdKey] as! String
                    for elementGlob in GlobalChannelImageDict[selectedChanelId]!
                    {
                        let mediaId = elementGlob[mediaIdKey] as! String
                        if mediaIdChk == mediaId
                        {
                            chkFlag = true
                            break
                        }
                        else{
                            chkFlag = false
                        }
                    }
                    if chkFlag == false
                    {
                        GlobalChannelImageDict[selectedChanelId]!.append(dataRowOfSelectedMediaArray)
                    }
                }
                
                thumbExist(chanel: selectedChanelId)
                GlobalChannelImageDict[selectedChanelId]!.sort(by: { p1, p2 in
                    let time1 = Int(p1[mediaIdKey] as! String)
                    let time2 = Int(p2[mediaIdKey] as! String)
                    return time1! > time2!
                })
                
                for k in 0 ..< GlobalDataChannelList.sharedInstance.globalChannelDataSource.count
                {
                    if k < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count
                    {
                        let chanIdChk = GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][channelIdKey] as! String
                        if chanIdChk == selectedChanelId
                        {
                            let mediaIdForFilePath = GlobalChannelImageDict[selectedChanelId]![0][mediaIdKey] as! String
                            GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][totalMediaKey] = "\(GlobalChannelImageDict[selectedChanelId]!.count)"
                            GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][latestMediaIdKey] = mediaIdForFilePath
                            GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][tImageKey] = downloadLatestMedia(mediaId: mediaIdForFilePath)
                        }
                    }
                }
            }
        }
        GlobalDataChannelList.sharedInstance.globalChannelDataSource.sort(by: { p1, p2 in
            let time1 = p1[ChannelCreatedTimeKey] as! String
            let time2 = p2[ChannelCreatedTimeKey] as! String
            return time1 > time2
        })
        
    }
    
    func thumbExist(chanel: String)  {
        for k in 0 ..< GlobalChannelImageDict[chanel]!.count
        {
            if k < GlobalChannelImageDict[chanel]!.count
            {
                if GlobalChannelImageDict[chanel]![k][tImageKey] != nil
                {
                    
                }
                else{
                    let mediaId = GlobalChannelImageDict[chanel]![k][mediaIdKey] as! String
                    let imagemedia = downloadLatestMedia(mediaId: mediaId)
                    GlobalChannelImageDict[chanel]![k][tImageKey] = imagemedia
                }
            }
        }
    }
    
    func downloadLatestMedia(mediaId: String) -> UIImage
    {
        var imageForMedia : UIImage = UIImage()
        let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
        let mediaIdForFilePath = mediaId + "thumb"
        let savingPath = parentPath! + "/" + mediaIdForFilePath
        let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(mediaPath: savingPath)
        if fileExistFlag == true{
            let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(mediaPath: savingPath)
            imageForMedia = mediaImageFromFile!
        }
        else{
            let thumbUrl = UrlManager.sharedInstance.getThumbImageForMedia(mediaId: mediaId, userName: userId, accessToken: accessToken)
            let url = convertStringtoURL(url: thumbUrl)
            downloadMedia(downloadURL: url, key: "ThumbImage", completion: { (result) -> Void in
                if(result != UIImage()){
                    let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
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
                    imageForMedia =  UIImage(named: "thumb12")!
                }
            })
        }
        return imageForMedia
    }
    
    // delete media from Channels
    func deleteMediasFromChannel(channelId: String, mediaIdChkS: NSMutableArray)
    {
        let archiveChannelId = UserDefaults.standard.value(forKey: archiveId) as! Int
        
        var mediaIds = [String]()
        for element in mediaIdChkS{
            mediaIds.append(element as! String)
        }
        mediaIds = mediaIds.sorted()
        if channelId == "\(archiveChannelId)"
        {
            deleteMediasFromAllChannels(chanelId: channelId, mediaIds: mediaIds)
            deleteMediaFromCache(mediaIds:mediaIds)
        }
        else{
            deleteMediaFromParticularChannel(chanelId: channelId,mediaIds:mediaIds)
        }
    }
    
    func deleteMediaFromCache(mediaIds: [String])
    {
        for i in 0 ..< mediaIds.count
        {
            if(i < mediaIds.count){
                let selectedMediaId = mediaIds[i]
                let mediaIdForFilePathThumb = "\(selectedMediaId)thumb"
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
                let savingPathThumb = parentPath! + "/" + mediaIdForFilePathThumb
                _ = FileManagerViewController.sharedInstance.deleteImageFromFilePath(mediaPath: savingPathThumb)
                let mediaIdForFilePathFull = "\(selectedMediaId)full"
                let savingPathFull = parentPath! + "/" + mediaIdForFilePathFull
                _ = FileManagerViewController.sharedInstance.deleteImageFromFilePath(mediaPath: savingPathFull)
            }
        }
    }
    
    //delete media from a single channel
    func deleteMediaFromParticularChannel(chanelId : String,mediaIds: [String])
    {
        var selectedIndex : [Int] = [Int]()
        var mediaIdForFilePath : String = String()
        for i in 0 ..< mediaIds.count
        {
            if(i < mediaIds.count){
                let selectedMediaId = mediaIds[i]
                var chkFlag = false
                var indexOfJ = 0
                
                for j in 0 ..< GlobalChannelImageDict[chanelId]!.count
                {
                    if(j < GlobalChannelImageDict[chanelId]!.count){
                        
                        indexOfJ = j
                        let mediaIdChk = GlobalChannelImageDict[chanelId]![j][mediaIdKey] as! String
                        if mediaIdChk == selectedMediaId
                        {
                            chkFlag = true
                            break
                        }
                    }
                }
                if chkFlag == true
                {
                    selectedIndex.append(indexOfJ)
                }
            }
        }
        if selectedIndex.count > 0
        {
            selectedIndex = selectedIndex.sorted()
            for k in 0 ..< selectedIndex.count
            {
                if(k < selectedIndex.count){
                    let indexToDelete = selectedIndex[k] - k
                    GlobalChannelImageDict[chanelId]!.remove(at: indexToDelete)
                }
            }
            GlobalChannelImageDict[chanelId]!.sort(by: { p1, p2 in
                let time1 = Int(p1[mediaIdKey] as! String)
                let time2 = Int(p2[mediaIdKey] as! String)
                return time1! > time2!
            })
        }
        
        for p in 0 ..< GlobalDataChannelList.sharedInstance.globalChannelDataSource.count
        {
            let chanIdChk = GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][channelIdKey] as! String
            if chanelId == chanIdChk
            {
                if GlobalChannelImageDict[chanelId]!.count > 0
                {
                    mediaIdForFilePath = GlobalChannelImageDict[chanelId]![0][mediaIdKey] as! String
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][latestMediaIdKey] = mediaIdForFilePath
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][tImageKey] = downloadLatestMedia(mediaId: mediaIdForFilePath)
                }else{
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][tImageKey] = UIImage(named: "thumb12")
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][latestMediaIdKey] = ""
                }
                GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][totalMediaKey] = "\(GlobalChannelImageDict[chanelId]!.count)"
            }
        }
        GlobalDataChannelList.sharedInstance.globalChannelDataSource.sort(by: { p1, p2 in
            let time1 = p1[ChannelCreatedTimeKey] as! String
            let time2 = p2[ChannelCreatedTimeKey] as! String
            return time1 > time2
        })
    }
    
    
    //deleting from archive needs to delete medias from all channels
    func deleteMediasFromAllChannels(chanelId : String,mediaIds: [String])
    {
        let globalchannelIdList : Array = Array(GlobalChannelImageDict.keys)
        for i in 0 ..< globalchannelIdList.count
        {
            if(i < globalchannelIdList.count){
                let globalChanelId = globalchannelIdList[i]
                deleteMediaFromParticularChannel(chanelId: globalChanelId, mediaIds: mediaIds)
            }
        }
        UserDefaults.standard.set(GlobalChannelImageDict[chanelId]!.count, forKey: ArchiveCount)
    }
    func getFilteredCount() -> Int
    {
        return self.filteredcount
    }
    func setFilteredCount( count : Int)
    {
        self.filteredcount = count
    }
    
    func setFailedUploadMediaDetails(mediaId: String, thumbURL: String, fullURL: String, mediaType: String) {
        var chkFlag = false
        if(mediaUploadFailedDict.count > 0){
            for j in 0 ..< mediaUploadFailedDict.count
            {
                if j < mediaUploadFailedDict.count
                {
                    let mediaIdChk = mediaUploadFailedDict[j][mediaIdKey] as! String
                    if mediaIdChk == mediaId
                    {
                        chkFlag = true
                        break
                    }
                }
            }
            if(chkFlag == false){
                mediaUploadFailedDict.append([mediaIdKey:mediaId, tImageURLKey:thumbURL, fImageURLKey:fullURL, mediaTypeKey: mediaType])
            }
        }
        else{
            mediaUploadFailedDict.append([mediaIdKey:mediaId, tImageURLKey:thumbURL, fImageURLKey:fullURL, mediaTypeKey: mediaType])
        }
    }
    
    func removeUploadSuccessMediaDetails(mediaId: String)  {
        var chkFlag = false
        var indexChk = 0
        if(mediaUploadFailedDict.count > 0){
            for j in 0 ..< mediaUploadFailedDict.count
            {
                if j < mediaUploadFailedDict.count
                {
                    let mediaIdChk = mediaUploadFailedDict[j][mediaIdKey] as! String
                    if mediaIdChk == mediaId
                    {
                        chkFlag = true
                        indexChk = j
                        break
                    }
                }
            }
            if(chkFlag == true){
                mediaUploadFailedDict.remove(at: indexChk)
            }
        }
    }
    
    func cleanMyDayBasedOnTimeStamp(MyDayChanelId: String) {
        if(GlobalChannelImageDict.count > 0){
            if((GlobalChannelImageDict[MyDayChanelId]?.count)! > 0){
                GlobalChannelImageDict[MyDayChanelId]?.removeAll()
            }
        }
        
        for p in 0 ..< GlobalDataChannelList.sharedInstance.globalChannelDataSource.count
        {
            if(p < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count){
                let chanIdChk = GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][channelIdKey] as! String
                if MyDayChanelId == chanIdChk
                {
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][tImageKey] = UIImage(named: "thumb12")
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][latestMediaIdKey] = ""
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[p][totalMediaKey] = "\(GlobalChannelImageDict[MyDayChanelId]!.count)"
                }
            }
        }
        GlobalDataChannelList.sharedInstance.globalChannelDataSource.sort(by: { p1, p2 in
            let time1 = p1[ChannelCreatedTimeKey] as! String
            let time2 = p2[ChannelCreatedTimeKey] as! String
            return time1 > time2
        })
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "removeActivityIndicatorMyChannelList"), object:nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "removeActivityIndicatorMyChannel"), object:nil)
    }
}
