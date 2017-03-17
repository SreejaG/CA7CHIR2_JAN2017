
import UIKit
import Foundation
import CoreLocation

class SignUpVerifyPhoneViewController: UIViewController
{
    var email: String!
    var userName: String!
    var countryName: String!
    var CountryPhoneCode: String!
    
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    let defaults = UserDefaults.standard
    
    static let identifier = "SignUpVerifyPhoneViewController"
    var verificationCode = ""
    
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var mobileNumberTextField: UITextField!
    @IBOutlet weak var continueBottomConstraint: NSLayoutConstraint!
    @IBOutlet var countryPicker: CountryPicker!
    @IBOutlet var countrySelectionButton: UIButton!
    @IBOutlet var continuButton: UIButton!
    
    @IBAction func selectCountryCode(_ sender: Any) {
        initialiseCountryPicker()
    }
    
    @IBOutlet weak var topConstaintDescriptionLabel: NSLayoutConstraint!
    @IBOutlet var countryCodeTextField: UITextField!
    @IBOutlet weak var verificationCodeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
        if #available(iOS 10.0, *){
            countryPicker.selectRow(232, inComponent: 0, animated: true)
        }
        else{
            countryPicker.selectRow(230, inComponent: 0, animated: true)
        }
        continuButton.isHidden = true
        initialiseCountryPicker()
        initialise()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
        checkVerificationCodeVisiblty()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        if((userName == "invalid") && (email == "invalid"))
        {
            self.title = ""
        }
        else{
            self.title = "VERIFY PHONE #"
        }
        
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        countryTextField.attributedPlaceholder = NSAttributedString(string: "Country",
                                                                    attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        mobileNumberTextField.attributedPlaceholder = NSAttributedString(string: "Mobile Number",
                                                                         attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        countryCodeTextField.attributedPlaceholder = NSAttributedString(string: "Code",
                                                                        attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        verificationCodeTextField.attributedPlaceholder = NSAttributedString(string: "Verification Code",
                                                                             attributes:[NSForegroundColorAttributeName: UIColor.lightGray,NSFontAttributeName: UIFont.italicSystemFont(ofSize: 14.0)])
        verificationCodeTextField.keyboardType = .decimalPad
        
        countryPicker.countryPhoneCodeDelegate = self
        countryTextField.isUserInteractionEnabled = false
        countryCodeTextField.isUserInteractionEnabled = true
        verificationCodeTextField.isHidden = true
        verificationCode = ""
        mobileNumberTextField.delegate = self
        countryCodeTextField.delegate = self
        verificationCodeTextField.delegate = self
        countryTextField.autocorrectionType = .no
        mobileNumberTextField.autocorrectionType = .no
        countryCodeTextField.autocorrectionType = .no
        verificationCodeTextField.autocorrectionType = .no
        
        countryTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        countryCodeTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        mobileNumberTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        verificationCodeTextField.addTarget(self, action: #selector(self.verificationTextChange), for: .editingChanged)
        
        addObserver()
    }
    
    func initialiseCountryPicker()  {
        self.countryPicker.isHidden = false
        countryCodeTextField.resignFirstResponder()
        mobileNumberTextField.resignFirstResponder()
        verificationCodeTextField.resignFirstResponder()
        countryName = "United States"
        self.countryTextField.text = "US" + " - " + "United States"
        self.countryCodeTextField.text = "+1"
        CountryPhoneCode = "+1"
    }
    
    func textFieldDidChange(_ textField: UITextField)
    {
        if(countryTextField.text!.isEmpty || countryCodeTextField.text!.isEmpty || mobileNumberTextField.text!.isEmpty)
        {
            continuButton.isHidden = true
        }
        else if((countryCodeTextField.text?.characters.count)! < 2)
        {
            continuButton.isHidden = true
        }
        else if((mobileNumberTextField.text?.characters.count)! < 4)
        {
            continuButton.isHidden = true
        }
        else{
            continuButton.isHidden = false
        }
    }
    
    func verificationTextChange(_ textField: UITextField)
    {
        countryPicker.isHidden = true
        if(verificationCodeTextField.text!.isEmpty)
        {
            continuButton.isHidden = true
        }
        else if(verificationCodeTextField.text?.characters.count != 6)
        {
            continuButton.isHidden = true
        }
        else
        {
            continuButton.isHidden = false
        }
    }
    
    func checkVerificationCodeVisiblty()
    {
        if verificationCode != ""
        {
            countryPicker.isHidden = true
            countryTextField.isEnabled = false
            mobileNumberTextField.isEnabled = false
            countrySelectionButton.isEnabled = false
            countryCodeTextField.enablesReturnKeyAutomatically = false
            verificationCodeTextField.isHidden = false
            mobileNumberTextField.resignFirstResponder()
            verificationCodeTextField.becomeFirstResponder()
            topConstaintDescriptionLabel.constant = 67
        }
        else
        {
            verificationCodeTextField.isHidden = true
            topConstaintDescriptionLabel.constant = 1
        }
    }
    
    func addObserver()
    {
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(SignUpVerifyPhoneViewController.keyboardDidShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(SignUpVerifyPhoneViewController.KeyboardDidHide),
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
    
    //PRAGMA MARK:- IBActions
    @IBAction func tapGestureRecognized(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func verifyPhoneContinueButtonClicked(_ sender: Any)
    {
        if(verificationCode != ""){
            if((userName == "invalid") && (email == "invalid"))
            {
                loadForgotPasswordView()
            }
            else{
                let deviceToken = defaults.value(forKey: "deviceToken") as! String
                let gcmRegId = "ios".appending(deviceToken)
                validateVerificationCode(userName: userName , verificationCode: verificationCodeTextField.text! , gcmRegId: gcmRegId)
            }
        }
        else{
            if((userName == "invalid") && (email == "invalid")){
                continuButton.isHidden = true
                view.endEditing(true)
                generateWaytoSendAlertForResetPassword()
            }
            else{
                continuButton.isHidden = true
                view.endEditing(true)
                generateWaytoSendAlert()
            }
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
    
    
    func  loadForgotPasswordView(){
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let verifyPhoneVC = storyboard.instantiateViewController(withIdentifier: ForgotPasswordViewController.identifier) as! ForgotPasswordViewController
        verifyPhoneVC.verificationCode = verificationCodeTextField.text!
        verifyPhoneVC.mobileNumber = countryCodeTextField.text! + mobileNumberTextField.text!
        self.present(verifyPhoneVC, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
    
    func generateWaytoSendAlert()
    {
        let alert = UIAlertController(title: "We will send a verification code to" + self.countryCodeTextField.text! + self.mobileNumberTextField.text!, message: "Enter the verification code to finish", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Send to SMS", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.generateVerificationCode(userName: self.userName, location: self.countryName, mobileNumber: self.countryCodeTextField.text! + self.mobileNumberTextField.text!, verificationMethod: "sms")
        }))
        alert.addAction(UIAlertAction(title: "Send to Email", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.generateVerificationCode(userName: self.userName, location: self.countryName, mobileNumber: self.countryCodeTextField.text! + self.mobileNumberTextField.text!, verificationMethod: "email")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            self.continuButton.isHidden = false
            self.mobileNumberTextField.becomeFirstResponder()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func generateWaytoSendAlertForResetPassword()
    {
        let alert = UIAlertController(title: "We will send a verification code to" + self.countryCodeTextField.text! + self.mobileNumberTextField.text!, message: "Enter the verification code to finish", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Send to SMS", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.generateVerificationCodeForResetPassword(mobileNumber: self.countryCodeTextField.text! + self.mobileNumberTextField.text!)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            self.continuButton.isHidden = false
            self.mobileNumberTextField.becomeFirstResponder()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func generateVerificationCodeForResetPassword(mobileNumber: String)
    {
        showOverlay()
        authenticationManager.generateVerificationCodeForResetPassword(mobileNumber: mobileNumber, success: { (response) in
            self.authenticationSuccessHandler(response: response)
        }) { (error, message) in
            self.authenticationFailureHandler(error: error, code: message)
            return
        }
    }
    
    func generateVerificationCode(userName: String, location: String, mobileNumber: String, verificationMethod: String)
    {
        showOverlay()
        let userCountryCode = self.countryCodeTextField.text
        let timeOffset = NSTimeZone.system.secondsFromGMT()
        let timeOffsetStr = String(describing: timeOffset)
        var timeZoneOffsetInUTC : String = String()
        if timeOffsetStr.hasPrefix("-")
        {
            timeZoneOffsetInUTC = timeOffsetStr
        }
        else
        {
            timeZoneOffsetInUTC = "+\(timeOffsetStr)"
        }
        
        authenticationManager.generateVerificationCodes(userName: userName, location: location, mobileNumber: mobileNumber, verificationMethod: verificationMethod, offset: timeZoneOffsetInUTC, countryCode: userCountryCode!, success: { (response) -> () in
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
            var status: Int!
            status = json["status"] as! Int
            if(status >= 1)
            {
                verificationCode = "exist"
                checkVerificationCodeVisiblty()
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
        self.continuButton.isHidden = false
        self.mobileNumberTextField.becomeFirstResponder()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false
        {
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
    
    func validateVerificationCode(userName: String, verificationCode: String, gcmRegId: String)
    {
        showOverlay()
        authenticationManager.validateVerificationCode(userName: userName, verificationCode: verificationCode, gcmRegId: gcmRegId, success: { (response) -> () in
            self.authenticationSuccessHandlerVerification(response: response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error: error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandlerVerification(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            var status: Int!
            status = json["status"] as! Int
            if(status >= 1)
            {
                verificationCode = ""
                if let tocken = json["token"]
                {
                    defaults.setValue(tocken, forKey: userAccessTockenKey)
                }
                if let bucketName = json["BucketName"]
                {
                    defaults.setValue(bucketName, forKey: userBucketName)
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
                loadFindFriendsView()
            }
        }
        else
        {
            removeOverlay()
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    func loadFindFriendsView()
    {
        let storyboard = UIStoryboard(name:"Authentication" , bundle: nil)
        let findFriendsVC = storyboard.instantiateViewController(withIdentifier: SignUpFindFriendsViewController.identifier) as! SignUpFindFriendsViewController
        findFriendsVC.phoneCode = CountryPhoneCode
        self.present(findFriendsVC, animated: false, completion: nil)
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
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

extension SignUpVerifyPhoneViewController:UITextFieldDelegate{
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        textField.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.countryPicker.isHidden = true
        return true
    }
}

extension SignUpVerifyPhoneViewController:CountryPhoneCodePickerDelegate{
    func countryPhoneCodePicker(_ picker: CountryPicker, didSelectCountryCountryWithName name: String, countryCode: String, phoneCode: String) {
        countryName = name
        self.countryTextField.text = countryCode + " - " + name
        self.countryCodeTextField.text = phoneCode
        CountryPhoneCode = phoneCode
    }
}
