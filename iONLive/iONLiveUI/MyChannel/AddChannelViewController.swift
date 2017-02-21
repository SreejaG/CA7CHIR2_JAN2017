
import UIKit

class AddChannelViewController: UIViewController {
    
    static let identifier = "AddChannelViewController"
    
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var channelCreateButton: UIView!
    @IBOutlet var channelTextField: UITextField!
    @IBOutlet var addChannelTableView: UITableView!
    
    var userId : String!
    var accessToken : String!
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var addChannelView: UIView!
    @IBOutlet var addToChannelTitleLabel: UILabel!
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    var shareFlag : Bool = true
    var loadingOverlay: UIView?
    
    var selectedChannelId:String!
    
    var channelSelected: NSMutableArray = NSMutableArray()
    var fulldataSource:[[String:Any]] = [[String:Any]]()
    
    var localMediaDict : [[String:Any]] = [[String:Any]]()
    var localChannelDict : [[String:Any]] = [[String:Any]]()
    
    var mediaDetailSelected : NSMutableArray = NSMutableArray()
    var selectedArray:[Int] = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        addToChannelTitleLabel.text = "ADD TO CHANNEL"
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    func addKeyboardObservers()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(AddChannelViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(AddChannelViewController.keyboardDidHide),
                                               name: NSNotification.Name.UIKeyboardDidHide,
                                               object: nil)
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        if tableViewBottomConstraint.constant == 0
        {
            self.tableViewBottomConstraint.constant = self.tableViewBottomConstraint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableViewBottomConstraint.constant != 0
        {
            self.tableViewBottomConstraint.constant = 0
        }
    }
    
