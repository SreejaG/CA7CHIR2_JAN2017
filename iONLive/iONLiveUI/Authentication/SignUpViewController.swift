//
//  SignUpViewController.swift
//  iONLive
//
//  Created by Gadgeon on 11/30/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwdTextField: UITextField!
    @IBOutlet weak var signUpBottomConstraint: NSLayoutConstraint!

    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "SIGN UP"
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        emailTextfield.attributedPlaceholder = NSAttributedString(string: "Email address",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        passwdTextField.attributedPlaceholder = NSAttributedString(string: "New Password",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor() ,NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        emailTextfield.autocorrectionType = UITextAutocorrectionType.No
        passwdTextField.autocorrectionType = UITextAutocorrectionType.No
        passwdTextField.secureTextEntry = true
        addObserver()
    }
  
    func addObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name:UIKeyboardDidShowNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "KeyboardDidHide:", name:UIKeyboardWillHideNotification , object: nil)
    }
    
    //PRAGMA MARK:- keyboard notification handler
    
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if signUpBottomConstraint.constant == 0
        {
            signUpBottomConstraint.constant += keyboardFrame.size.height
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if signUpBottomConstraint.constant != 0
        {
            signUpBottomConstraint.constant -= keyboardFrame.size.height
        }
    }
    
    // PRAGMA MARK:- textField delegates
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    //PRAGMA MARK:- IBActions
    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func signUpClicked(sender: AnyObject)
    {
        if emailTextfield.text!.isEmpty
        {
            ErrorManager.sharedInstance.loginNoEmailEnteredError()
        }
        else if passwdTextField.text!.isEmpty
        {
            ErrorManager.sharedInstance.loginNoPasswordEnteredError()
        }
        else
        {
            self.signUpUser(self.emailTextfield.text!, password: self.passwdTextField.text!, withLoginButton: true)
        }
    }
    
    
    //PRAGMA MARK:- Helper functions
    
    func isEmail(email:String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive)
        return regex?.firstMatchInString(email, options: [], range: NSMakeRange(0, email.characters.count)) != nil
    }
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    
    //PRAGMA MARK:- API handlers
    func signUpUser(email: String, password: String, withLoginButton: Bool)
    {
        //check for valid email
        let isEmailValid = isEmail(email) as Bool!
        if isEmailValid == false
        {
            ErrorManager.sharedInstance.loginInvalidEmail()
            return
        }
        
        //authenticate through authenticationManager
        showOverlay()
        authenticationManager.signUp(email: email, password: password, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, message: message)
                return
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        self.passwdTextField.text = ""
        self.removeOverlay()
        loadLiveStreamView()
        if let json = response as? [String: AnyObject]
        {
            let defaults = NSUserDefaults .standardUserDefaults()
            print("success = \(json["status"]),\(json["token"]),\(json["user"])")
            if let tocken = json["token"]
            {
                defaults.setValue(tocken, forKey: userAccessTockenKey)
            }
            if let userId = json["user"]
            {
                defaults.setValue(userId, forKey: userLoginIdKey)
            }
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }
        
    }
    
    func authenticationFailureHandler(error: NSError?, message: String)
    {
        self.removeOverlay()
        print("message = \(message) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if message.isEmpty == false {
            ErrorManager.sharedInstance.alert("Login Error", message:message)
        }
        else{
            ErrorManager.sharedInstance.signUpError()
        }
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! UIViewController
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        vc.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(vc, animated: false)
    }

}