
import UIKit

class SnapCamSelectViewController: UIViewController {
    
    static let identifier = "SnapCamSelectViewController"
    @IBOutlet weak var snapCamSettingsTableView: UITableView!
    weak var streamingDelegate:StreamingProtocol?
    var snapCamMode : SnapCamSelectionMode = SnapCamSelectionMode()
    var toggleSnapCamIPhoneMode:SnapCamSelectionMode = .SnapCam
    
    @IBOutlet var titleLabel: UILabel!
    var rowAfterAlertHit: Int!
    var cellAfterAlertHit : UITableViewCell = UITableViewCell()
    
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var activityImageView: UIImageView!
    
    var dataSource = ["Live Stream", "Photos", "Video" , "Catch gif", "Time lapse", "Switch to iPhone"]
    
    @IBOutlet var iPhoneSnapCamImageView: UIImageView!
    @IBOutlet var blurView: UIView!
    @IBOutlet var snapCamButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadDefaults()
    }
    
    func loadDefaults()
    {
        snapCamSettingsTableView.separatorStyle = .none
        snapCamButton.clipsToBounds = true
        snapCamButton.layer.cornerRadius = 5
        updateDatabaseForSnapCamOrIPhone()
    }
    
    func updateDatabaseForSnapCamOrIPhone()
    {
        let defaults = UserDefaults.standard
        let shutterMode = defaults.integer(forKey: "shutterActionMode")
        switch(shutterMode)
        {
        case 0 :
            snapCamMode = .LiveStream
            break
        case 1:
            snapCamMode = .Photos
            break
        case 2:
            snapCamMode = .Video
            break
        case 3:
            snapCamMode = .CatchGif
            break
        case 4:
            snapCamMode = .Timelapse
            break
        case 5:
            snapCamMode = .iPhone
            break
            //        case 6:
            //            snapCamMode = .TestAPI
        //            break
        default :
            break
        }
        
        if toggleSnapCamIPhoneMode == SnapCamSelectionMode.SnapCam
        {
            dataSource[5] = "Switch to iPhone"
            titleLabel.text = "Snapcam"
            snapCamButton.setImage(UIImage(named: "snapCamMode"), for: .normal)
            
        }
        else
        {
            dataSource[5] = "Switch to SnapCam"
            titleLabel.text = "iPhone"
            snapCamButton.setImage(UIImage(named: "iphone"), for: .normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    deinit {
    }
    
}

//PRAGMA MARK:- TableView datasource, delegates
extension SnapCamSelectViewController:UITableViewDataSource,UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let count = dataSource.count
        return count > 0 ? count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: SnapCamTableViewCell.identifier, for: indexPath) as! SnapCamTableViewCell
        
        if dataSource.count > indexPath.row
        {
            cell.optionlabel.text = dataSource[indexPath.row]
        }
        customizeCellBasedOnSnapCamSelectionMode(selectedCell: cell , row: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
        updateSnapCamModeSelection(row: indexPath.row, ForCell: selectedCell)
        
        switch indexPath.row
        {
        case 5:
            if  toggleSnapCamIPhoneMode == SnapCamSelectionMode.iPhone
            {
                titleLabel.text = "Snapcam"
                loadCameraViewWithFadeInFadeOutAnimation()
            }
            else
            {
                titleLabel.text = "iPhone"
                let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
                let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewController(withIdentifier: "IPhoneCameraViewController") as! IPhoneCameraViewController
                self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
                loadSnapCamViewWithFadeInFadeOutAnimation()
            }
            break
            
            //        case 6:
            //            loadAPITestView()
            //            break
            
        default :
            let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
            let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewController(withIdentifier: "IPhoneCameraViewController") as! IPhoneCameraViewController
            let navController = UINavigationController(rootViewController: iPhoneCameraViewController)
            self.present(navController, animated: false) { () -> Void in
            }
            break;
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60
    }
}

//PRAGMA MARK:- Helper Methods
extension SnapCamSelectViewController
{
    func updateSnapCamModeSelection(row:Int , ForCell selectedCell:UITableViewCell)
    {
        if isStreamStarted()
        {
            showAlertViewToStopStream(row: row, ForCell: selectedCell)
        }
        else
        {
            updateSnapCamSelection(rowVal: row)
            changeSnapCamModeForCell(selectedCell: selectedCell)
        }
    }
    
    //PRAGMA MARK:- Animated views
    func loadSnapCamViewWithFadeInFadeOutAnimation()
    {
        self.blurView.alpha = 0;
        self.blurView.isHidden = false;
        activityImageView.isHidden = true;
        activityLabel.isHidden = true;
        iPhoneSnapCamImageView.image = UIImage(named: "Switched_mode_Camera");
        snapCamSettingsTableView.isHidden = true;
        
        UIView.animate(withDuration: 1.0, animations: { () -> Void in
            self.blurView.alpha = 1.0
        }) { (finished) -> Void in
            UIView.animate(withDuration: 1.0, animations: { () -> Void in
                self.blurView.alpha = 0.0
            }, completion: { (finshed) -> Void in
                self.switchToiPhoneView()
            })
        }
    }
    
    func loadCameraViewWithFadeInFadeOutAnimation()
    {
        self.blurView.alpha = 0;
        self.blurView.isHidden = false;
        activityImageView.image =  UIImage.animatedImageNamed("loader-", duration: 1.0)
        iPhoneSnapCamImageView.image = UIImage(named: "Switched modes");
        snapCamSettingsTableView.isHidden = true;
        
        UIView .animate(withDuration: 1.0, animations: { () -> Void in
            self.blurView.alpha = 1.0
            
        }) { (finished) -> Void in
            self.startSnapCamViewAnimation()
        }
    }
    
    func startSnapCamViewAnimation()
    {
        UIView .animate(withDuration: 1.0, animations: { () -> Void in
            
            self.activityImageView.isHidden = true;
            self.activityLabel.isHidden = true;
            self.iPhoneSnapCamImageView.image = UIImage(named: "SnapCam Switched modes");
            
        }) { (finished) -> Void in
            
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                
                self.blurView.alpha = 0.0
                
            }, completion: { (finshed) -> Void in
                self.switchToSnapCamView()
            })
        }
    }
    
    func switchToSnapCamView()
    {
        dataSource[5] = "Switch to SnapCam"
        toggleSnapCamIPhoneMode = SnapCamSelectionMode.SnapCam
        
        loadLiveStreamView()
    }
    
    func switchToiPhoneView()
    {
        dataSource[5] = "Switch to iPhone"
        toggleSnapCamIPhoneMode = SnapCamSelectionMode.iPhone
        loadCameraViewController()
    }
    
    //PRAGMA MARK:- LoadViews for each table Actions
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewController(withContentPath: "rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! MovieViewController
        clearStreamingUserDefaults(defaults: UserDefaults.standard)
        let navigationController:UINavigationController = UINavigationController(rootViewController: vc)
        navigationController.isNavigationBarHidden = true
        self.present(navigationController, animated: false) { () -> Void in
        }
    }
    
    func loadCameraViewController()
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewController(withIdentifier: "IPhoneCameraViewController") as! IPhoneCameraViewController
        let navController = UINavigationController(rootViewController: iPhoneCameraViewController)
        navController.isNavigationBarHidden = true
        self.present(navController, animated: false) { () -> Void in
        }
    }
    
    func loadAPITestView()
    {
        let storyBoard = UIStoryboard(name:"iONCamPictureAPITest" , bundle: nil)
        let testAPIListVC = storyBoard.instantiateViewController(withIdentifier: iONLiveCamAPIListViewController.identifier)
        self.navigationController?.pushViewController(testAPIListVC, animated: true)
    }
    
    func changeSelectedSnapCamMode(selectedMode:SnapCamSelectionMode)
    {
        if snapCamMode == selectedMode
        {
        }
        else
        {
            snapCamMode = selectedMode
            if snapCamMode != SnapCamSelectionMode.SnapCam && snapCamMode != SnapCamSelectionMode.iPhone
            {
                UserDefaults.standard.set(selectedMode.rawValue, forKey: "shutterActionMode");
            }
        }
    }
    
    func showAlertViewToStopStream(row:Int , ForCell selectedCell:UITableViewCell)
    {
        let alert: UIAlertView = UIAlertView()
        alert.title = "Streaming In Progress"
        alert.message = "Do you want to stop streaming?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.delegate = self
        rowAfterAlertHit = row
        cellAfterAlertHit = selectedCell
        alert.show()
    }
    
    func changeSnapCamModeForCell(selectedCell:UITableViewCell)
    {
        //        streamingDelegate?.cameraSelectionMode!(selection: snapCamMode)
        self.snapCamSettingsTableView.reloadData()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        let buttonTitle = alertView.buttonTitle(at: buttonIndex)
        if buttonTitle == "Yes" {
            
            stopLiveStreaming()
            updateSnapCamSelection(rowVal: rowAfterAlertHit)
            changeSnapCamModeForCell(selectedCell: cellAfterAlertHit)
            self.snapCamSettingsTableView.reloadData()
        }
        else
        {
            self.snapCamSettingsTableView.reloadData()
        }
    }
    
    func stopLiveStreaming()
    {
        if toggleSnapCamIPhoneMode == SnapCamSelectionMode.SnapCam
        {
            stopSnapCamCameraLiveStreaming()
        }
        else if toggleSnapCamIPhoneMode == SnapCamSelectionMode.iPhone
        {
            stopIPhoneCameraLiveStreaming()
        }
    }
    
    func stopSnapCamCameraLiveStreaming()
    {
        let stream = UploadStream()
        stream.stopStreamingClicked()
        streamingDelegate?.cameraSelectionMode!(selection: snapCamMode)
    }
    
    func stopIPhoneCameraLiveStreaming()
    {
        let liveStreaming = IPhoneLiveStreaming()
        liveStreaming.stopStreamingClicked()
    }
    
    //PRAGMA MARK:- customize table cell
    func customizeCellBasedOnSnapCamSelectionMode(selectedCell:UITableViewCell , row:Int)
    {
        if (snapCamMode == SnapCamSelectionMode.SnapCam || snapCamMode ==  SnapCamSelectionMode.iPhone) && row == 5
        {
            customizeSnapCamIPhoneCell(selectedCell: selectedCell)
        }
        else if snapCamMode == SnapCamSelectionMode.TestAPI && row == 6
        {
            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
        }
        else if snapCamMode.rawValue == row
        {
            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
        }
        else
        {
            selectedCell.contentView.backgroundColor = UIColor.clear
        }
    }
    
    func customizeSnapCamIPhoneCell(selectedCell : UITableViewCell)
    {
        selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
    }
    
    func updateSnapCamSelection(rowVal:Int)
    {
        switch(rowVal)
        {
        case 0 :
            changeSelectedSnapCamMode(selectedMode: .LiveStream)
            break
        case 1:
            changeSelectedSnapCamMode(selectedMode: .Photos)
            break
        case 2:
            changeSelectedSnapCamMode(selectedMode: .Video)
            break
        case 3:
            changeSelectedSnapCamMode(selectedMode: .CatchGif)
            break
        case 4:
            changeSelectedSnapCamMode(selectedMode: .Timelapse)
            break
        case 5:
            changeSelectedSnapCamMode(selectedMode: .iPhone)
            break
            //        case 6:
            //            changeSelectedSnapCamMode(selectedMode: .TestAPI)
        //            break
        default :
            break
        }
    }
    
    //PRAGMA MARK:- User defaults
    func isStreamStarted()->Bool
    {
        let defaults = UserDefaults.standard
        return  defaults.bool(forKey: "StartedStreaming")
    }
    
    func clearStreamingUserDefaults(defaults:UserDefaults)
    {
        defaults.removeObject(forKey: streamingToken)
        defaults.removeObject(forKey: startedStreaming)
        defaults.removeObject(forKey: initializingStream)
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func settingsbuttonClicked(_ sender: Any)
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let settingsVC = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.isNavigationBarHidden = true
        self.present(navController, animated: false) { () -> Void in
        }
    }
    
    @IBAction func snapcamButtonClicked(_ sender: Any)
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewController(withIdentifier: "IPhoneCameraViewController") as! IPhoneCameraViewController
        let navController = UINavigationController(rootViewController: iPhoneCameraViewController)
        navController.isNavigationBarHidden = true
        self.present(navController, animated: false) { () -> Void in
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}





