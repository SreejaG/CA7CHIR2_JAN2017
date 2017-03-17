
import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userNameTextfield: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInBottomConstraint: NSLayoutConstraint!
    @IBOutlet var loginButton: UIButton!
    
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
        loginButton.isHidden = true
        
        UserDefaults.standard.setValue("true", forKey: "tokenValid")
        
        initialise()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
        self.userNameTextfield.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "LOG IN"
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        userNameTextfield.attributedPlaceholder = NSAttributedString(string: "Username",
                                                                     attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                     attributes:[NSForegroundColorAttributeName: UIColor.lightGray ,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        userNameTextfield.autocorrectionType = UITextAutocorrectionType.no
        passwordTextField.autocorrectionType = UITextAutocorrectionType.no
        passwordTextField.isSecureTextEntry = true
        userNameTextfield.delegate = self
        passwordTextField.delegate = self
        
        userNameTextfield.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        
        addObserver()
    }
    
    func addObserver()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(LoginViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(LoginViewController.KeyboardDidHide),
                                               name: NSNotification.Name.UIKeyboardDidHide,
                                               object: nil)
    }
    
    func textFieldDidChange(_ textField: UITextField)
    {
        if(userNameTextfield.text!.isEmpty || passwordTextField.text!.isEmpty)
        {
            loginButton.isHidden = true
        }
        else{
            let whiteChrSet = NSCharacterSet.whitespaces
            let decimalChrSet = NSCharacterSet.decimalDigits
            
            if(((userNameTextfield.text?.characters.count)! < 5) || ((userNameTextfield.text?.characters.count)! > 15))
            {
                loginButton.isHidden = true
            }
            else if (userNameTextfield.text! as String).rangeOfCharacter(from: whiteChrSet) != nil
            {
                loginButton.isHidden = true
            }
            else if(((passwordTextField.text?.characters.count)! < 8) || ((passwordTextField.text?.characters.count)! > 40))
            {
                loginButton.isHidden = true
            }
            else if (passwordTextField.text! as String).rangeOfCharacter(from: decimalChrSet) == nil
            {
                loginButton.isHidden = true
            }
            else{
                loginButton.isHidden = false
            }
        }
    }
    
    //PRAGMA MARK:- keyboard notification handler
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.view.layoutIfNeeded()
        if logInBottomConstraint.constant == 0
        {
            UIView.animate(withDuration: 1.0) { () -> Void in
                self.logInBottomConstraint.constant += keyboardFrame.size.height
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        self.view.layoutIfNeeded()
        if logInBottomConstraint.constant != 0
        {
            UIView.animate(withDuration: 1.0) { () -> Void in
                self.logInBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func forgetPasswordClicked(_ sender: Any)
    {
        loadVerifyPhoneView()
    }
    
    func loadVerifyPhoneView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let verifyPhoneVC = storyboard.instantiateViewController(withIdentifier: SignUpVerifyPhoneViewController.identifier) as! SignUpVerifyPhoneViewController
        verifyPhoneVC.email = "invalid"
        verifyPhoneVC.userName = "invalid"
        self.present(verifyPhoneVC, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
    
    @IBAction func tapGestureRecognized(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func loginClicked(_ sender: Any)
    {
        if let deviceToken = defaults.value(forKey: "deviceToken")
        {
            let gcmRegId = ("ios" ).appending(deviceToken as! String)
            
            self.loginUser(email: self.userNameTextfield.text!, password: self.passwordTextField.text!, gcmRegistrationId: gcmRegId, withLoginButton: true)
        }
        else{
            if !self.requestManager.validConnection() {
                ErrorManager.sharedInstance.noNetworkConnection()
            }
            else{
                ErrorManager.sharedInstance.installFailure()
            }
        }
    }
    
    @IBAction func backClicked(_ sender: Any){
        guard (navigationController?.popViewController(animated:true)) != nil
            else
        {
            dismiss(animated: true, completion: nil)
            return
        }
    }
    
    //Loading Overlay Methods
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
    
    //PRAGMA MARK:- API handlers
    func loginUser(email: String, password: String, gcmRegistrationId: String, withLoginButton: Bool)
    {
        showOverlay()
        authenticationManager.authenticate(email: email, password: password, gcmRegId: gcmRegistrationId, success: { (response) -> () in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        self.passwordTextField.text = ""
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            clearStreamingUserDefaults(defaults: defaults)
            if let tocken = json["token"]
            {
                defaults.setValue(tocken, forKey: userAccessTockenKey)
            }
            if let userId = json["user"]
            {
                defaults.setValue(userId, forKey: userLoginIdKey)
            }
            if let code = json["countryCode"]
            {
                defaults.setValue(code, forKey: "countryCode")
            }
            if let code = json["archiveId"]
            {
                defaults.setValue(code, forKey: archiveId)
                
            }
            if let code = json["totalMediaInArchive"]
            {
                defaults.setValue(code, forKey:ArchiveCount)
            }
            UserDefaults.standard.setValue("initialCall", forKey: "CallingAPI")
            UserDefaults.standard.setValue("0", forKey: "notificationArrived")
            GlobalDataChannelList.sharedInstance.initialise()
            ChannelSharedListAPI.sharedInstance.initialisedata()
            loadCameraViewController()
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    func clearStreamingUserDefaults(defaults:UserDefaults)
    {
        defaults.removeObject(forKey: streamingToken)
        defaults.removeObject(forKey: startedStreaming)
        defaults.removeObject(forKey: initializingStream)
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
            }
        }
        else{
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewController(withContentPath: "rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! UIViewController
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    func loadCameraViewController()
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewController(withIdentifier: "IPhoneCameraViewController") as! IPhoneCameraViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = iPhoneCameraViewController
        self.present(iPhoneCameraViewController, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
}

extension LoginViewController:UITextFieldDelegate{
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        textField.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}

