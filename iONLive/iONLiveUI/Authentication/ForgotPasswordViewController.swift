
import UIKit

class ForgotPasswordViewController: UIViewController{
    
    static let identifier = "ForgotPasswordViewController"
    
    @IBOutlet weak var resetPasswdBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var resetButton: UIButton!
    
    var verificationCode : String!
    var mobileNumber : String!
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    @IBOutlet var reEnterPwdText: UITextField!
    @IBOutlet var newPwdText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetButton.isHidden = true
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    func initialise()
    {
        self.title = "RESET PASSWORD"
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        newPwdText.attributedPlaceholder = NSAttributedString(string: "New Password",
                                                              attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        newPwdText.autocorrectionType = UITextAutocorrectionType.no
        
        reEnterPwdText.attributedPlaceholder = NSAttributedString(string: "Re-enter Password",
                                                                  attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        reEnterPwdText.autocorrectionType = UITextAutocorrectionType.no
        newPwdText.becomeFirstResponder()
        newPwdText.isSecureTextEntry = true
        newPwdText.delegate = self
        reEnterPwdText.isSecureTextEntry = true
        reEnterPwdText.delegate = self
        
        newPwdText.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        reEnterPwdText.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        
        addObserver()
    }
    
    func addObserver()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(ForgotPasswordViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(ForgotPasswordViewController.KeyboardDidHide),
                                               name: NSNotification.Name.UIKeyboardDidHide,
                                               object: nil)
    }
    
    //PRAGMA MARK:- keyboard notification handler
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.view.layoutIfNeeded()
        if resetPasswdBottomConstraint.constant == 0
        {
            UIView.animate(withDuration: 1.0, animations: { () -> Void in
                self.resetPasswdBottomConstraint.constant += keyboardFrame.size.height
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        self.view.layoutIfNeeded()
        if resetPasswdBottomConstraint.constant != 0
        {
            UIView.animate(withDuration: 1.0, animations: { () -> Void in
                self.resetPasswdBottomConstraint.constant = 0
            })
        }
    }
    
    func textFieldDidChange(_
        textField: UITextField)
    {
        if(newPwdText.text!.isEmpty || reEnterPwdText.text!.isEmpty)
        {
            resetButton.isHidden = true
        }
        else{
            let decimalChrSet = NSCharacterSet.decimalDigits
            
            if(((newPwdText.text?.characters.count)! < 8) || ((newPwdText.text?.characters.count)! > 40))
            {
                resetButton.isHidden = true
            }
            if(((reEnterPwdText.text?.characters.count)! < 8) || ((reEnterPwdText.text?.characters.count)! > 40))
            {
                resetButton.isHidden = true
            }
            else if (newPwdText.text! as String).rangeOfCharacter(from: decimalChrSet) == nil
            {
                resetButton.isHidden = true
            }
            else if (reEnterPwdText.text! as String).rangeOfCharacter(from: decimalChrSet) == nil
            {
                resetButton.isHidden = true
            }
            else{
                resetButton.isHidden = false
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func tapGestureRecognized(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func didTapResetButton(_ sender: Any) {
        let newPaswrd = newPwdText.text
        let confirmPaswrd = reEnterPwdText.text
        if(newPaswrd != confirmPaswrd){
            ErrorManager.sharedInstance.passwordMismatch()
        }
        else{
            showOverlay()
            authenticationManager.resetPassword(mobileNumber: mobileNumber, newPassword: newPaswrd!, verificationCode: verificationCode, success: { (response) in
                self.authenticationSuccessHandler(response: response)
            }, failure: { (error, message) in
                self.authenticationFailureHandler(error: error, code: message)
                return
            })
        }
    }
    
    @IBAction func backClicked(_ sender: Any) {
        guard (navigationController?.popViewController(animated:true)) != nil
            else
        {
            dismiss(animated: true, completion: nil)
            return
        }
    }
    
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                let alert = UIAlertController(title: "", message: "Your password has been changed", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Go To Login Screen", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                    self.loadInitialViewController()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        else
        {
            ErrorManager.sharedInstance.signUpError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
        }
        else{
            ErrorManager.sharedInstance.signUpError()
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
    
    func  loadInitialViewController(){
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
            
            let sharingStoryboard = UIStoryboard(name:"Authentication", bundle: nil)
            let channelItemListVC = sharingStoryboard.instantiateViewController(withIdentifier: "AuthenticateViewController") as! AuthenticateViewController
           self.present(channelItemListVC, animated: false, completion: nil)
            CFRunLoopWakeUp(CFRunLoopGetCurrent());
        }
    }
}

extension ForgotPasswordViewController : UITextFieldDelegate{
    
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