    func initialise()
    {
        channelSelected.removeAllObjects()
        selectedArray.removeAll()
        
        doneButton.isHidden = true
        shareFlag = true
        channelCreateButton.isHidden = true
        
        channelTextField.addTarget(self, action: #selector(AddChannelViewController.textFieldDidChange), for: .editingChanged)
        
        addChannelView.isUserInteractionEnabled = true
        addChannelView.alpha = 1
        addToChannelTitleLabel.text = "ADD TO CHANNEL"
        
        let defaults = UserDefaults.standard
        userId = defaults.value(forKey: userLoginIdKey) as! String
        accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        
        setChannelDetailsDummy()
    }
    
    func setChannelDetailsDummy()
    {
        fulldataSource.removeAll()
        let defaults = UserDefaults.standard
        let archiveChanelId = "\(defaults.value(forKey: archiveId) as! Int)"
        for element in GlobalDataChannelList.sharedInstance.globalChannelDataSource{
            let channelId = element[MyChannelIdKey] as! String
            if((channelId != selectedChannelId) && (channelId != archiveChanelId))
            {
                fulldataSource.append(element)
            }
            addChannelTableView.reloadData()
        }
    }
    
    func textFieldDidChange(_ textField: UITextField)
    {
        if let text = textField.text, !text.isEmpty
        {
            if(text.characters.count >= 3)
            {
                channelCreateButton.isHidden = false
            }
            else
            {
                channelCreateButton.isHidden = true
            }
        }
    }
    
    @IBAction func didTapCancelButon(_ sender: Any){
        if(shareFlag == false){
            shareFlag = true
            addChannelView.isUserInteractionEnabled = true
            addChannelView.alpha = 1
            doneButton.isHidden = true
            addToChannelTitleLabel.text = "ADD TO CHANNEL"
            selectedArray.removeAll()
            addChannelTableView.reloadData()
        }
        else{
            let storyboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let channelVC = storyboard.instantiateViewController(withIdentifier: MyChannelViewController.identifier) as! MyChannelViewController
            channelVC.navigationController?.isNavigationBarHidden = true
            self.navigationController?.pushViewController(channelVC, animated: false)
        }
    }
    
    @IBAction func didTapGestureRecognizer(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func didTapCreateButton(_ sender: Any) {
        if((channelTextField.text?.characters.count)! > 15){
            channelTextField.resignFirstResponder()
            channelTextField.text = ""
            channelCreateButton.isHidden = true
            ErrorManager.sharedInstance.InvalidChannelEnteredError()
        }
        else{
            let channelname: String = channelTextField.text!
            channelTextField.text = ""
            channelCreateButton.isHidden = true
            channelTextField.resignFirstResponder()
            addChannelDetails(userName: userId, token: accessToken, channelName: channelname)
        }
    }
    
    func addChannelDetails(userName: String, token: String, channelName: String)
    {
        showOverlay()
        channelManager.addChannelDetails(userName: userName, accessToken: token, channelName: channelName, success: { (response) -> () in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandler(response:Any?)
    {
        removeOverlay()
        if let json = response as? [String: Any]
        {
            channelTextField.text = ""
            let channelId = String(json["channelId"] as! Int)
            let channelName = json["channelName"] as! String
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
            let localDateStr = dateFormatter.string(from: NSDate() as Date)
            
            GlobalDataChannelList.sharedInstance.globalChannelDataSource.insert([MyChannelIdKey:channelId, channelNameKey:channelName, totalMediaKey:"0", ChannelCreatedTimeKey: localDateStr,sharedOriginalKey:1, sharedTemporaryKey:1], at: 0)
            
            let imageData = [[String:AnyObject]]()
            GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.updateValue(imageData, forKey: channelId)
            
            fulldataSource.insert([MyChannelIdKey:channelId, channelNameKey:channelName, totalMediaKey:"0", ChannelCreatedTimeKey: localDateStr,sharedOriginalKey:1, sharedTemporaryKey:1], at: 0)
            
            addChannelTableView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    @IBAction func didTapDoneButton(_ sender: Any) {
        localChannelDict.removeAll()
        for i in 0 ..< selectedArray.count
        {
            if(i < selectedArray.count)
            {
                let channelSelectedId = fulldataSource[selectedArray[i]][MyChannelIdKey] as! String
                localChannelDict.append(fulldataSource[selectedArray[i]])
                channelSelected.add(channelSelectedId)
            }
        }
        if channelSelected.count > 0
        {
            addMediaToChannels(channelIds: channelSelected, mediaIds: mediaDetailSelected)
        }
    }
    
    func addMediaToChannels(channelIds:NSArray, mediaIds:NSArray){
        let defaults = UserDefaults .standard
        let userId = defaults.value(forKey: userLoginIdKey) as! String
        let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        showOverlay()
        imageUploadManger.addMediaToChannel(userName: userId, accessToken: accessToken, mediaIds: mediaIds, channelId: channelIds, success: { (response) -> () in
            self.authenticationSuccessHandlerAdd(response: response,channelIds: channelIds,mediaIds: mediaIds)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerAdd(response : AnyObject?, channelIds:NSArray, mediaIds:NSArray)
    {
        GlobalChannelToImageMapping.sharedInstance.addMediaToChannel(channelSelectedDict: localChannelDict, mediaDetailOfSelectedChannel: localMediaDict)
        
        removeOverlay()
        if (response as? [String: AnyObject]) != nil
        {
            channelTextField.text = ""
            let storyboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let channelVC = storyboard.instantiateViewController(withIdentifier: MyChannelViewController.identifier) as! MyChannelViewController
            channelVC.navigationController?.isNavigationBarHidden = true
            self.navigationController?.pushViewController(channelVC, animated: false)
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code: code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
        if(shareFlag == false){
            shareFlag = true
            addChannelView.isUserInteractionEnabled = true
            addChannelView.alpha = 1
            doneButton.isHidden = true
            addToChannelTitleLabel.text = "ADD TO CHANNEL"
            selectedArray.removeAll()
            addChannelTableView.reloadData()
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
}

extension AddChannelViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if fulldataSource.count > 0
        {
            return fulldataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if fulldataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: AddChannelCell.identifier, for:indexPath) as! AddChannelCell
            
            cell.addChannelTextLabel.text = fulldataSource[indexPath.row][channelNameKey] as? String
            cell.addChannelCountLabel.text = fulldataSource[indexPath.row][totalMediaKey] as? String
            
            if let latestImage = fulldataSource[indexPath.row][tImageKey]
            {
                cell.addChannelImageView.image = latestImage as? UIImage
            }
            else
            {
                cell.addChannelImageView.image = UIImage(named: "thumb12")
            }
            
            if(fulldataSource[indexPath.row][totalMediaKey] as! String == "0"){
                cell.addChannelImageView.image = UIImage(named: "thumb12")
            }
            
            if(selectedArray.contains(indexPath.row)){
                cell.accessoryType = .checkmark
            }
            else{
                cell.accessoryType = .none
            }
            
            cell.selectionStyle = .none
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        shareFlag = false
        
        if(selectedArray.contains(indexPath.row)){
            let elementIndex = selectedArray.index(of: indexPath.row)
            selectedArray.remove(at: elementIndex!)
        }
        else{
            selectedArray.append(indexPath.row)
        }
        if(selectedArray.count <= 0){
            addChannelView.isUserInteractionEnabled = true
            addChannelView.alpha = 1.0
            doneButton.isHidden = true
        }
        else{
            addChannelView.isUserInteractionEnabled = false
            addChannelView.alpha = 0.4
            doneButton.isHidden = false
        }
        tableView.reloadData()
    }
}



