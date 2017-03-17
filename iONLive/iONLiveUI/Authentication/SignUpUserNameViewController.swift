
import UIKit

class SignUpUserNameViewController: UIViewController {
    
    var email: String!
    var password: String!
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    var loadingOverlay: UIView?
    
    static let identifier = "SignUpUserNameViewController"
    @IBOutlet weak var userNameTextfield: UITextField!
    @IBOutlet weak var continueBottomConstraint: NSLayoutConstraint!
    
    
    @IBOutlet var continuButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        continuButton.isHidden = true
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
        
        initialise()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
        userNameTextfield.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "USERNAME"
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        userNameTextfield.attributedPlaceholder = NSAttributedString(string: "Username",
                                                                     attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        userNameTextfield.autocorrectionType = UITextAutocorrectionType.no
        userNameTextfield.delegate = self
        userNameTextfield.keyboardType = .namePhonePad
        
        userNameTextfield.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        
        addObserver()
    }
    
    func addObserver()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(SignUpUserNameViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(SignUpUserNameViewController
                                                .KeyboardDidHide),
                                               name: NSNotification.Name.UIKeyboardDidHide,
                                               object: nil)
    }
    
    //PRAGMA MARK:- keyboard notification handler
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.view.layoutIfNeeded()
        if continueBottomConstraint.constant == 0
        {
            UIView.animate(withDuration: 1.0) { () -> Void in
                self.continueBottomConstraint.constant += keyboardFrame.size.height
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        self.view.layoutIfNeeded()
        if continueBottomConstraint.constant != 0
        {
            UIView.animate(withDuration: 1.0) { () -> Void in
                self.continueBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func textFieldDidChange(_ textField: UITextField)
    {
        if( userNameTextfield.text!.isEmpty)
        {
            continuButton.isHidden = true
        }
        else{
            let whiteChrSet = NSCharacterSet.whitespaces
            if(((userNameTextfield.text?.characters.count)! < 5) || ((userNameTextfield.text?.characters.count)! > 15))
            {
                continuButton.isHidden = true
            }
            else if (userNameTextfield.text! as String).rangeOfCharacter(from: whiteChrSet) != nil
            {
                continuButton.isHidden = true
            }
            else{
                continuButton.isHidden = false
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func tapGestureRecognized(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func userNameContinueButtonClicked(_ sender: Any)
    {
        signUpUser(email: email, password: password, userName: self.userNameTextfield.text!)
    }
    
    
    @IBAction func backClicked(_ sender: Any) {
        guard (navigationController?.popViewController(animated:true)) != nil
            else
        {
            dismiss(animated: true, completion: nil)
            return
        }
    }
    
    func loadVerifyPhoneView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let verifyPhoneVC = storyboard.instantiateViewController(withIdentifier: SignUpVerifyPhoneViewController.identifier) as! SignUpVerifyPhoneViewController
        verifyPhoneVC.email = email
        verifyPhoneVC.userName = self.userNameTextfield.text
        self.present(verifyPhoneVC, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
    
    func signUpUser(email: String, password: String, userName: String)
    {
        showOverlay()
        authenticationManager.signUp(email: email, password: password, userName: self.userNameTextfield.text!, success: { (response) -> () in
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
            let defaults = UserDefaults.standard
            if let userId = json["user"]
            {
                defaults.setValue(userId, forKey: userLoginIdKey)
            }
            loadVerifyPhoneView()
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
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: code)
            }
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
}

extension SignUpUserNameViewController:UITextFieldDelegate{
    
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

