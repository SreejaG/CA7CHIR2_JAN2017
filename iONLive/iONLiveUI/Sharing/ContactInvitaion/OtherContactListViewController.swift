
import AddressBook
import AddressBookUI
import UIKit

class OtherContactListViewController: UIViewController {
    
    private var addressBookRef: ABAddressBook?
    
    func setAddressBook(addressBook: ABAddressBook) {
        addressBookRef = addressBook
    }
    
    static let identifier = "OtherContactListViewController"
    
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    
    let defaults = UserDefaults.standard
    var userId = String()
    var accessToken = String()
    
    var channelId:String!
    var totalMediaCount: Int = Int()
    var channelName:String!
    
    var loadingOverlay: UIView?
    
    var searchActive: Bool = false
    
    var ca7chContactSource:[[String:Any]] = [[String:Any]]()
    var phoneContactSource:[[String:Any]] = [[String:Any]]()
    
    var searchContactSource:[[[String:Any]]] = [[[String:Any]]]()
    
    var contactSource:[[[String:Any]]] = [[[String:Any]]]()
    
    var contactPhoneNumbers: [String] = [String]()
    
    var addUserArray : NSMutableArray = NSMutableArray()
    var inviteUserArray : NSMutableArray = NSMutableArray()
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var contactListSearchBar: UISearchBar!
    @IBOutlet var ca7chTableView: UITableView!
    @IBOutlet var ca7chTableBottomConstraint: NSLayoutConstraint!
    
    var NoDatalabelFormySharingImageList : UILabel = UILabel()
    
    let userNameKey = "userName"
    let profileImageKey = "profileImage"
    let subscribedKey = "sharedindicator"
    let selectionKey = "selected"
    let profileImageUrlKey = "profile_image_URL"
    
    //Pull to refresh
    var refreshControl:UIRefreshControl!
    var pullToRefreshActive = false
    
