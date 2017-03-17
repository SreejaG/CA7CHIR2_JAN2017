
import UIKit

class ContactDetailsViewController: UIViewController {
    var contactDataSource:[[String:Any]] = [[String:Any]]()
    var contactDummy:[[String:Any]] = [[String:Any]]()
    var appContactsArr: [[String:Any]] = [[String:Any]]()
    var dataSource:[[[String:Any]]]?
    var indexTitles : NSArray = NSArray()
    
    var searchDataSource : [[[String:Any]]]?
    var checkedMobiles : NSMutableDictionary = NSMutableDictionary()
    
    let defaults = UserDefaults.standard
    var userId = String()
    var accessToken = String()
    
    var searchActive: Bool = false
    var contactExistChk :Bool!
    
    let nameKey = "user_name"
    let phoneKey = "mobile_no"
    let imageKey = "profile_image"
    let selectionKey = "selection"
    let inviteKey = "invitationKey"
    let imageURLKey = "imageUrl"
    
    static let identifier = "ContactDetailsViewController"
    
    let requestManager = RequestManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    
    @IBOutlet weak var doneButton: UIButton!
    var loadingOverlay: UIView?
    
    @IBOutlet var contactSearchBar: UISearchBar!
    
    @IBOutlet var contactTableView: UITableView!
    
    @IBOutlet var tableBottomConstraint: NSLayoutConstraint!
    
    @IBAction func gestureTapped(_ sender: Any) {
        view.endEditing(true)
        self.contactSearchBar.text = ""
        self.contactSearchBar.resignFirstResponder()
        searchActive = false
        self.contactTableView.reloadData()
        self.contactTableView.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshSignUpContactList = Notification.Name("refreshSignUpContactListTableView")
        NotificationCenter.default.addObserver(self, selector:#selector(ContactDetailsViewController.callSignUpRefreshContactListTableView(notif:)), name: refreshSignUpContactList, object: nil)
        initialise()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
        self.contactTableView.backgroundView = nil
        self.contactTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
    }
    
    func addKeyboardObservers()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(ContactDetailsViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(ContactDetailsViewController.keyboardDidHide),
                                               name: NSNotification.Name.UIKeyboardDidHide,
                                               object: nil)
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        if tableBottomConstraint.constant == 0
        {
            self.tableBottomConstraint.constant = self.tableBottomConstraint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableBottomConstraint.constant != 0
        {
            self.tableBottomConstraint.constant = 0
        }
    }
    
    @IBAction func didTapDoneButton(_ sender: Any) {
        doneButton.isHidden = true
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
        let contactsArray : NSMutableArray = NSMutableArray()
        contactsArray.removeAllObjects()
        
        for i in 0 ..< dataSource!.count
        {
            if i < (dataSource?.count)!
            {
                for element in dataSource![i]{
                    let selected = element["tempSelected"] as! Int
                    if(selected == 1){
                        let number = element[phoneKey] as! String
                        contactsArray.add(number)
                    }
                }
            }
        }
        if(contactsArray.count > 0){
            showOverlay()
            contactManagers.inviteContactDetails(userName: userId, accessToken: accessToken, contacts: contactsArray, success: { (response) -> () in
                self.authenticationSuccessHandlerInvite(response: response)
            }) { (error, message) -> () in
                self.authenticationFailureHandlerInvite(error: error, code: message)
                return
            }
        }
        else{
            loadIphoneCameraController()
        }
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
            for i in 0 ..< dataSource!.count
            {
                if i < (dataSource?.count)!
                {
                    for j in 0 ..< dataSource![i].count
                    {
                        if(j < dataSource![i].count){
                            let selected = dataSource![i][j]["orgSelected"] as! Int
                            dataSource![i][j]["tempSelected"] = selected
                        }
                    }
                }
            }
            contactTableView.reloadData()
        }
    }
    
    func authenticationFailureHandlerInvite(error: NSError?, code: String)
    {
        self.removeOverlay()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if code == "CONTACT001"{
                loadIphoneCameraController()
            }
            else  if code == "CONTACT002"{
                loadIphoneCameraController()
            }
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
        
        for i in 0 ..< dataSource!.count
        {
            if i < (dataSource?.count)!
            {
                for j in 0 ..< dataSource![i].count
                {
                    if j < dataSource![i].count
                    {
                        let selected = dataSource![i][j]["orgSelected"] as! Int
                        dataSource![i][j]["tempSelected"] = selected
                    }
                }
            }
        }
        contactTableView.reloadData()
    }
    
