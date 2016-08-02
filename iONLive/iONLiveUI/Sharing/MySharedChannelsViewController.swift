//
//  MySharedChannelsViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/22/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MySharedChannelsViewController: UIViewController {
    
    static let identifier = "MySharedChannelsViewController"
    
    @IBOutlet weak var sharedChannelsTableView: UITableView!
    @IBOutlet weak var sharedChannelsSearchBar: UISearchBar!
    @IBOutlet weak var tableViewBottomConstaint: NSLayoutConstraint!
    
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    
    let channelDetailIdKey = "channel_detail_id"
    let mediaDetailIdKey = "media_detail_id"
    let channelNameKey = "channel_name"
    let totalMediaCountKey = "total_media_count"
    let createdTimeStampKey = "created_timeStamp"
    let sharedIndicatorOriginalKey = "orgSelected"
    let sharedIndicatorTemporaryKey = "tempSelected"
    let thumbImageKey = "thumbImage"
    let thumbImageURLKey = "thumbImage_URL"
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    var searchActive : Bool = false
    var searchDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var addChannelArray : NSMutableArray = NSMutableArray()
    var deleteChannelArray : NSMutableArray = NSMutableArray()
    
    @IBOutlet var doneButton: UIButton!
    
    var loadingOverlay: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MySharedChannelsViewController.CallRefreshMySharedChannelTableView(_:)), name: "refreshMySharedChannelTableView", object: nil)
        
        doneButton.hidden = true
    
        dataSource.removeAll()
        addChannelArray.removeAllObjects()
        deleteChannelArray.removeAllObjects()
        
        sharedChannelsSearchBar.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(MySharedChannelsViewController.removeActivityIndicator(_:)), name: "removeActivityIndicatorMyChannelList", object: nil)
        
        showOverlay()
        if (GlobalDataChannelList.sharedInstance.globalChannelDataSource.count > 0)
        {
            removeOverlay()
            dataSource.removeAll()
            createChannelDataSource()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func removeActivityIndicator(notif : NSNotification){
        dataSource.removeAll()
        self.createChannelDataSource()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.removeOverlay()
        })
    }
    
    @IBAction func backButtonClicked(sender: AnyObject)
    {
        if(doneButton.hidden == false){
            doneButton.hidden = true
            for var i = 0; i < dataSource.count; i++
            {
                let selectionValue : Int = dataSource[i]["orgSelected"] as! Int
                dataSource[i]["tempSelected"] = selectionValue
            }
            self.sharedChannelsTableView.reloadData()
        }
        else{
            let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
            let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
            self.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
        }
    }
    
    func addKeyboardObservers()
    {
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidShow:", name: UIKeyboardDidShowNotification, object:nil)]
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidHide", name: UIKeyboardWillHideNotification, object:nil)]
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if tableViewBottomConstaint.constant == 0
        {
            self.tableViewBottomConstaint.constant = self.tableViewBottomConstaint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableViewBottomConstaint.constant != 0
        {
            self.tableViewBottomConstaint.constant = 0
        }
    }
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
        self.sharedChannelsSearchBar.text = ""
        self.sharedChannelsSearchBar.resignFirstResponder()
        searchActive = false
        self.sharedChannelsTableView.reloadData()
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        doneButton.hidden = true
        self.sharedChannelsTableView.reloadData()
        sharedChannelsTableView.layoutIfNeeded()
        addChannelArray.removeAllObjects()
        deleteChannelArray.removeAllObjects()
        for var i = 0; i < dataSource.count; i++
        {
            let channelid = dataSource[i][channelDetailIdKey] as! String
            let selectionValue : Int = dataSource[i][sharedIndicatorTemporaryKey] as! Int
            if(selectionValue == 1){
                addChannelArray.addObject(channelid)
            }
            else{
                 deleteChannelArray.addObject(channelid)
            }
        }
        if((addChannelArray.count > 0) || (deleteChannelArray.count > 0)){
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            enableDisableChannels(userId, token: accessToken, addChannels: addChannelArray, deleteChannels: deleteChannelArray)
        }
    }
    
    func  enableDisableChannels(userName: String, token: String, addChannels: NSMutableArray, deleteChannels:NSMutableArray) {
        showOverlay()
        channelManager.enableDisableChannels(userName, accessToken: token, addChannel: addChannels, deleteChannel: deleteChannels, success: { (response) in
            self.authenticationSuccessHandlerEnableDisable(response)
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func loadInitialViewController(code: String){
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
    
    func authenticationSuccessHandlerEnableDisable(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                for var i = 0; i < dataSource.count; i++
                {
                    let selectionValue : Int = dataSource[i][sharedIndicatorTemporaryKey] as! Int
                    dataSource[i][sharedIndicatorOriginalKey] = selectionValue
                }
                sharedChannelsTableView.reloadData()
                GlobalDataChannelList.sharedInstance.enableDisableChannelList(dataSource)
            }
        }
        else
        {
            for var i = 0; i < dataSource.count; i++
            {
                let selectionValue : Int = dataSource[i][sharedIndicatorOriginalKey] as! Int
                dataSource[i][sharedIndicatorTemporaryKey] = selectionValue
            }
            
            ErrorManager.sharedInstance.inValidResponseError()
            sharedChannelsTableView.reloadData()
        }
    }
    
    func createChannelDataSource()
    {
        for element in GlobalDataChannelList.sharedInstance.globalChannelDataSource
        {
            let chanelName = element[channelNameKey] as! String
            if chanelName != "Archive"
            {
                dataSource.append(element)
            }
        }
        if dataSource.count > 0{
            sharedChannelsTableView.reloadData()
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
        
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
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

    func authenticationFailureHandler(error: NSError?, code: String)
    {
        removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
        for var i = 0; i < dataSource.count; i++
        {
            let selectionValue : Int = dataSource[i]["orgSelected"] as! Int
            dataSource[i]["tempSelected"] = selectionValue
        }
        self.sharedChannelsTableView.reloadData()
    }
    
    func CallRefreshMySharedChannelTableView(notif:NSNotification){
        if(doneButton.hidden == true){
            doneButton.hidden = false
        }
        let indexpath = notif.object as! Int
        if(searchActive)
        {
            let selectedValue =  searchDataSource[indexpath][sharedIndicatorTemporaryKey] as! Int
            if(selectedValue == 1)
            {
                searchDataSource[indexpath][sharedIndicatorTemporaryKey] = 0
            }
            else
            {
                searchDataSource[indexpath][sharedIndicatorTemporaryKey] = 1
            }
            
            let selectedChannelId =  searchDataSource[indexpath][channelDetailIdKey] as! String
            for (var i = 0; i < dataSource.count; i++)
            {
                let dataSourceChannelId = dataSource[i][channelDetailIdKey] as! String
                if(selectedChannelId == dataSourceChannelId)
                {
                    dataSource[i][sharedIndicatorTemporaryKey] = searchDataSource[indexpath][sharedIndicatorTemporaryKey]
                }
            }
        }
        else
        {
            
            let selectedValue =  dataSource[indexpath][sharedIndicatorTemporaryKey] as! Int
            if(selectedValue == 1){
                dataSource[indexpath][sharedIndicatorTemporaryKey] = 0
            }
            else{
                dataSource[indexpath][sharedIndicatorTemporaryKey] = 1
            }
        }
        sharedChannelsTableView.reloadData()
    }
}

extension MySharedChannelsViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 45.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsHeaderCell.identifier) as! MySharedChannelsHeaderCell
        headerCell.headerTitleLabel.text = "MY SHARED CHANNELS"
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
}

extension MySharedChannelsViewController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if(searchActive){
            return searchDataSource.count > 0 ? (searchDataSource.count) : 0
        }
        else{
            return dataSource.count > 0 ? (dataSource.count) : 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var dataSourceTmp : [[String:AnyObject]]?
        if(searchActive){
            dataSourceTmp = searchDataSource
        }
        else{
            dataSourceTmp = dataSource
        }
        
        if dataSourceTmp!.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsCell.identifier, forIndexPath:indexPath) as! MySharedChannelsCell
            
            cell.channelNameLabel.text = dataSourceTmp![indexPath.row][channelNameKey] as? String
            cell.sharedCountLabel.text = dataSourceTmp![indexPath.row][totalMediaCountKey] as? String
            
            if let latestImage = dataSourceTmp![indexPath.row][thumbImageKey]
            {
                cell.userImage.image = latestImage as? UIImage
            }
            else
            {
                cell.userImage.image = UIImage(named: "thumb12")
            }

            cell.channelSelectionButton.tag = indexPath.row
            
            let selectionValue : Int = dataSourceTmp![indexPath.row][sharedIndicatorTemporaryKey] as! Int
            if(selectionValue == 1){
                cell.channelSelectionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
                cell.sharedCountLabel.hidden = false
                cell.avatarIconImageView.hidden = false
            }
            else{
                cell.channelSelectionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
                cell.sharedCountLabel.hidden = true
                cell.avatarIconImageView.hidden = true
            }
            cell.selectionStyle = .None
            return cell
        }
        else{
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        NSUserDefaults.standardUserDefaults().setInteger(1, forKey: "tabToAppear")
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let channelDetailVC:UITabBarController = sharingStoryboard.instantiateViewControllerWithIdentifier(MyChannelDetailViewController.identifier) as! UITabBarController
        if(!searchActive){
            if dataSource.count > indexPath.row
            {
                (channelDetailVC as! MyChannelDetailViewController).channelId = dataSource[indexPath.row][channelDetailIdKey] as! String
                (channelDetailVC as! MyChannelDetailViewController).channelName = dataSource[indexPath.row][channelNameKey] as! String
                (channelDetailVC as! MyChannelDetailViewController).totalMediaCount = Int(dataSource[indexPath.row][totalMediaCountKey]! as! String)!
            }
        }
        else{
            if searchDataSource.count > indexPath.row
            {
                (channelDetailVC as! MyChannelDetailViewController).channelId = searchDataSource[indexPath.row][channelDetailIdKey] as! String
                (channelDetailVC as! MyChannelDetailViewController).channelName = searchDataSource[indexPath.row][channelNameKey] as! String
                (channelDetailVC as! MyChannelDetailViewController).totalMediaCount = Int(searchDataSource[indexPath.row][totalMediaCountKey]! as! String)!
            }
        }
        channelDetailVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelDetailVC, animated: false)
    }
}

extension MySharedChannelsViewController : UISearchBarDelegate,UISearchDisplayDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if self.sharedChannelsSearchBar.text != ""
        {
            searchActive = true
        }
        else{
            searchActive = false
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource.removeAll()
        
        if sharedChannelsSearchBar.text!.isEmpty
        {
            searchDataSource = dataSource
            sharedChannelsSearchBar.resignFirstResponder()
            self.sharedChannelsTableView.reloadData()
        }
        else{
            if dataSource.count > 0
            {
                for element in dataSource{
                    let tmp: String = (element[channelNameKey]?.lowercaseString)!
                    if(tmp.containsString(searchText.lowercaseString))
                    {
                        searchDataSource.append(element)
                    }
                }
               
                searchActive = true
                self.sharedChannelsTableView.reloadData()
            }
        }
    }
}