    var operationQueueObjInSharingContactList = OperationQueue()
    var operationInSharingContactList = BlockOperation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshCa7chContactsList = Notification.Name("refreshCa7chContactsListTableView")
        NotificationCenter.default.addObserver(self, selector:#selector(OtherContactListViewController.refreshCa7chContactsListTableView(notif:)), name: refreshCa7chContactsList, object: nil)
        
        contactAuthorizationAlert()
        
        addKeyboardObservers()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(OtherChannelViewController.pullToRefresh), for: .valueChanged)
        self.ca7chTableView.addSubview(self.refreshControl)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        operationInSharingContactList.cancel()
        NotificationCenter.default.removeObserver(self, name: Notification.Name("refreshCa7chContactsListTableView"), object: nil)
    }
    
    func addKeyboardObservers()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(OtherContactListViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(OtherContactListViewController.keyboardDidHide),
                                               name: NSNotification.Name.UIKeyboardDidHide,
                                               object: nil)
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        if ca7chTableBottomConstraint.constant == 0
        {
            self.ca7chTableBottomConstraint.constant = self.ca7chTableBottomConstraint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if ca7chTableBottomConstraint.constant != 0
        {
            self.ca7chTableBottomConstraint.constant = 0
        }
    }
    
    func initialise()
    {
        let addressBookRef1 = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAddressBook(addressBook: addressBookRef1)
        
        ca7chContactSource.removeAll()
        phoneContactSource.removeAll()
        
        contactPhoneNumbers.removeAll()
        
        contactSource.removeAll()
        searchContactSource.removeAll()
        
        doneButton.isHidden = true
        searchActive = false
        
        userId = defaults.value(forKey: userLoginIdKey) as! String
        accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        
        NoDatalabelFormySharingImageList.removeFromSuperview()
        
        ca7chTableView.reloadData()
        
        displayContacts()
    }
    
    func pullToRefresh()
    {
        if(!pullToRefreshActive){
            pullToRefreshActive = true
            operationInSharingContactList.cancel()
            self.contactListSearchBar.text = ""
            self.contactListSearchBar.resignFirstResponder()
            searchActive = false
            self.getPullToRefreshData()
        }
        else
        {
        }
    }
    
    func getPullToRefreshData()
    {
        initialise()
    }
    
    func contactAuthorizationAlert()
    {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        switch authorizationStatus {
        case .denied, .restricted:
            generateContactSynchronizeAlert()
        case .authorized:
            self.initialise()
        case .notDetermined:
            promptForAddressBookRequestAccess()
        }
    }
    
    func generateContactSynchronizeAlert()
    {
        let alert = UIAlertController(title: "\"Catch\" would like to access your contacts", message: "The contacts in your address book will be transmitted to Catch for you to decide who to add", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.showEventsAcessDeniedAlert()
        }))
        self.present(alert, animated: false, completion: nil)
    }
    
    func promptForAddressBookRequestAccess() {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, { granted, error in              DispatchQueue.main.async {
            if !granted {
                self.generateContactSynchronizeAlert()
            } else {
                self.initialise()
            }
            }
        })
    }
    
    func showEventsAcessDeniedAlert() {
        let alertController = UIAlertController(title: "Permission Denied!",
                                                message: "The contact permission was not authorized. Please enable it in Settings to continue.",
                                                preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (alertAction) in
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings as URL)
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: false, completion: nil)
    }
    
    
    @IBAction func gestureTapped(_ sender: Any) {
        view.endEditing(true)
        self.contactListSearchBar.text = ""
        self.contactListSearchBar.resignFirstResponder()
        searchActive = false
        self.ca7chTableView.reloadData()
        self.ca7chTableView.layoutIfNeeded()
    }
    
    func displayContacts(){
        if(!pullToRefreshActive){
            showOverlay()
        }
        let phoneCode = defaults.value(forKey: "countryCode") as! String
        let allContacts = ABAddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as Array
        for record in allContacts {
            let phones : ABMultiValue = ABRecordCopyValue(record,kABPersonPhoneProperty).takeUnretainedValue() as ABMultiValue
            var phoneNumber: String = String()
            var appendPlus : String = String()
            for numberIndex : CFIndex in 0 ..< ABMultiValueGetCount(phones)
            {
                let phoneUnmaganed = ABMultiValueCopyValueAtIndex(phones, numberIndex)
                let phoneNumberStr = phoneUnmaganed?.takeUnretainedValue() as! String
                let phoneNumberWithCode: String!
                if(phoneNumberStr.hasPrefix("+")){
                    phoneNumberWithCode = phoneNumberStr
                }
                else if(phoneNumberStr.hasPrefix("00")){
                    let stringLength = phoneNumberStr.characters.count
                    let subStr = (phoneNumberStr as NSString).substring(with: NSRange(location: 2, length: stringLength - 2))
                    phoneNumberWithCode = (phoneCode).appending(subStr)
                }
                else if(phoneNumberStr.hasPrefix("0")){
                    let stringLength = phoneNumberStr.characters.count
                    let subStr = (phoneNumberStr as NSString).substring(with: NSRange(location: 1, length: stringLength - 1))
                    phoneNumberWithCode = (phoneCode).appending(subStr)
                }
                else{
                    phoneNumberWithCode = (phoneCode).appending(phoneNumberStr)
                }
                
                if phoneNumberWithCode.hasPrefix("+")
                {
                    appendPlus = "+"
                }
                else{
                    appendPlus = "nil"
                }
                
                let phoneNumberStringArray = (phoneNumberWithCode).components(
                    separatedBy: CharacterSet.decimalDigits.inverted)
                
                if appendPlus == "+"
                {
                    phoneNumber = (appendPlus).appending(NSArray(array: phoneNumberStringArray).componentsJoined(by: "")) as String
                }
                
                var currentContactImage : UIImage = UIImage()
                
                if let currentContactImageData = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail)?.takeRetainedValue() as CFData!
                {
                    currentContactImage = UIImage(data: currentContactImageData as Data)!
                }
                else{
                    currentContactImage = UIImage(named: "dummyUser")!
                }
                
                if(phoneNumber != ""){
                    contactPhoneNumbers.append(phoneNumber)
                    var currentContactName = String()
                    if ABRecordCopyCompositeName(record) != nil
                    {
                        currentContactName = ABRecordCopyCompositeName(record).takeRetainedValue() as String
                    }
                    else{
                        currentContactName = "No Name"
                    }
                    self.phoneContactSource.append([self.userNameKey: currentContactName, self.profileImageKey: currentContactImage, "orgSelected":0, "tempSelected":0])
                }
            }
        }
        if contactPhoneNumbers.count > 0
        {
            addContactDetails(contactPhoneNumbers: self.contactPhoneNumbers as NSArray)
        }
        else{
            if(!pullToRefreshActive){
                self.removeOverlay()
            }
            else{
                self.refreshControl.endRefreshing()
                self.pullToRefreshActive = false
            }
            addNoDataLabel()
        }
    }
    
    func addNoDataLabel()
    {
        self.NoDatalabelFormySharingImageList = UILabel(frame: CGRect(x:((self.view.frame.width/2) - 100), y:((self.view.frame.height/2) - 35), width:200, height:70))
        self.NoDatalabelFormySharingImageList.textAlignment = NSTextAlignment.center
        self.NoDatalabelFormySharingImageList.text = "No Contacts Available"
        self.view.addSubview(self.NoDatalabelFormySharingImageList)
    }
    
    func addContactDetails(contactPhoneNumbers: NSArray)
    {
        contactManagers.addContactDetails(userName: userId, accessToken: accessToken, userContacts: contactPhoneNumbers, success:  { (response) -> () in
            self.authenticationSuccessHandlerAdd(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandlerAdd(error: error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerAdd(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            var status: Int!
            status = json["status"] as! Int
            if(status >= 1)
            {
                getChannelContactDetails(username: userId, token: accessToken, channelid: channelId)
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func authenticationFailureHandlerAdd(error: NSError?, code: String)
    {
        if(self.pullToRefreshActive){
            self.refreshControl.endRefreshing()
            self.pullToRefreshActive = false
        }
        else{
            self.removeOverlay()
        }
        setContactDetails()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if code == "CONTACT002" {
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
                if code == "CONTACT001"{
                }
            }
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code: code)
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func getChannelContactDetails(username: String, token: String, channelid: String)
    {
        channelManager.getChannelNonContactDetails(channelId: channelid, userName: username, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        if(!pullToRefreshActive){
            self.removeOverlay()
        }
        else{
            self.refreshControl.endRefreshing()
            self.pullToRefreshActive = false
        }
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["contactList"] as! [AnyObject]
            
            for element in responseArr{
                let userName = element["user_name"] as! String
                let thumbUrl = UrlManager.sharedInstance.getUserProfileImageBaseURL() + userId + "/" + accessToken + "/" + userName
                
                var profileImage : UIImage?
                
                let savingPath = "\(userName)Profile"
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
                let profileImagePath = parentPath! + "/" + savingPath
                let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(mediaPath: profileImagePath)
                
                if fileExistFlag == true{
                    let profileImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(mediaPath: profileImagePath)
                    profileImage = profileImageFromFile!
                }
                else{
                    profileImage = UIImage(named: "dummyUser")
                }
                
                ca7chContactSource.append([userNameKey:userName, profileImageUrlKey: thumbUrl,"tempSelected": 0, "orgSelected" : 0, profileImageKey : profileImage!, "profileFlag" : fileExistFlag])
            }
            
            self.setContactDetails()
            
            if(ca7chContactSource.count > 0){
                operationInSharingContactList  = BlockOperation (block: {
                    self.downloadMediaFromGCS(operationObj: self.operationInSharingContactList)
                })
                self.operationQueueObjInSharingContactList.addOperation(operationInSharingContactList)
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func downloadMediaFromGCS(operationObj: BlockOperation){
        var localArray = [[String:Any]]()
        for i in 0 ..< contactSource[0].count
        {
            localArray.append(contactSource[0][i])
        }
        for i in 0 ..< localArray.count
        {
            if operationObj.isCancelled == true{
                return
            }
            if(i < localArray.count){
                var profileImage : UIImage?
                let fileFlag = localArray[i]["profileFlag"] as! Bool
                if(!fileFlag)
                {
                    let user = localArray[i][userNameKey] as! String
                    let savingPath = "\(user)Profile"
                    let profileImageName = localArray[i][profileImageUrlKey] as! String
                    if(profileImageName != "")
                    {
                        profileImage = FileManagerViewController.sharedInstance.getProfileImage(profileNameURL: profileImageName)
                        let profileImageData = UIImageJPEGRepresentation(profileImage!, 0.5)
                        let profileImageDataAsNsdata = (profileImageData as NSData?)!
                        let imageFromDefault = UIImageJPEGRepresentation(UIImage(named: "dummyUser")!, 0.5)
                        let imageFromDefaultAsNsdata = (imageFromDefault as NSData?)!
                        if(profileImageDataAsNsdata.isEqual(imageFromDefaultAsNsdata)){
                        }
                        else{
                            _ =
                                FileManagerViewController.sharedInstance.saveImageToFilePath(mediaName: savingPath, mediaImage: profileImage!)
                        }
                    }
                    else{
                        profileImage = UIImage(named: "dummyUser")
                    }
                    localArray[i][profileImageKey] = profileImage
                }
            }
        }
        for j in 0 ..< contactSource[0].count
        {
            if operationObj.isCancelled == true{
                return
            }
            if j < contactSource[0].count
            {
                let userChk = contactSource[0][j][userNameKey] as! String
                for element in localArray
                {
                    let userLocalChk = element[userNameKey] as! String
                    if userChk == userLocalChk
                    {
                        if element[profileImageKey] != nil
                        {
                            contactSource[0][j][profileImageKey] = element[profileImageKey] as! UIImage
                        }
                    }
                }
            }
        }
        localArray.removeAll()
        DispatchQueue.main.async {
            self.ca7chTableView.reloadData()
        }
    }
    
    func setContactDetails()
    {
        contactSource = [ca7chContactSource,phoneContactSource]
        if(contactSource.count > 0){
            
        }
        else{
            addNoDataLabel()
        }
        ca7chTableView.reloadData()
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        if(self.pullToRefreshActive){
            self.refreshControl.endRefreshing()
            self.pullToRefreshActive = false
        }
        else{
            self.removeOverlay()
        }
        self.setContactDetails()
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code: code)
            }
            else
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func  loadInitialViewController(code: String){
        if let tokenValid = UserDefaults.standard.value(forKey: "tokenValid")
        {
            if tokenValid as! String == "true"
            {
                DispatchQueue.main.async {
                    let documentsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/GCSCA7CH"
                    
                    if(FileManager.default.fileExists(atPath: documentsPath))
                    {
                        let fileManager = FileManager.default
                        do {
                            try fileManager.removeItem(atPath: documentsPath)
                        }
                        catch _ as NSError {
                        }
                        _ = FileManagerViewController.sharedInstance.createParentDirectory()
                    }
                    else{
                        _ = FileManagerViewController.sharedInstance.createParentDirectory()
                    }
                    
                    let defaults = UserDefaults .standard
                    let deviceToken = defaults.value(forKey: "deviceToken") as! String
                    defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    defaults.setValue(deviceToken, forKey: "deviceToken")
                    defaults.set(1, forKey: "shutterActionMode");
                    defaults.setValue("false", forKey: "tokenValid")
                    
                    ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
                    
                    let sharingStoryboard = UIStoryboard(name:"Authentication", bundle: nil)
                    let channelItemListVC = sharingStoryboard.instantiateViewController(withIdentifier: "AuthenticateViewController") as! AuthenticateViewController
                    channelItemListVC.navigationController?.isNavigationBarHidden = true
                    self.navigationController?.pushViewController(channelItemListVC, animated: false)
                }
            }
        }
    }
    
    func refreshCa7chContactsListTableView(notif:NSNotification){
        if(doneButton.isHidden == true){
            doneButton.isHidden = false
        }
        let dict = notif.object as! [String:Int]
        let section: Int = dict["sectionKey"]!
        let row : Int = dict["rowKey"]!
        if(searchActive)
        {
            if searchContactSource[section].count > row
            {
                let selectedValue =  searchContactSource[section][row]["tempSelected"] as! Int
                if(selectedValue == 1)
                {
                    searchContactSource[section][row]["tempSelected"] = 0
                }
                else
                {
                    searchContactSource[section][row]["tempSelected"] = 1
                }
                let selecteduserId =  searchContactSource[section][row][userNameKey] as! String
                for j in 0 ..< contactSource[section].count
                {
                    if j < contactSource[section].count
                    {
                        let dataSourceUserId = contactSource[section][j][userNameKey] as! String
                        if(selecteduserId == dataSourceUserId)
                        {
                            contactSource[section][j]["tempSelected"] = searchContactSource[section][row]["tempSelected"]
                        }
                    }
                }
            }
        }
        else
        {
            if contactSource[section].count > row
            {
                let selectedValue =  contactSource[section][row]["tempSelected"] as! Int
                if(selectedValue == 1){
                    contactSource[section][row]["tempSelected"] = 0
                }
                else{
                    contactSource[section][row]["tempSelected"] = 1
                }
            }
        }
        
        var doneButtonHideFlagZero : Bool  = false
        var doneButtonHideFlagOne : Bool  = false
        for k in 0 ..< contactSource[0].count
        {
            if k < contactSource[0].count
            {
                let temp =  contactSource[0][k][sharedTemporaryKey] as! Int
                if temp != 0
                {
                    doneButtonHideFlagZero = true
                    break
                }
            }
        }
        if(doneButtonHideFlagZero){
            doneButton.isHidden = false
        }
        else{
            for l in 0 ..< contactSource[1].count
            {
                if l < contactSource[1].count
                {
                    let temp =  contactSource[1][l][sharedTemporaryKey] as! Int
                    if temp != 0
                    {
                        doneButtonHideFlagOne = true
                        break
                    }
                }
            }
            if(doneButtonHideFlagOne){
                doneButton.isHidden = false
            }
            else{
                doneButton.isHidden = true
            }
        }
        
        ca7chTableView.reloadData()
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url as NSString
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRect(x:0, y:64, width:self.view.frame.width, height:(self.view.frame.height - 64))
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        if(doneButton.isHidden == false){
            doneButton.isHidden = true
            if(searchActive){
                for i in 0 ..< searchContactSource[0].count
                {
                    if i < searchContactSource[0].count
                    {
                        let selectionValue : Int = searchContactSource[0][i]["orgSelected"] as! Int
                        searchContactSource[0][i]["tempSelected"] = selectionValue
                    }
                }
                for j in 0 ..< searchContactSource[1].count
                {
                    if j < searchContactSource[1].count
                    {
                        let selectionValue : Int = searchContactSource[1][j]["orgSelected"] as! Int
                        searchContactSource[1][j]["tempSelected"] = selectionValue
                    }
                }
                for i in 0 ..< contactSource[0].count
                {
                    if i < contactSource[0].count
                    {
                        contactSource[0][i]["tempSelected"] = 0
                    }
                }
                for j in 0 ..< contactSource[1].count
                {
                    if j < contactSource[1].count
                    {
                        contactSource[1][j]["tempSelected"] = 0
                    }
                }
            }
            else{
                for i in 0 ..< contactSource[0].count
                {
                    if i < contactSource[0].count
                    {
                        let selectionValue : Int = contactSource[0][i]["orgSelected"] as! Int
                        contactSource[0][i]["tempSelected"] = selectionValue
                    }
                }
                for j in 0 ..< contactSource[1].count
                {
                    if j < contactSource[1].count
                    {
                        let selectionValue : Int = contactSource[1][j]["orgSelected"] as! Int
                        contactSource[1][j]["tempSelected"] = selectionValue
                    }
                }
            }
            ca7chTableView.reloadData()
        }
        else{
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
    @IBAction func didTapDoneButton(_ sender: Any) {
        doneButton.isHidden = true
        ca7chTableView.reloadData()
        ca7chTableView.layoutIfNeeded()
        
        addUserArray.removeAllObjects()
        
        for i in 0 ..< contactSource[0].count
        {
            if i < contactSource[0].count
            {
                let userId = contactSource[0][i][userNameKey] as! String
                let selectionValue : Int = contactSource[0][i]["tempSelected"] as! Int
                if(selectionValue == 1){
                    addUserArray.add(userId)
                }
            }
        }
        
        for j in 0 ..< contactSource[1].count
        {
            if j < contactSource[1].count
            {
                let userId = contactSource[1][j][userNameKey] as! String
                let selectionValue : Int = contactSource[1][j]["tempSelected"] as! Int
                if(selectionValue == 1){
                    inviteUserArray.add(userId)
                }
            }
        }
        
        if addUserArray.count > 0
        {
            inviteContactList(userName: userId, accessToken: accessToken, channelid: channelId, addUser: addUserArray)
        }
        else if inviteUserArray.count > 0
        {
            loadMychannelDetailController()
        }
    }
    
    func inviteContactList(userName: String, accessToken: String, channelid: String, addUser: NSMutableArray){
        showOverlay()
        channelManager.AddContactToChannel(userName: userName, accessToken: accessToken, channelId: channelid, adduser: addUserArray, success: { (response) -> () in
            self.authenticationSuccessHandlerInvite(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerInvite(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                for i in 0 ..< contactSource[0].count
                {
                    if i < contactSource[0].count
                    {
                        let selectionValue : Int = contactSource[0][i]["tempSelected"] as! Int
                        contactSource[0][i]["orgSelected"] = selectionValue
                    }
                }
                for j in 0 ..< contactSource[1].count
                {
                    if j < contactSource[1].count
                    {
                        let selectionValue : Int = contactSource[1][j]["tempSelected"] as! Int
                        contactSource[1][j]["orgSelected"] = selectionValue
                    }
                }
                loadMychannelDetailController()
            }
        }
    }
    
    func loadMychannelDetailController(){
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let channelDetailVC:UITabBarController = sharingStoryboard.instantiateViewController(withIdentifier: MyChannelDetailViewController.identifier) as! UITabBarController
        (channelDetailVC as! MyChannelDetailViewController).channelId = channelId as String
        (channelDetailVC as! MyChannelDetailViewController).channelName = channelName as String
        (channelDetailVC as! MyChannelDetailViewController).totalMediaCount = Int(totalMediaCount)
        channelDetailVC.navigationController?.isNavigationBarHidden = true
        self.navigationController?.pushViewController(channelDetailVC, animated: false)
    }
}

extension OtherContactListViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "Ca7chContactsHeaderTableViewCell") as! Ca7chContactsHeaderTableViewCell
        
        switch (section) {
        case 0:
            headerCell.headerLabel.text = "USING CATCH"
        case 1:
            headerCell.headerLabel.text = "MY CONTACTS"
        default:
            headerCell.headerLabel.text = ""
        }
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section
        {
        case 0:
            if(searchActive){
                if(searchContactSource.count > 0){
                    return searchContactSource[0].count > 0 ? (searchContactSource[0].count) : 0
                }
                else{
                    return 0
                }
            }
            else{
                return contactSource[0].count > 0 ? (contactSource[0].count) : 0
            }
        case 1:
            if(searchActive){
                if(searchContactSource.count > 0){
                    return searchContactSource[1].count > 0 ? (searchContactSource[1].count) : 0
                }
                else{
                    return 0
                }
            }
            else{
                return contactSource[1].count > 0 ? (contactSource[1].count) : 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Ca7chContactsTableViewCell.identifier, for:indexPath as IndexPath) as! Ca7chContactsTableViewCell
        
        var cellDataSource:[String:Any]?
        var datasourceTmp: [[[String:Any]]]?
        
        if(searchActive){
            datasourceTmp = searchContactSource
        }
        else{
            datasourceTmp = contactSource
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
        }
        
        if let cellDataSource = cellDataSource
        {
            cell.contactUserName.text = cellDataSource[userNameKey] as? String
            cell.contactProfileImage.image = cellDataSource[profileImageKey] as? UIImage
            cell.subscriptionButton.tag = indexPath.row
            cell.section = indexPath.section
            
            let selectionValue : Int = cellDataSource["tempSelected"] as! Int
            if(selectionValue == 1){
                cell.subscriptionButton.setImage(UIImage(named:"CheckOn"), for:.normal)
            }
            else{
                cell.subscriptionButton.setImage(UIImage(named:"red-circle"), for:.normal)
            }
            cell.selectionStyle = .none
            cell.profileDownloadIndicator.isHidden = true
            return cell
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return contactSource.count > 0 ? (contactSource.count) : 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: false)
        tableView.reloadData()
    }
}

extension OtherContactListViewController: UISearchBarDelegate{
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if searchBar.text != ""
        {
            searchActive = true
        }
        else{
            searchActive = false
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
        ca7chTableView.reloadData()
        ca7chTableView.layoutIfNeeded()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchContactSource.removeAll()
        var searchCa7chContactDataSource:[[String:Any]] = [[String:Any]]()
        var searchPhoneContactsDataSource: [[String:Any]] = [[String:Any]]()
        searchCa7chContactDataSource.removeAll()
        searchPhoneContactsDataSource.removeAll()
        
        if contactListSearchBar.text!.isEmpty
        {
            searchContactSource = contactSource
            contactListSearchBar.resignFirstResponder()
            self.ca7chTableView.reloadData()
        }
        else{
            if contactSource[0].count > 0
            {
                for element in contactSource[0]{
                    var tmp: String = ""
                    tmp = (element[userNameKey] as! String).lowercased()
                    if(tmp.range(of: searchText.lowercased()) != nil)
                    {
                        searchCa7chContactDataSource.append(element)
                    }
                }
            }
            if contactSource[1].count > 0
            {
                for element in contactSource[1]{
                    var tmp: String =  ""
                    tmp = (element[userNameKey] as! String).lowercased()
                    if(tmp.range(of: searchText.lowercased()) != nil)
                    {
                        searchPhoneContactsDataSource.append(element)
                    }
                }
            }
            searchContactSource = [searchCa7chContactDataSource, searchPhoneContactsDataSource]
            searchActive = true
            self.ca7chTableView.reloadData()
        }
    }
}
