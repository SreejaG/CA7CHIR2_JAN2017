//
//  ContactDetailsViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 16/03/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ContactDetailsViewController: UIViewController {
    
    var selectedContacts : [[String:AnyObject]] = [[String:AnyObject]]()
    
    var contactDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var appContactsArr: [[String:AnyObject]] = [[String:AnyObject]]()
    var dataSource:[[[String:AnyObject]]]?
    var indexTitles : NSArray = NSArray()
    
    var searchDataSource : [[[String:AnyObject]]]?
    var checkedMobiles : NSMutableDictionary = NSMutableDictionary()
    
    var searchActive: Bool = false
    var contactExistChk :Bool!
    
    let nameKey = "user_name"
    let phoneKey = "mobile_no"
    let imageKey = "profile_image"
    let selectionKey = "selection"
    let inviteKey = "invitationKey"
    
    static let identifier = "ContactDetailsViewController"
    
    let requestManager = RequestManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    
    var loadingOverlay: UIView?
    
    @IBOutlet var contactSearchBar: UISearchBar!
    
    @IBOutlet var contactTableView: UITableView!
    
    @IBAction func gestureTapped(sender: AnyObject) {
        view.endEditing(true)
        self.contactSearchBar.text = ""
        self.contactSearchBar.resignFirstResponder()
        searchActive = false
        self.contactTableView.reloadData()
        self.contactTableView.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        removeOverlay()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
        self.contactTableView.backgroundView = nil
        self.contactTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
        let contactsArray : NSMutableArray = NSMutableArray()
        contactsArray.removeAllObjects()
        for element in selectedContacts
        {
            if element[selectionKey] as! String == "1"
            {
                contactsArray.addObject(element[phoneKey] as! String)
            }
        }
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        showOverlay()
        contactManagers.inviteContactDetails(userId, accessToken: accessToken, contacts: contactsArray, success: { (response) -> () in
            self.authenticationSuccessHandlerInvite(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandlerInvite(error, code: message)
            return
        }
    }
    
    func  loadInitialViewController(){
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
        self.navigationController?.presentViewController(channelItemListVC, animated: true, completion: nil)
    }
    
    func authenticationSuccessHandlerInvite(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                loadIphoneCameraController()
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func authenticationFailureHandlerInvite(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            if code == "CONTACT001"{
                loadIphoneCameraController()
            }
            else  if code == "CONTACT002"{
                loadIphoneCameraController()
            }
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
            
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func loadIphoneCameraController(){
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
    }
    
    func initialise()
    {
        dataSource?.removeAll()
        appContactsArr.removeAll()
        selectedContacts.removeAll()
        searchDataSource?.removeAll()
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        if(contactExistChk == true){
            getContactDetails(userId, token: accessToken)
        }
        else{
            setContactDetails()
        }
        contactTableView.tableFooterView = UIView()
    }
    
    func getContactDetails(userName: String, token: String)
    {
        showOverlay()
        contactManagers.getContactDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            appContactsArr.removeAll()
            let responseArr = json["contactListOfUser"] as! [AnyObject]
            var contactImage : UIImage = UIImage()
            for element in responseArr{
                let userName = element[nameKey] as! String
                let selection = element[inviteKey] as! String
                let mobNum = element[phoneKey] as! String
                if let imageName =  element[imageKey]
                {
                    if let imageByteArray: NSArray = imageName!["data"] as? NSArray
                    {
                        var bytes:[UInt8] = []
                        for serverByte in imageByteArray {
                            bytes.append(UInt8(serverByte as! UInt))
                        }
                        
                        if let profileData:NSData = NSData(bytes: bytes, length: bytes.count){
                            let profileImageData = profileData as NSData?
                            contactImage = UIImage(data: profileImageData!)!
                        }
                    }
                    else{
                        contactImage = UIImage(named: "avatar")!
                    }
                }
                else{
                    contactImage = UIImage(named: "avatar")!
                }
                
                appContactsArr.append([nameKey:userName, phoneKey:mobNum,imageKey:contactImage,inviteKey:selection])
            }
            setContactDetails()
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            if code == "CONTACT001"{
                setContactDetails()
            }
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func setContactDetails()
    {
        var index : Int = 0
        if appContactsArr.count > 0 {
            for element in appContactsArr{
                let appNumber = element["mobile_no"] as! String
                if let num : String = appNumber{
                    index = 0
                    for element in contactDataSource{
                        let contactNumber = element["mobile_no"] as! String
                        if contactNumber == num {
                            contactDataSource.removeAtIndex(index)
                        }
                        index += 1
                    }
                }
            }
        }
        
        dataSource = [appContactsArr,contactDataSource]
        
        for ele in appContactsArr{
            selectedContacts.append([nameKey:ele[nameKey] as! String, phoneKey:ele[phoneKey] as! String, selectionKey:"1"])
        }
        
        for ele in contactDataSource{
            selectedContacts.append([nameKey:ele[nameKey] as! String, phoneKey:ele[phoneKey] as! String, selectionKey:"0"])
        }
        
        contactTableView.reloadData()
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
}

extension ContactDetailsViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 45.0
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("contactHeaderTableViewCell") as! contactHeaderTableViewCell
        
        switch (section) {
        case 0:
            headerCell.contactHeaderTitle.text = "USING CATCH"
        case 1:
            headerCell.contactHeaderTitle.text = "MY CONTACTS"
        default:
            headerCell.contactHeaderTitle.text = ""
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        
        switch section
        {
        case 0:
            if(searchActive){
                return searchDataSource != nil ? (searchDataSource?[0].count)! :0
            }
            else{
                return dataSource != nil ? (dataSource?[0].count)! :0
            }
        case 1:
            if(searchActive){
                return searchDataSource != nil ? (searchDataSource?[1].count)! :0
            }
            else{
                return dataSource != nil ? (dataSource?[1].count)! :0
            }
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("contactTableViewCell", forIndexPath:indexPath) as! contactTableViewCell
        
        var cellDataSource:[String:AnyObject]?
        var datasourceTmp: [[[String:AnyObject]]]?
        
        if(searchActive){
            datasourceTmp = searchDataSource
        }
        else{
            datasourceTmp = dataSource
        }
        
        if let dataSources = datasourceTmp
        {
            if dataSources.count > indexPath.section
            {
                if dataSources[indexPath.section].count > indexPath.row
                {
                    cellDataSource = dataSources[indexPath.section][indexPath.row]
                }
            }
            
            if(cell.deselectedArray.count > 0){
                
                for i in 0 ..< selectedContacts.count
                {
                    let selectedValue: String = selectedContacts[i][nameKey] as! String
                    if cell.deselectedArray.containsObject(selectedValue){
                        selectedContacts[i][selectionKey] = "0"
                    }
                }
            }
            
            if(cell.selectedArray.count > 0){
                
                for i in 0 ..< selectedContacts.count
                {
                    let selectedValue: String = selectedContacts[i][nameKey] as! String
                    if cell.selectedArray.containsObject(selectedValue){
                        selectedContacts[i][selectionKey] = "1"
                    }
                }
            }
        }
        
        if let cellDataSource = cellDataSource
        {
            cell.contactProfileName.text = cellDataSource[nameKey] as? String
            cell.contactProfileImage.image = cellDataSource[imageKey] as? UIImage
            
            if selectedContacts.count > 0
            {
                for i in 0 ..< selectedContacts.count
                {
                    if selectedContacts[i][nameKey] as! String == cellDataSource[nameKey] as! String{
                        if selectedContacts[i][selectionKey] as! String == "0"
                        {
                            cell.contactSelectionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
                        }
                        else{
                            cell.contactSelectionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
                        }
                    }
                }
            }
            cell.cellDataSource = cellDataSource
            cell.selectionStyle = .None
            return cell
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if let dataSource = dataSource
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        tableView.reloadData()
        
    }
}

extension ContactDetailsViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource?.removeAll()
        if contactSearchBar.text == "" {
            contactSearchBar.resignFirstResponder()
        }
        var searchContactDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
        var searchAppContactsArr: [[String:AnyObject]] = [[String:AnyObject]]()
        searchContactDataSource.removeAll()
        searchAppContactsArr.removeAll()
        
        if dataSource![0].count > 0
        {
            for element in dataSource![0]{
                var tmp: String = ""
                tmp = (element["user_name"]?.lowercaseString)!
                if(tmp.hasPrefix(searchText.lowercaseString))
                {
                    searchAppContactsArr.append(element)
                }
            }
        }
        if dataSource![1].count > 0
        {
            for element in dataSource![1]{
                var tmp: String =  ""
                tmp = (element["user_name"]?.lowercaseString)!
                if(tmp.hasPrefix(searchText.lowercaseString))
                {
                    searchContactDataSource.append(element)
                }
            }
        }
        
        searchDataSource = [searchAppContactsArr, searchContactDataSource]
        
        if((searchAppContactsArr.count == 0) && (searchContactDataSource.count == 0)){
            searchActive = false;
        } else {
            searchActive = true;
        }
        
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
    }
}
