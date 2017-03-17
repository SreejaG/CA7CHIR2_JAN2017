
import UIKit

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwdTextField: UITextField!
    @IBOutlet weak var signUpBottomConstraint: NSLayoutConstraint!
    @IBOutlet var continueButton: UIButton!
    
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
        
        continueButton.isHidden = true
        
        UserDefaults.standard.setValue("true", forKey: "tokenValid")
        
        initialise()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
        self.emailTextfield.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "SIGN UP"
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        emailTextfield.attributedPlaceholder = NSAttributedString(string: "Email address",
                                                                  attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        passwdTextField.attributedPlaceholder = NSAttributedString(string: "New Password",
                                                                   attributes:[NSForegroundColorAttributeName: UIColor.lightGray ,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        emailTextfield.autocorrectionType = UITextAutocorrectionType.no
        passwdTextField.autocorrectionType = UITextAutocorrectionType.no
        passwdTextField.isSecureTextEntry = true
        emailTextfield.delegate = self
        passwdTextField.delegate = self
        passwdTextField.tag = 10
        
        emailTextfield.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        passwdTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        
        addObserver()
    }
    
    func addObserver()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(SignUpViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(SignUpViewController.KeyboardDidHide),
                                               name: NSNotification.Name.UIKeyboardDidHide,
                                               object: nil)
    }
    
    //PRAGMA MARK:- keyboard notification handler
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.view.layoutIfNeeded()
        if signUpBottomConstraint.constant == 0
        {
            UIView.animate(withDuration: 1.0) { () -> Void in
                self.signUpBottomConstraint.constant += keyboardFrame.size.height
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        self.view.layoutIfNeeded()
        if signUpBottomConstraint.constant != 0
        {
            UIView.animate(withDuration: 1.0) { () -> Void in
                self.signUpBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func textFieldDidChange(_ textField: UITextField)
    {
        if(emailTextfield.text!.isEmpty || passwdTextField.text!.isEmpty)
        {
            continueButton.isHidden = true
        }
        else{
            let decimalChrSet = NSCharacterSet.decimalDigits
            
            if(isEmail(email: self.emailTextfield.text!) as Bool! == false)
            {
                continueButton.isHidden = true
            }
            else if(((passwdTextField.text?.characters.count)! < 8) || ((passwdTextField.text?.characters.count)! > 40))
            {
                continueButton.isHidden = true
            }
            else if (passwdTextField.text! as String).rangeOfCharacter(from: decimalChrSet) == nil
            {
                continueButton.isHidden = true
            }
            else{
                continueButton.isHidden = false
            }
        }
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func tapGestureRecognized(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func signUpClicked(_ sender: Any)
    {
        loadUserNameView()
    }
    
    @IBAction func backClicked(_ sender: Any){
        guard (navigationController?.popViewController(animated:true)) != nil
            else
        {
            dismiss(animated: true, completion: nil)
            return
        }
    }
    
    func loadUserNameView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let userNameVC = storyboard.instantiateViewController(withIdentifier: SignUpUserNameViewController.identifier) as! SignUpUserNameViewController
        userNameVC.email = self.emailTextfield.text!
        userNameVC.password = self.passwdTextField.text!
        self.present(userNameVC, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
    
    //PRAGMA MARK:- Helper functions
    func isEmail(email:String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .caseInsensitive)
        return regex?.firstMatch(in: email, options: [], range: NSMakeRange(0, email.characters.count)) != nil
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
}

extension SignUpViewController:UITextFieldDelegate{
    
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