    func loadIphoneCameraController(){
        UserDefaults.standard.setValue("initialCall", forKey: "CallingAPI")
        UserDefaults.standard.setValue("0", forKey: "notificationArrived")
        GlobalDataChannelList.sharedInstance.initialise()
        ChannelSharedListAPI.sharedInstance.initialisedata()
        
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewController(withIdentifier: "IPhoneCameraViewController") as! IPhoneCameraViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = iPhoneCameraVC
        self.present(iPhoneCameraVC, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
    
    func initialise()
    {
        dataSource?.removeAll()
        appContactsArr.removeAll()
        searchDataSource?.removeAll()
        
        addKeyboardObservers()
        
        userId = defaults.value(forKey: userLoginIdKey) as! String
        accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        
        if(contactExistChk == true){
            getContactDetails(userName: userId, token: accessToken)
        }
        else{
            setContactDetails()
        }
        contactTableView.tableFooterView = UIView()
    }
    
    func getContactDetails(userName: String, token: String)
    {
        showOverlay()
        contactManagers.getContactDetails(userName: userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
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
            let contactImage : UIImage = UIImage(named: "dummyUser")!
            for element in responseArr{
                
                let userName = element[nameKey] as! String
                let mobNum = element[phoneKey] as! String
                let thumbUrl = UrlManager.sharedInstance.getUserProfileImageBaseURL() + userId + "/" + accessToken + "/" + userName
                appContactsArr.append([nameKey:userName, phoneKey:mobNum,imageURLKey:thumbUrl, "orgSelected":0, "tempSelected":0, imageKey:contactImage])
            }
            setContactDetails()
            
            if(appContactsArr.count > 0){
                let backgroundQueue = DispatchQueue(label: "com.app.queue",
                                                    qos: .background,
                                                    target: nil)
                backgroundQueue.async {
                    self.downloadMediaFromGCS()
                }
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func downloadMediaFromGCS(){
        var localArray = [[String:Any]]()
        for i in 0 ..< dataSource![0].count
        {
            localArray.append(dataSource![0][i])
        }
        for i in 0 ..< localArray.count
        {
            if(i < localArray.count){
                var profileImage : UIImage?
                let profileImageName = localArray[i][imageURLKey] as! String
                if(profileImageName != "")
                {
                    profileImage = FileManagerViewController.sharedInstance.getProfileImage(profileNameURL: profileImageName)
                }
                else{
                    profileImage = UIImage(named: "dummyUser")
                }
                localArray[i][imageKey] = profileImage
            }
        }
        for j in 0 ..< dataSource![0].count
        {
            if j < dataSource![0].count
            {
                let userChk = dataSource![0][j][nameKey] as! String
                for element in localArray
                {
                    let userLocalChk = element[nameKey] as! String
                    if userChk == userLocalChk
                    {
                        if element[imageKey] != nil
                        {
                            dataSource![0][j][imageKey] = element[imageKey] as! UIImage
                        }
                    }
                }
            }
        }
        localArray.removeAll()
        DispatchQueue.main.async {
            self.contactTableView.reloadData()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if code == "CONTACT001"{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
                setContactDetails()
            }
            else if((code == "USER004") || (code == "USER005") || (code == "USER006")){
            }
        }
        else{
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRect(x:0, y:64, width:self.view.frame.width, height:self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func setContactDetails()
    {
        contactDummy.removeAll()
        var Cflag : Bool = false
        for i in 0 ..< contactDataSource.count
        {
            if i < contactDataSource.count
            {
                Cflag = false
                let contactNumber = contactDataSource[i]["mobile_no"] as! String
                for j in 0 ..< appContactsArr.count
                {
                    if j < appContactsArr.count
                    {
                        let appNumber = appContactsArr[j]["mobile_no"] as! String
                        if(contactNumber == appNumber) {
                            Cflag = true
                            break
                        }
                        else{
                            Cflag = false
                        }
                    }
                }
                if(Cflag == false){
                    contactDummy.append(contactDataSource[i])
                }
            }
        }
        contactDataSource.removeAll()
        contactDataSource = contactDummy
        contactDummy.removeAll()
        dataSource = [appContactsArr,contactDataSource]
        contactTableView.reloadData()
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url as NSString
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func callSignUpRefreshContactListTableView(notif:NSNotification){
        if(doneButton.isHidden == true){
            doneButton.isHidden = false
        }
        let dict = notif.object as! [String:Int]
        let section: Int = dict["sectionKey"]!
        let row : Int = dict["rowKey"]!
        if(searchActive)
        {
            if searchDataSource![section].count > row
            {
                let selectedValue =  searchDataSource![section][row]["tempSelected"] as! Int
                if(selectedValue == 1)
                {
                    searchDataSource![section][row]["tempSelected"] = 0
                }
                else
                {
                    searchDataSource![section][row]["tempSelected"] = 1
                }
                let selecteduserId =  searchDataSource![section][row][nameKey] as! String
                for j in 0 ..< dataSource![section].count
                {
                    if j < dataSource![section].count
                    {
                        let dataSourceUserId = dataSource![section][j][nameKey] as! String
                        if(selecteduserId == dataSourceUserId)
                        {
                            dataSource![section][j]["tempSelected"] = searchDataSource![section][row]["tempSelected"]
                        }
                    }
                }
            }
        }
        else
        {
            if dataSource![section].count > row
            {
                let selectedValue =  dataSource![section][row]["tempSelected"] as! Int
                if(selectedValue == 1){
                    dataSource![section][row]["tempSelected"] = 0
                }
                else{
                    dataSource![section][row]["tempSelected"] = 1
                }
            }
        }
        contactTableView.reloadData()
    }
}

extension ContactDetailsViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "contactHeaderTableViewCell") as! contactHeaderTableViewCell
        
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactTableViewCell", for:indexPath) as! contactTableViewCell
        
        var cellDataSource:[String:Any]?
        var datasourceTmp: [[[String:Any]]]?
        
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
        }
        
        if let cellDataSource = cellDataSource
        {
            cell.contactProfileName.text = cellDataSource[nameKey] as? String
            cell.contactProfileImage.image = cellDataSource[imageKey] as? UIImage
            cell.contactSelectionButton.tag = indexPath.row
            cell.section = indexPath.section
            
            let selectionValue : Int = cellDataSource["tempSelected"] as! Int
            if(selectionValue == 1){
                cell.contactSelectionButton.setImage(UIImage(named:"CheckOn"), for:.normal)
            }
            else{
                cell.contactSelectionButton.setImage(UIImage(named:"red-circle"), for:.normal)
            }
            
            cell.selectionStyle = .none
            return cell
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadData()
        
    }
}

extension ContactDetailsViewController: UISearchBarDelegate{
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
        contactTableView.reloadData()
        contactTableView.layoutIfNeeded()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchDataSource?.removeAll()
        var searchContactDataSource:[[String:Any]] = [[String:Any]]()
        var searchAppContactsArr: [[String:Any]] = [[String:Any]]()
        searchContactDataSource.removeAll()
        searchAppContactsArr.removeAll()
        
        if contactSearchBar.text!.isEmpty
        {
            searchDataSource = dataSource
            contactSearchBar.resignFirstResponder()
            self.contactTableView.reloadData()
        }
        else{
            if dataSource![0].count > 0
            {
                for element in dataSource![0]{
                    let tmp: String = (element["user_name"] as! String).lowercased()
                    if(tmp.range(of: searchText.lowercased()) != nil)
                    {
                        searchAppContactsArr.append(element)
                    }
                }
            }
            if dataSource![1].count > 0
            {
                for element in dataSource![1]{
                    let tmp: String = (element["user_name"] as! String).lowercased()
                    if(tmp.range(of: searchText.lowercased()) != nil)
                    {
                        searchContactDataSource.append(element)
                    }
                }
            }
            searchDataSource = [searchAppContactsArr, searchContactDataSource]
            searchActive = true
            self.contactTableView.reloadData()
        }
    }
}
