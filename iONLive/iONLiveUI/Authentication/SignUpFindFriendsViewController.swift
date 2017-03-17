
import AddressBook
import AddressBookUI
import UIKit

class SignUpFindFriendsViewController: UIViewController{
    
    private var addressBookRef: ABAddressBook?
    
    func setAddressBook(addressBook: ABAddressBook) {
        addressBookRef = addressBook
    }
    
    static let identifier = "SignUpFindFriendsViewController"
    
    let requestManager = RequestManager.sharedInstance
    let contactManagers = contactManager.sharedInstance
    var phoneCode: String!
    var dataSource:[[String:Any]] = [[String:Any]]()
    var contactPhoneNumbers: [String] = [String]()
    let nameKey = "user_name"
    let phoneKey = "mobile_no"
    let imageKey = "profile_image"
    let inviteKey = "invitationKey"
    var loadingOverlay: UIView?
    var contactExist: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "FIND FRIENDS"
        let addressBookRef1 = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAddressBook(addressBook: addressBookRef1)
    }
    
    @IBAction func continueButtonClicked(_ sender: Any) {
        contactAuthorizationAlert()
    }
        
    func contactAuthorizationAlert()
    {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        switch authorizationStatus {
        case .denied, .restricted:
            generateContactSynchronizeAlert()
        case .authorized:
            displayContacts()
        case .notDetermined:
            promptForAddressBookRequestAccess()
        }
    }
    
    func generateContactSynchronizeAlert()
    {
        let alert = UIAlertController(title: "\"Catch\" would like to access your contacts", message: "The contacts in your address book will be transmitted to Catch for you to decide who to add", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.loadCameraViewController()
        }))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.showEventsAcessDeniedAlert()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func promptForAddressBookRequestAccess() {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, { granted, error in              DispatchQueue.main.async {
            if !granted {
                self.generateContactSynchronizeAlert()
            } else {
                self.displayContacts()
            }
            }
        })
    }
    
    func displayContacts(){
        showOverlay()
        contactPhoneNumbers.removeAll()
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
                    phoneNumberWithCode = phoneCode.appending(subStr)
                }
                else if(phoneNumberStr.hasPrefix("0")){
                    let stringLength = phoneNumberStr.characters.count
                    let subStr = (phoneNumberStr as NSString).substring(with: NSRange(location: 1, length: stringLength - 1))
                    phoneNumberWithCode = phoneCode.appending(subStr)
                }
                else{
                    phoneNumberWithCode = phoneCode.appending(phoneNumberStr)
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
                contactPhoneNumbers.append(phoneNumber)
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
                
                self.dataSource.append([self.nameKey: currentContactName, self.phoneKey: phoneNumber, self.imageKey: currentContactImage, "orgSelected":0, "tempSelected":0])
            }
        }
        addContactDetails(contactPhoneNumbers: contactPhoneNumbers as NSArray)
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
        present(alertController, animated: true, completion: nil)
    }
    
    func addContactDetails(contactPhoneNumbers: NSArray)
    {
        let defaults = UserDefaults.standard
        let userId = defaults.value(forKey: userLoginIdKey) as! String
        let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        contactManagers.addContactDetails(userName: userId, accessToken: accessToken, userContacts: contactPhoneNumbers, success:  { (response) -> () in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            var status: Int!
            status = json["status"] as! Int
            if(status >= 1)
            {
                contactExist = true
                loadContactViewController()
            }
        }
        else
        {
            ErrorManager.sharedInstance.addContactError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if code == "CONTACT002" {
                contactExist = false
                loadContactViewController()
            }
            else{
                if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                }
                else{
                    ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
                    if code == "CONTACT001"{
                        contactExist = false
                        loadContactViewController()
                    }
                }
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
    
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewController(withContentPath: "rtsp://\(vowzaIp):1935/live", parameters: nil , liveVideo: true) as! UIViewController
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        vc.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    func loadCameraViewController()
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewController(withIdentifier: "IPhoneCameraViewController") as! IPhoneCameraViewController
       self.present(iPhoneCameraViewController, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
    
    func loadContactViewController()
    {
        removeOverlay()
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let contactDetailsViewController = storyboard.instantiateViewController(withIdentifier: "ContactDetailsViewController") as! ContactDetailsViewController
        contactDetailsViewController.contactDataSource = dataSource
        contactDetailsViewController.contactExistChk = contactExist
        self.present(contactDetailsViewController, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
}
