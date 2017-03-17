
import UIKit

class ResolutionSelectionViewController: UIViewController {
    
    static let identifier = "ResolutionSelectionViewController"
    
    @IBOutlet var resolutionTableView: UITableView!
    
    var liveResolutions = ["352x240 (240p)","480x360 (360p)","850x480 (480p)","1280x720 (720p)","1920x1080 (1080p)"]
    
    var selectedOption:String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(UserDefaults.standard.value(forKey: "liveResolution") != nil)
        {
            let value = UserDefaults.standard.value(forKey: "liveResolution") as! String
            selectedOption = FileManagerViewController.sharedInstance.getLiveResolutionLongString(resolution: value)
        }
        else{
            selectedOption = "1280x720 (720p)"
        }
        resolutionTableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapBackButton(_ sender: Any)
    {
        let value = FileManagerViewController.sharedInstance.getLiveResolutionShortString(resolution: selectedOption)
        UserDefaults.standard.setValue(value, forKey: "liveResolution")
        guard (navigationController?.popViewController(animated:true)) != nil
            else
        {
            dismiss(animated: true, completion: nil)
            return
        }
    }
}

extension ResolutionSelectionViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: ResolutionHeaderTableViewCell.identifier) as! ResolutionHeaderTableViewCell
        headerCell.topBorder.isHidden = false
        headerCell.bottomBorder.isHidden = false
        
        switch section
        {
        case 0:
            headerCell.topBorder.isHidden = true
            headerCell.headerTitleLabel.text = ""
            break
        case 1:
            headerCell.bottomBorder.isHidden = true
            headerCell.headerTitleLabel.text = ""
            break
        default:
            break
        }
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return liveResolutions.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if liveResolutions.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: ResolutionTableViewCell.identifier, for:indexPath as IndexPath) as! ResolutionTableViewCell
            cell.resolutionLabel.text = liveResolutions[indexPath.row]
            cell.selectionStyle = .none
            
            if selectedOption == liveResolutions[indexPath.row]
            {
                cell.selectionImageView.isHidden = false
            }
            else
            {
                cell.selectionImageView.isHidden = true
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if liveResolutions.count > indexPath.row
        {
            selectedOption = liveResolutions[indexPath.row]
            resolutionTableView.reloadData()
        }
    }
}
