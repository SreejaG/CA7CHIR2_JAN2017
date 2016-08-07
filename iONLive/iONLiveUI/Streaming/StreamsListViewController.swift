
import UIKit

class StreamsListViewController: UIViewController{
    
    let streamTockenKey = "wowza_stream_token"
    let imageKey = "image"
    let typeKey = "type"
    let imageType = "imageType"
    let timestamp = "last_updated_time_stamp"
    let channelIdkey = "ch_detail_id"
    let channelNameKey = "channel_name"
    let notificationKey = "notification"
    let userIdKey = "user_name"
    static let identifier = "StreamsListViewController"
    let imageUploadManger = ImageUpload.sharedInstance
    let profileManager = ProfileManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    var firstTap : Int = 0
    var offset: String = "0"
    var offsetToInt : Int = Int()
    let isWatched = "isWatched"
    let actualImageKey = "actualImage"
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var fullImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaAndLiveArray:[[String:AnyObject]] = [[String:AnyObject]]()
    let cameraController = IPhoneCameraViewController()
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    let timeKey = ""
    let thumbImageKey = "thumbImage"
    var mediaShared:[[String:AnyObject]] = [[String:AnyObject]]()
    var tapCount : Int = 0
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var refreshControl:UIRefreshControl!
    var pullToRefreshActive = false
    var  liveStreamSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var count : Int = 0
    var limit : Int = 20
    var downloadCompleteFlag : String = "start"
    var lastContentOffset: CGPoint = CGPoint()
    @IBOutlet weak var streamListCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        firstTap = 0
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.streamListCollectionView.alwaysBounceVertical = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.streamUpdate), name: "stream", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.mediaDeletePushNotification), name: "MediaDelete", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.pushNotificationUpdateStream), name: "PushNotification", object:nil)
        getAllLiveStreams()
        initialise()
        showOverlay()
        if GlobalStreamList.sharedInstance.GlobalStreamDataSource.count == 0
        {
            GlobalStreamList.sharedInstance.initialiseCloudData(count ,endValueLimit: limit)
            self.refreshControl.addTarget(self, action: #selector(StreamsListViewController.pullToRefresh), forControlEvents: UIControlEvents.ValueChanged)
            self.streamListCollectionView.addSubview(self.refreshControl)
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.setSourceByAppendingMediaAndLive()
                self.refreshControl.addTarget(self, action: #selector(StreamsListViewController.pullToRefresh), forControlEvents: UIControlEvents.ValueChanged)
                self.streamListCollectionView.addSubview(self.refreshControl)
                self.streamListCollectionView.reloadData()
            })
        }
    }
    override func viewWillAppear(animated: Bool) {
        if (NSUserDefaults.standardUserDefaults().objectForKey("StreamListActive") == nil)
        {
            NSUserDefaults.standardUserDefaults().setValue("Active", forKey: "StreamListActive")
        }
        else{
            if NSUserDefaults.standardUserDefaults().objectForKey("StreamListActive") as! String == "Active"
            {
                if(mediaAndLiveArray.count == 0)
                {
                    self.showOverlay()
                    GlobalStreamList.sharedInstance.imageDataSource.removeAll()
                    GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAll()
                    GlobalStreamList.sharedInstance.initialiseCloudData(0, endValueLimit: 21)
                }
            }
            else
            {
                NSUserDefaults.standardUserDefaults().setValue("Active", forKey: "StreamListActive")
            }
        }
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        //        if(self.pullToRefreshActive)
        //        {
        //            self.refreshControl.endRefreshing()
        //        }
    }
    func pushNotificationUpdateStream(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        if (info["type"] as! String == "liveStream")
        {
            channelPushNotificationLiveStarted(info)
            
        }
        else if(info["type"] as! String == "channel")
        {
            if(info["subType"] as! String == "useradded")
            {
                
            }
            else{
                let channelId = info["channelId"]!
                deleteChannelSpecificMediaFromLocal("\(channelId)")
                deleteChannelSpecificMediaFromGlobal("\(channelId)")
            }
        }
        
        
    }
    func deleteChannelSpecificMediaFromLocal(channelId : String)
    {
        var selectedArray : [Int] = [Int]()
        var foundFlag : Bool = false
        var removeIndex : Int = Int()
        
        
        for(var i = 0 ; i < mediaAndLiveArray.count ; i++)
        {
            let channelIdValue = mediaAndLiveArray[i][self.channelIdkey] as! String
            var  count : Int = 0
            print(channelIdValue,"\(channelId)")
            if ( channelIdValue == "\(channelId)")
            {
                selectedArray.append(i)
            }
        }
        selectedArray =  selectedArray.sort()
        print(selectedArray)
        for(var i = 0 ; i < selectedArray.count ; i++)
        {
            //GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i])
            mediaAndLiveArray.removeAtIndex(selectedArray[i] - i)
            
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.streamListCollectionView.reloadData()
        })
        decremntMediaSharedCount(selectedArray.count , chanlId:channelId)
    }
    func decremntMediaSharedCount( count : Int , chanlId : String)
    {
        let totalNoShared = "totalNo"
        
        var mediaSharedCountArray:[[String:AnyObject]] = [[String:AnyObject]]()
        let defaults = NSUserDefaults .standardUserDefaults()
        mediaSharedCountArray = defaults.valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        
        if(count != 0)
        {
            for i in 0  ..< mediaSharedCountArray.count
            {
                if  mediaSharedCountArray[i][channelIdkey] as! String == chanlId
                {
                    let totalNo = mediaShared[i][totalNoShared] as! String
                    let totalNoLatest : Int = Int(totalNo)! - count
                    if totalNoLatest >= 0
                    {
                        mediaShared[i][totalNoShared]  = "\(totalNoLatest)"
                    }
                    let defaults = NSUserDefaults .standardUserDefaults()
                    defaults.setObject(mediaSharedCountArray, forKey: "Shared")
                }
            }
        }
        
    }
    func deleteChannelSpecificMediaFromGlobal(channelId : String)
    {
        var selectedArray : [Int] = [Int]()
        var foundFlag : Bool = false
        var removeIndex : Int = Int()
        
        
        for(var i = 0 ; i < GlobalStreamList.sharedInstance.GlobalStreamDataSource.count ; i++)
        {
            let channelIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][self.channelIdkey] as! String
            var  count : Int = 0
            print(channelIdValue,"\(channelId)")
            if ( channelIdValue == "\(channelId)")
            {
                selectedArray.append(i)
            }
        }
        selectedArray =  selectedArray.sort()
        print(selectedArray)
        for(var i = 0 ; i < selectedArray.count ; i++)
        {
            GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i] - i)
            
        }
    }
    
    func channelPushNotificationLiveStarted(info: [String : AnyObject])
    {
        // let info = notif.object as! [String : AnyObject]
        let subType = info["subType"] as! String
        
        switch subType {
        case "started":
            updateLiveStreamStartedEntry(info)
            break;
        case "stopped":
            updateLiveStreamStoppeddEntry(info)
            break;
            
        default:
            break;
        }
    }
    func updateLiveStreamStartedEntry(info:[String : AnyObject])
    {
        ErrorManager.sharedInstance.streamAvailable()
        getAllLiveStreams()
    }
    func updateLiveStreamStoppeddEntry(info:[String : AnyObject])
    {
        let channelId = info["channelId"] as! Int
        let livStreamId = info ["liveStreamId"] as! Int
        var  checkFlag : Bool = false
        var removeIndex : Int = Int()
        for (index, element) in mediaAndLiveArray.enumerate() {
            // do something with index
            if element[channelIdkey] as? String == "\(channelId)"
            {
                if(element[mediaIdKey] as? String == "\(livStreamId)")
                {
                    removeIndex = index
                    checkFlag = true
                }
            }
        }
        if checkFlag
        {
            mediaAndLiveArray.removeAtIndex(removeIndex)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.streamListCollectionView.reloadData()
            })
        }
        
        
        //        let index  = getUpdateIndexChannel("\(channelId)", isCountArray: false)
        //        if(index != -1)
        //        {
        //
        //        }
    }
    func getUpdateIndexChannel(channelId : String , isCountArray : Bool) -> Int
    {
        var selectedArray : NSArray = NSArray()
        var indexOfRow : Int = Int()
        if(isCountArray)
        {
            if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
            {
                mediaShared.removeAll()
                mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
            }
            selectedArray = mediaShared as Array
        }
        else{
            selectedArray = mediaAndLiveArray
        }
        var  checkFlag : Bool = false
        for (index, element) in selectedArray.enumerate() {
            // do something with index
            if element[channelIdkey] as? String == channelId
            {
                indexOfRow = index
                checkFlag = true
            }
        }
        if (!checkFlag)
        {
            indexOfRow = -1
        }
        return indexOfRow
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if (self.lastContentOffset.y < scrollView.contentOffset.y) {
            if(self.downloadCompleteFlag == "end")
            {
                do {
                    if(self.downloadCompleteFlag == "end")
                    {
                        let sortList : Array = GlobalStreamList.sharedInstance.GlobalStreamDataSource
                        var subIdArray : [Int] = [Int]()
                        
                        for(var i = 0 ; i < sortList.count ; i++)
                        {
                            subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                        }
                        if(subIdArray.count > 0)
                        {
                            let subid = subIdArray.minElement()!
                            self.downloadCompleteFlag = "start"
                            GlobalStreamList.sharedInstance.imageDataSource.removeAll()
                            GlobalStreamList.sharedInstance.getMediaByOffset("\(subid)")
                        }
                    }
                } catch {
                    print("do it error")
                }
            }
        }
        if (self.lastContentOffset.y > scrollView.contentOffset.y) {
            print("Scrolled Up");
        }
    }
    func mediaDeletePushNotification(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        let type =  info["type"] as! String
        if(type == "media")
        {
            getDataUsingNotificationId(info)
        }
        else{
            let channelId = info["channelId"] as! Int
            let mediaArrayData  = info["mediaId"] as! NSArray
            removeDataFromGlobal(channelId, mediaArrayData: mediaArrayData)
        }
    }
    func removeDataFromGlobal(channelId : Int , mediaArrayData : NSArray)
    {
        var selectedArray :[Int] = [Int]()
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            for(var mediaArrayCount = 0 ; mediaArrayCount < mediaArrayData.count ; mediaArrayCount++)
            {
                var foundFlag : Bool = false
                var removeIndex : Int = Int()
                for(var i = 0 ; i < GlobalStreamList.sharedInstance.GlobalStreamDataSource.count ; i++)
                {
                    let channelIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][self.channelIdkey] as! String
                    
                    if ( channelIdValue == "\(channelId)")
                    {
                        let mediaIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][self.mediaIdKey] as! String
                        
                        if( mediaIdValue == "\(mediaArrayData[mediaArrayCount])" )
                        {
                            foundFlag = true
                            removeIndex = i
                        }
                    }
                }
                if(foundFlag)
                {
                    selectedArray.append(removeIndex)
                }
            }
        })
        selectedArray.sortInPlace()
        for(var i = 0 ; i < selectedArray.count ; i++)
        {
            GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i])
        }
        let qualityOfServiceClass1 = QOS_CLASS_BACKGROUND
        let backgroundQueue1 = dispatch_get_global_queue(qualityOfServiceClass1, 0)
        dispatch_async(backgroundQueue1, {
            self.removeFromMediaAndLiveArray(channelId, mediaData: mediaArrayData)
            
        })
        
    }
    func getDataUsingNotificationId(info : [String : AnyObject])
    {
        //  let info = notif.object as! [String : AnyObject]
        let notifId : Int = info["notificationId"] as! Int
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey) as! String
        let accessTocken = userDefault.objectForKey(userAccessTockenKey) as! String
        channelManager.getDataByNotificationId(loginId, accessToken: accessTocken, notificationId: "\(notifId)", success: { (response) in
            self.getAllChannelIdsSuccessHandler(response)
        }) { (error, message) in
            self.authenticationFailureHandlerForLiveStream(error, code: message)
        }
        
    }
    func getAllChannelIdsSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["notificationMessage"] as! String
            let responseArrData = convertStringToDictionary1(responseArr)
            let channelIdArray : NSArray = responseArrData!["channelId"] as! NSArray
            let mediaArrayData : NSArray = responseArrData!["mediaId"] as! NSArray
            deleteFromLocal(channelIdArray, mediaArrayData: mediaArrayData)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.streamListCollectionView.reloadData()
                
            })
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.deleteFromGlobal(channelIdArray, mediaArrayData: mediaArrayData)
                
            })
            
        }
    }
    
    func deleteFromGlobal (channelIdArray : NSArray, mediaArrayData : NSArray)
    {
        var selectedArray : [Int] = [Int]()
        var removeIndex : Int = Int()
        for(var j = 0 ; j < channelIdArray .count ; j++)
        {
            let channel = channelIdArray[j] as! Int
            
            for(var i = 0 ; i < GlobalStreamList.sharedInstance.GlobalStreamDataSource.count ; i++)
            {
                let channelIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][self.channelIdkey] as! String
                var foundFlag : Bool = false
                
                if ( channelIdValue == "\(channel)")
                {
                    var  count : Int = 0
                    let mediaId = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][self.mediaIdKey] as! String
                    
                    //                                    if( mediaIdValue == "\(mediaArrayData[mediaArrayCount])" )
                    for(var mediaArrayCount = 0 ; mediaArrayCount < mediaArrayData.count ; mediaArrayCount++)
                    {
                        let mediaIdValue = mediaArrayData[mediaArrayCount] as! String
                        
                        if(mediaIdValue == mediaId)
                        {
                            removeIndex = i
                            count = count + 1
                            foundFlag = true
                            break;
                            
                        }
                    }
                    if(foundFlag)
                    {
                        foundFlag = false
                        
                        selectedArray.append(i)
                    }
                }
            }
        }
        selectedArray =  selectedArray.sort()
        for(var i = 0 ; i < selectedArray.count ; i++)
        {
            GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i] - i)
            
        }
        
    }
    
    func deleteFromLocal (channelIdArray : NSArray, mediaArrayData : NSArray)
    {
        var selectedArray : [Int] = [Int]()
        var removeIndex : Int = Int()
        var channelIDCount : [String : AnyObject] = [String : AnyObject]()
        
        for(var j = 0 ; j < channelIdArray .count ; j++)
        {
            let channel = channelIdArray[j] as! Int
            
            for(var i = 0 ; i < mediaAndLiveArray.count ; i++)
            {
                let channelIdValue = mediaAndLiveArray[i][self.channelIdkey] as! String
                var foundFlag : Bool = false
                var  count : Int = 0
                if ( channelIdValue == "\(channel)")
                {
                    let mediaId = mediaAndLiveArray[i][self.mediaIdKey] as! String
                    for(var mediaArrayCount = 0 ; mediaArrayCount < mediaArrayData.count ; mediaArrayCount++)
                    {
                        let mediaIdValue = mediaArrayData[mediaArrayCount] as! String
                        
                        if(mediaIdValue == mediaId)
                        {
                            count = count + 1
                            removeIndex = i
                            foundFlag = true
                            break;
                            
                        }
                    }
                    if(foundFlag)
                    {
                        foundFlag = false
                        channelIDCount.updateValue(count, forKey: channelIdValue)
                        
                        selectedArray.append(i)
                    }
                }
                
            }
        }
        selectedArray =  selectedArray.sort()
        for(var i = 0 ; i < selectedArray.count ; i++)
        {
            //GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i])
            mediaAndLiveArray.removeAtIndex(selectedArray[i] - i)
            
        }
        NSNotificationCenter.defaultCenter().postNotificationName("StreamToChannelMedia", object: channelIDCount)
        
    }
    func convertStringToDictionary1(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    func convertStringToDictionary(text: String) -> NSArray? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSArray
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    func removeLiveFromMediaAndLiveArray(channelId : Int,type : String)
    {
        var selectedArray :[Int] = [Int]()
        var foundFlag : Bool = false
        var removeIndex : Int = Int()
        for(var i = 0 ; i < mediaAndLiveArray.count ; i++)
        {
            let channelIdValue = mediaAndLiveArray[i][channelIdkey] as! String
            if (channelIdValue == "\(channelId)")
            {
                let mediaIdValue = mediaAndLiveArray[i][mediaTypeKey] as! String
                
                if(mediaIdValue == "live" )
                {
                    foundFlag = true
                    removeIndex = i
                    break
                }
            }
        }
        if(foundFlag)
        {
            selectedArray.append(removeIndex)
            foundFlag = false
            
        }
        if(selectedArray.count > 0)
        {
            var pathArray : [NSIndexPath] = [NSIndexPath]()
            selectedArray = selectedArray.sort()
            for(var i = 0 ; i < selectedArray.count ; i++)
            {
                
                let index = selectedArray[i]
                let indexPath: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
                pathArray.append(indexPath)
                mediaAndLiveArray.removeAtIndex(index)
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.streamListCollectionView.reloadData()
            })
        }
    }
    func removeFromMediaAndLiveArray(channelId : Int,mediaData : NSArray)
    {
        var selectedArray :[Int] = [Int]()
        for(var mediaArrayCount = 0 ; mediaArrayCount < mediaData.count ; mediaArrayCount++)
        {
            var foundFlag : Bool = false
            var removeIndex : Int = Int()
            for(var i = 0 ; i < mediaAndLiveArray.count ; i++)
            {
                let channelIdValue = mediaAndLiveArray[i][channelIdkey] as! String
                if (channelIdValue == "\(channelId)")
                {
                    let mediaIdValue = mediaAndLiveArray[i][mediaIdKey] as! String
                    
                    if(mediaIdValue == "\(mediaData[mediaArrayCount])" )
                    {
                        foundFlag = true
                        removeIndex = i
                        break
                    }
                }
            }
            if(foundFlag)
            {
                selectedArray.append(removeIndex)
                foundFlag = false
                
            }
            
            
        }
        if(selectedArray.count > 0)
        {
            var pathArray : [NSIndexPath] = [NSIndexPath]()
            selectedArray = selectedArray.sort()
            for(var i = 0 ; i < selectedArray.count ; i++)
            {
                
                let index = selectedArray[i]
                let indexPath: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
                pathArray.append(indexPath)
                mediaAndLiveArray.removeAtIndex(index - i)
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.streamListCollectionView.reloadData()
            })
        }
        
        
    }
    func remove(pathArray : NSArray) {
        
        //   var indexPath: NSIndexPath = NSIndexPath(forRow: i, inSection: 0)
        var pathArray : [NSIndexPath] = [NSIndexPath]()
        // pathArray.append(indexPath)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.streamListCollectionView.performBatchUpdates({
                self.streamListCollectionView.deleteItemsAtIndexPaths(pathArray)
                }, completion: {
                    (finished: Bool) in
                    //                              self.streamListCollectionView.reloadItemsAtIndexPaths(self.streamListCollectionView.indexPathsForVisibleItems())
                    
            })
        })
    }
    func getUpdateIndex(channelId : String , isCountArray : Bool) -> Int
    {
        
        var selectedArray : NSArray = NSArray()
        var indexOfRow : Int = Int()
        if(isCountArray)
        {
            if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
            {
                mediaShared.removeAll()
                mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
            }
            selectedArray = mediaShared as Array
            
        }
        else{
            selectedArray = GlobalStreamList.sharedInstance.GlobalStreamDataSource
        }
        var  checkFlag : Bool = false
        for (index, element) in selectedArray.enumerate() {
            // do something with index
            if element["mediaId"] as? String == channelId
            {
                indexOfRow = index
                checkFlag = true
            }
        }
        if (!checkFlag)
        {
            indexOfRow = -1
        }
        return indexOfRow
    }
    func setSourceByAppendingMediaAndLive()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mediaAndLiveArray.removeAll()
            self.mediaAndLiveArray = self.liveStreamSource +  GlobalStreamList.sharedInstance.GlobalStreamDataSource
            self.streamListCollectionView.reloadData()
        })
        
    }
    func streamUpdate(notif: NSNotification)
    {
        if(self.downloadCompleteFlag == "start")
        {
            downloadCompleteFlag = "end"
        }
        if(pullToRefreshActive){
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshControl.endRefreshing()
                self.pullToRefreshActive = false
            })
        }
        let success =  notif.object as! String
        if(success == "success")
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.setSourceByAppendingMediaAndLive()
                self.streamListCollectionView.reloadData()
            })
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                
                //  ErrorManager.sharedInstance.emptyMedia()
                self.setSourceByAppendingMediaAndLive()
                self.streamListCollectionView.reloadData()
            })
        }
    }
    func initialise()
    {
        totalMediaCount = 0
        firstTap = firstTap + 1
        if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
        {
            mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        }
        for i in 0 ..< mediaShared.count
        {
            totalMediaCount = totalMediaCount + Int(mediaShared[i]["totalNo"] as! String)!
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func  loadInitialViewController(code: String){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
            
            if(NSFileManager.defaultManager().fileExistsAtPath(documentsPath))
            {
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtPath(documentsPath)
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                FileManagerViewController.sharedInstance.createParentDirectory()
            }
            else{
                FileManagerViewController.sharedInstance.createParentDirectory()
            }
            
            let defaults = NSUserDefaults .standardUserDefaults()
            let deviceToken = defaults.valueForKey("deviceToken") as! String
            defaults.removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
            defaults.setValue(deviceToken, forKey: "deviceToken")
            defaults.setObject(1, forKey: "shutterActionMode");
            let sharingStoryboard = UIStoryboard(name:"Authentication", bundle: nil)
            let channelItemListVC = sharingStoryboard.instantiateViewControllerWithIdentifier("AuthenticateNavigationController") as! AuthenticateNavigationController
            channelItemListVC.navigationController?.navigationBarHidden = true
            self.presentViewController(channelItemListVC, animated: false) { () -> Void in
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        })
    }
    
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        let data = NSData(contentsOfURL: downloadURL)
        if let imageData = data as NSData? {
            if let mediaImage1 = UIImage(data: imageData)
            {
                mediaImage = mediaImage1
            }
            completion(result: mediaImage)
        }
        else
        {
            completion(result:UIImage(named: "thumb12")!)
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - (64 + 50))
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://130.211.135.170:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        self.presentViewController(vc, animated: false) { () -> Void in
        }
    }
    func pullToRefresh()
    {
        if(!pullToRefreshActive){
            
            pullToRefreshActive = true
            self.downloadCompleteFlag = "start"
            if(mediaAndLiveArray.count > 0){
                //  let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                //  let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                //  dispatch_async(backgroundQueue, {
                self.getAllLiveStreams()
                //    })
                self.getPullToRefreshData()
                
            }
            else{
                self.refreshControl.endRefreshing()
                pullToRefreshActive = false
                
            }
        }
        else
        {
            
        }
    }
    func getPullToRefreshData()
    {
        GlobalStreamList.sharedInstance.imageDataSource.removeAll()
        GlobalStreamList.sharedInstance.getPullToRefreshData()
    }
    //PRAGMA MARK:- API Handlers
    func getAllLiveStreams()
    {
        liveStreamSource.removeAll()
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        if let loginId = loginId, let accessTocken = accessTocken
        {
            livestreamingManager.getAllLiveStreams(loginId:loginId as! String , accesstocken:accessTocken as! String ,success: { (response) -> () in
                self.getAllStreamSuccessHandler(response)
                }, failure: { (error, message) -> () in
                    self.authenticationFailureHandlerForLiveStream(error, code: message)
                    return
            })
        }
        else
        {
            removeOverlay()
            if(pullToRefreshActive){
                self.refreshControl.endRefreshing()
                pullToRefreshActive = false
            }
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func authenticationFailureHandlerForLiveStream(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                self.initialise()
            }
        }
        else{
            self.initialise()
        }
    }
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    func getAllStreamSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let responseArrLive = json["liveStreams"] as! [[String:AnyObject]]
            if (responseArrLive.count != 0)
            {
                for element in responseArrLive{
                    let stremTockn = element[streamTockenKey] as! String
                    let userId = element[userIdKey] as! String
                    let channelIdSelected = element["ch_detail_id"]?.stringValue
                    let channelname = element[channelNameKey] as! String
                    let mediaId = element["live_stream_detail_id"]?.stringValue
                    let pulltorefresh = element["channel_live_stream_detail_id"]?.stringValue
                    var notificationType : String = String()
                    
                    if let notifType =  element["notification_type"] as? String
                    {
                        if notifType != ""
                        {
                            notificationType = (notifType as? String)!.lowercaseString
                        }
                        else{
                            notificationType = "shared"
                        }
                    }
                    else{
                        notificationType = "shared"
                    }
                    var imageForMedia : UIImage = UIImage()
                    let thumbUrlBeforeNullChk = element["live_stream_signedUrl"]
                    let thumbUrl = nullToNil(thumbUrlBeforeNullChk) as! String
                    if(thumbUrl != ""){
                        let url: NSURL = convertStringtoURL(thumbUrl)
                        downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                            if(result != UIImage()){
                                imageForMedia = result
                            }
                        })
                    }
                    else{
                        imageForMedia = UIImage(named: "thumb12")!
                    }
                    
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                    let currentDate = dateFormatter.stringFromDate(NSDate())
                    var foundFlag : Bool = false
                    //                    for(var liveStreamIndex = 0 ; liveStreamIndex < mediaAndLiveArray.count ; liveStreamIndex++)
                    //                    {
                    //                        let mediaIdFromSource = mediaAndLiveArray[liveStreamIndex][self.mediaIdKey] as! String
                    //
                    //                        if  mediaIdFromSource == mediaId
                    //                        {
                    //                            foundFlag = true
                    //                        }
                    //
                    //                    }
                    //                    if(!foundFlag)
                    //                    {
                    liveStreamSource.append([self.mediaIdKey:mediaId!, self.mediaUrlKey:"", self.timestamp :currentDate,self.thumbImageKey:imageForMedia ,self.streamTockenKey:stremTockn,self.actualImageKey:"",self.userIdKey:userId,self.notificationKey:notificationType,self.mediaTypeKey:"live",self.timeKey:currentDate,self.channelNameKey:channelname, self.channelIdkey: channelIdSelected!,"createdTime":currentDate,pullTorefreshKey :pulltorefresh!])
                    // }
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if(self.mediaAndLiveArray.count == 0)
                    {
                        if(self.liveStreamSource.count > 0)
                        {
                            self.setSourceByAppendingMediaAndLive()
                        }
                    }
                    self.streamListCollectionView.reloadData()
                })
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func loadStaticImagesOnly()
    {
        self.streamListCollectionView.reloadData()
    }
    @IBAction func customBackButtonClicked(sender: AnyObject)
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
    }
    func  didSelectExtension(indexPathRow: Int)
    {
        getProfileImageSelectedIndex(indexPathRow)
    }
    func getProfileImageSelectedIndex(indexpathRow: Int)
    {
        if(mediaAndLiveArray.count > 0)
        {
            let subUserName = mediaAndLiveArray[indexpathRow][userIdKey] as! String
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            profileManager.getSubUserProfileImage(userId, accessToken: accessToken, subscriberUserName: subUserName, success: { (response) in
                self.successHandlerForProfileImage(response,indexpathRow: indexpathRow)
                }, failure: { (error, message) -> () in
                    self.failureHandlerForprofileImage(error, code: message,indexPathRow:indexpathRow)
                    return
            })
            
        }
    }
    var profileImageUserForSelectedIndex : UIImage = UIImage()
    func successHandlerForProfileImage(response:AnyObject?,indexpathRow:Int)
    {
        if let json = response as? [String: AnyObject]
        {
            let profileImageNameBeforeNullChk = json["profile_image_thumbnail"]
            let profileImageName = self.nullToNil(profileImageNameBeforeNullChk) as! String
            if(profileImageName != "")
            {
                let url: NSURL = self.convertStringtoURL(profileImageName)
                if let data = NSData(contentsOfURL: url){
                    let imageDetailsData = (data as NSData?)!
                    profileImageUserForSelectedIndex = UIImage(data: imageDetailsData)!
                }
                else{
                    profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
                }
            }
            else{
                profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
            }
            
        }
        else{
            profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
        }
        getLikeCountForSelectedIndex(indexpathRow,profile: profileImageUserForSelectedIndex)
    }
    func failureHandlerForprofileImage(error: NSError?, code: String,indexPathRow:Int)
    {
        profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
        getLikeCountForSelectedIndex(indexPathRow,profile: profileImageUserForSelectedIndex)
    }
    func getLikeCountForSelectedIndex(indexpathRow:Int,profile:UIImage)  {
        let mediaId = mediaAndLiveArray[indexpathRow][mediaIdKey] as! String
        getLikeCount(mediaId, indexpathRow: indexpathRow, profile: profile)
    }
    func getLikeCount(mediaId: String,indexpathRow:Int,profile:UIImage) {
        let mediaTypeSelected : String = mediaAndLiveArray[indexpathRow][mediaTypeKey] as! String
        var likeCount: String = "0"
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        channelManager.getMediaLikeCountDetails(userId, accessToken: accessToken, mediaId: mediaId, mediaType: mediaTypeSelected, success: { (response) in
            self.successHandlerForMediaCount(response,indexpathRow:indexpathRow,profile: profile)
            }, failure: { (error, message) -> () in
                self.failureHandlerForMediaCount(error, code: message,indexPathRow:indexpathRow,profile: profile)
                return
        })
    }
    var likeCountSelectedIndex : String = "0"
    func successHandlerForMediaCount(response:AnyObject?,indexpathRow:Int,profile:UIImage)
    {
        if let json = response as? [String: AnyObject]
        {
            likeCountSelectedIndex = json["likeCount"] as! String
        }
        loadmovieViewController(indexpathRow, profileImage: profile, likeCount: likeCountSelectedIndex)
    }
    func failureHandlerForMediaCount(error: NSError?, code: String,indexPathRow:Int,profile:UIImage)
    {
        likeCountSelectedIndex = "0"
        loadmovieViewController(indexPathRow, profileImage: profile, likeCount: likeCountSelectedIndex)
    }
    func loadmovieViewController(indexPathRow:Int,profileImage:UIImage,likeCount:String) {
        
        self.removeOverlay()
        streamListCollectionView.alpha = 1.0
        
        let type = mediaAndLiveArray[indexPathRow][mediaTypeKey] as! String
        if((type ==  "image") || (type == "video"))
        {
            let dateString = mediaAndLiveArray[indexPathRow]["createdTime"] as! String
            let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
            let vc = MovieViewController.movieViewControllerWithImageVideo(mediaAndLiveArray[indexPathRow][self.actualImageKey] as! String, channelName: mediaAndLiveArray[indexPathRow][self.channelNameKey] as! String,channelId: mediaAndLiveArray[indexPathRow][self.channelIdkey] as! String, userName: mediaAndLiveArray[indexPathRow][self.userIdKey] as! String, mediaType:mediaAndLiveArray[indexPathRow][self.mediaTypeKey] as! String, profileImage: profileImage, videoImageUrl:mediaAndLiveArray[indexPathRow][self.mediaUrlKey] as! UIImage, notifType: mediaAndLiveArray[indexPathRow][self.notificationKey] as! String, mediaId: mediaAndLiveArray[indexPathRow][self.mediaIdKey] as! String,timeDiff:imageTakenTime,likeCountStr:likeCount) as! MovieViewController
            self.presentViewController(vc, animated: false) { () -> Void in
            }
        }
        else
        {
            let streamTocken = mediaAndLiveArray[indexPathRow][self.streamTockenKey] as! String
            if streamTocken != ""
            {
                let parameters : NSDictionary = ["channelName": mediaAndLiveArray[indexPathRow][self.channelNameKey] as! String, "userName":mediaAndLiveArray[indexPathRow][self.userIdKey] as! String, "mediaType":mediaAndLiveArray[indexPathRow][self.mediaTypeKey] as! String, "profileImage":profileImage, "notifType":mediaAndLiveArray[indexPathRow][self.notificationKey] as! String, "mediaId":mediaAndLiveArray[indexPathRow][self.mediaIdKey] as! String,"channelId":mediaAndLiveArray[indexPathRow][self.channelIdkey] as! String,"likeCount":likeCount as! String]
                let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://130.211.135.170:1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false) as! UIViewController
                
                self.presentViewController(vc, animated: false) { () -> Void in
                }
            }
            else
            {
                ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
            }
        }
    }
    
}
extension StreamsListViewController:UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if  mediaAndLiveArray.count > 0
        {
            return mediaAndLiveArray.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("StreamListCollectionViewCell", forIndexPath: indexPath) as! StreamListCollectionViewCell
        
        if  mediaAndLiveArray.count > 0
        {
            if mediaAndLiveArray.count > indexPath.row
            {
                let type = mediaAndLiveArray[indexPath.row][mediaTypeKey] as! String
                if let imageThumb = mediaAndLiveArray[indexPath.row][thumbImageKey] as? UIImage
                {
                    
                    if type == "video"
                    {
                        cell.liveStatusLabel.hidden = false
                        cell.liveStatusLabel.text = ""
                        cell.liveNowIcon.hidden = false
                        cell.liveNowIcon.image = UIImage(named: "Live_now_off_mode")
                        cell.streamThumbnaleImageView.image = imageThumb
                    }
                    else if type == "image"{
                        
                        cell.liveStatusLabel.hidden = true
                        cell.liveNowIcon.hidden = true
                        cell.streamThumbnaleImageView.image = imageThumb
                    }
                    else
                    {
                        cell.liveStatusLabel.hidden = false
                        cell.liveStatusLabel.text = "LIVE"
                        cell.liveNowIcon.hidden = false
                        cell.liveNowIcon.image = UIImage(named: "Live_now")
                        cell.streamThumbnaleImageView.image = imageThumb
                    }
                }
            }
        }
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        //   if(!pullToRefreshActive){
        if  mediaAndLiveArray.count>0
        {
            if mediaAndLiveArray.count > indexPath.row
            {
                collectionView.alpha = 0.4
                showOverlay()
                didSelectExtension(indexPath.row)
            }
        }
        // }
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, 1, 0, 1)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSizeMake((UIScreen.mainScreen().bounds.width/3)-2, 100)
    }
}
extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
