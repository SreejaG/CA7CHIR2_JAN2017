//
//  UploadStreamViewController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/18/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class UploadStreamViewController: UIViewController {
    static let identifier = "UploadStreamViewController"
    
    @IBOutlet weak var streamingStatuslabel: UILabel!
    @IBOutlet weak var startStreamingButon: UIButton!
    @IBOutlet weak var stopStreamingButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var currentStreamingTocken:String?    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        if let viewController = self.parentViewController?.parentViewController
        {
            let vc:MovieViewController = viewController as! MovieViewController
            vc.initialiseDecoder()
        }
        
    }
    
    func initialize()
    {
        self.title = "LIVE STREAM"

        let defaults = NSUserDefaults .standardUserDefaults()
        let streaming = defaults.boolForKey(startedStreaming)
        if streaming
        {
            streamingStatuslabel.text = "Live Streaming.."
            activityIndicator.hidden = false
            currentStreamingTocken = defaults.valueForKey(streamingToken) as? String
            setStartStreamingButtonEnability(false)
            setStopStreamingButtonEnability(true)
        }
        else
        {
            streamingStatuslabel.hidden = true
            activityIndicator.hidden = true
            currentStreamingTocken = nil
            
            setStartStreamingButtonEnability(true)
            setStopStreamingButtonEnability(false)
        }
    }
    
    //PRAGMA MARK:- button actions
    @IBAction func startStreamingClicked(sender: AnyObject)
    {
        setStartStreamingButtonEnability(false)
        setStopStreamingButtonEnability(true)
        initialiseLiveStreaming()
        
    }

    @IBAction func stopStreamingClicked(sender: AnyObject)
    {
        streamingStatuslabel.hidden = true
        setStartStreamingButtonEnability(false)
        setStopStreamingButtonEnability(false)
        stopLiveStreaming(self.currentStreamingTocken)
    }
    
   //PRAGMA MARK :- API Helper
    
    func initialiseLiveStreaming()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            streamingStatuslabel.hidden = false
            activityIndicator.hidden = false
            streamingStatuslabel.text = "Initializing Live Streaming.."
            
            livestreamingManager.initialiseLiveStreaming(loginId:loginId as! String , tocken:accessTocken as! String, success: { (response) -> () in
                
                if let json = response as? [String: AnyObject]
                {
                    self.currentStreamingTocken = json["streamToken"] as? String
                    print("success = \(json["streamToken"])")
                    //call start stream api here
                    self.startLiveStreaming(self.currentStreamingTocken)
                }
                else
                {
                    self.streamingFailureUIUpdatesHandler()
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                     self.streamingFailureUIUpdatesHandler()
                    
                    print("message = \(message), error = \(error?.localizedDescription)")
                    if !self.requestManager.validConnection() {
                        ErrorManager.sharedInstance.noNetworkConnection()
                    }
                    else if message.isEmpty == false {
                        ErrorManager.sharedInstance.alert("Streaming Error", message:message)
                    }
                    else{
                        ErrorManager.sharedInstance.streamingError()
                    }
                    return
            })
        }
        else
        {
            setStartStreamingButtonEnability(true)
            setStopStreamingButtonEnability(false)
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func startLiveStreaming(streamTocken:String?)
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)

        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            streamingStatuslabel.text = "Starting Live Streaming.."
            livestreamingManager.startLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in
                
                
                
                if let json = response as? [String: AnyObject]
                {
                    print("success = \(json["streamToken"])")
                    let streamToken:String = json["streamToken"] as! String
//                    var baseStream = "rtmp://104.197.159.157:1935/live/"
////                    var baseStream = "rtmp://192.168.16.34:1935/live/"
//                    baseStream.appendContentsOf(streamToken)
//                    print("baseStream\(baseStream)")
                    
//                    let fromServer = "rtsp://192.168.42.1:554/live"
//                    let fromServerPtr = strdup(fromServer.cStringUsingEncoding(NSUTF8StringEncoding)!)
//                    let fromServerName :UnsafeMutablePointer<CChar> = UnsafeMutablePointer(fromServerPtr)
                    
//                    let baseStreamptr = strdup(baseStream.cStringUsingEncoding(NSUTF8StringEncoding)!)
//                    let baseStreamName: UnsafeMutablePointer<CChar> = UnsafeMutablePointer(baseStreamptr)
                    let baseStreamName = self.getBaseStream(streamToken)
                    let cameraServerName = self.getCameraServer()
                    
                    let defaults = NSUserDefaults .standardUserDefaults()
                    defaults.setValue(streamToken, forKey: streamingToken)

                    if (init_streams(cameraServerName, baseStreamName) == 0)
                    {
                        self.streamingStatuslabel.text = "Live Streaming.."
                        defaults.setBool(true, forKey: startedStreaming)
                        print("live streaming")
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
                        {
                                
                                start_stream(baseStreamName)
                        }
                    }
                    else
                    {
                        defaults.setValue(false, forKey: startedStreaming)
                        ErrorManager.sharedInstance.alert("Can't Initialise the stream", message: "Can't Initialise the stream")
                    }
                    
                }
                else
                {
                    self.streamingFailureUIUpdatesHandler()
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                     self.streamingFailureUIUpdatesHandler()
                    
                    print("message = \(message)")
                    
                    if !self.requestManager.validConnection() {
                        ErrorManager.sharedInstance.noNetworkConnection()
                    }
                    else if message.isEmpty == false {
                        ErrorManager.sharedInstance.alert("Streaming Error", message:message)
                    }
                    else{
                        ErrorManager.sharedInstance.streamingError()
                    }
                    return
            })

        }
        else
        {
            self.streamingFailureUIUpdatesHandler()
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func getBaseStream(streamToken:String) -> UnsafeMutablePointer<CChar>
    {
        var baseStream = "rtmp://104.197.159.157:1935/live/"
//      var baseStream = "rtmp://192.168.16.34:1935/live/"
        baseStream.appendContentsOf(streamToken)
        let baseStreamptr = strdup(baseStream.cStringUsingEncoding(NSUTF8StringEncoding)!)
        let baseStreamName: UnsafeMutablePointer<CChar> = UnsafeMutablePointer(baseStreamptr)
        return baseStreamName
    }
    
    func getCameraServer() -> UnsafeMutablePointer<CChar>
    {
        let cameraServer = "rtsp://192.168.42.1:554/live"
        let cameraServerPtr = strdup(cameraServer.cStringUsingEncoding(NSUTF8StringEncoding)!)
        let cameraServerName :UnsafeMutablePointer<CChar> = UnsafeMutablePointer(cameraServerPtr)
        return cameraServerName
    }
    
    func stopLiveStreaming(streamTocken:String?)
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            self.activityIndicator.hidden = false
            livestreamingManager.stopLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in
                
                self.activityIndicator.hidden = true
                if let json = response as? [String: AnyObject]
                {
//                    self.setStartStreamingButtonEnability(true)
//                    self.setStopStreamingButtonEnability(false)
//                    
//                    let defaults = NSUserDefaults .standardUserDefaults()
//                    defaults.setValue(false, forKey: startedStreaming)
//                    stop_stream()
//                    
                    self.stopStreamingandUpdateButton()
                    print("success = \(json["streamToken"])")
                }
                else
                {
                    ErrorManager.sharedInstance.inValidResponseError()
                    self.setStartStreamingButtonEnability(false)
                    self.setStopStreamingButtonEnability(true)
                }
                
                }, failure: { (error, message) -> () in
                    self.setStartStreamingButtonEnability(false)
                    self.setStopStreamingButtonEnability(true)
                    
                    self.activityIndicator.hidden = true
                    print("message = \(message)")
                    
                    if !self.requestManager.validConnection() {
                        ErrorManager.sharedInstance.noNetworkConnection()
                    }
                    else if message.isEmpty == false {
                        ErrorManager.sharedInstance.alert("Streaming Error", message:message)
                    }
                    else{
                        ErrorManager.sharedInstance.streamingError()
                    }
                    return
            })
        }
        else
        {
            self.setStartStreamingButtonEnability(false)
            self.setStopStreamingButtonEnability(true)
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func stopStreamingandUpdateButton()
    {
        self.setStartStreamingButtonEnability(true)
        self.setStopStreamingButtonEnability(false)
        
        let defaults = NSUserDefaults .standardUserDefaults()
        defaults.setValue(false, forKey: startedStreaming)
        stop_stream()
    }
    
// PRAGMA MARK :- Helper functions
    
    func setStartStreamingButtonEnability(enability:Bool)
    {
        if enability
        {
            startStreamingButon.enabled = true
            startStreamingButon.alpha = 1.0
        }
        else
        {
            startStreamingButon.enabled = false
            startStreamingButon.alpha = 5.0
        }
    }
    
    func setStopStreamingButtonEnability(enability:Bool)
    {
        if enability
        {
            stopStreamingButton.enabled = true
            stopStreamingButton.alpha = 1.0
        }
        else
        {
            stopStreamingButton.enabled = false
            stopStreamingButton.alpha = 5.0
        }
    }
    
    func streamingFailureUIUpdatesHandler()
    {
        self.activityIndicator.hidden = true
        self.streamingStatuslabel.hidden = true
        self.setStartStreamingButtonEnability(true)
        self.setStopStreamingButtonEnability(false)
    }
    
    @IBAction func didTapDoneButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
    deinit
    {
        currentStreamingTocken = nil
    }
}