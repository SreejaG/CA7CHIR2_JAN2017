
import UIKit

class DeleteMediaSettingsViewController: UIViewController{
    
    static let identifier = "DeleteMediaSettingsViewController"
    
    @IBOutlet weak var deleteMediaSettingsTableView: UITableView!
    
    var dataSource = ["Never","After 30 Days","After 7 Days"]
    
    var selectedOption:String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(UserDefaults.standard.value(forKey: "archiveMediaDeletion") != nil)
        {
            let value = UserDefaults.standard.value(forKey: "archiveMediaDeletion") as! String
            selectedOption = FileManagerViewController.sharedInstance.getArchiveDeleteLongString(resolution: value)
        }
        else{
            selectedOption = "Never"
        }
        deleteMediaSettingsTableView.reloadData()
    }
    
    @IBAction func didTapBackButton(_ sender: Any)
    {
        let value = FileManagerViewController.sharedInstance.getArchiveDeleteShortString(resolution: selectedOption)
        UserDefaults.standard.setValue(value, forKey: "archiveMediaDeletion")
        guard (navigationController?.popViewController(animated:true)) != nil
            else
        {
            dismiss(animated: true, completion: nil)
            return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension DeleteMediaSettingsViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: DeleteMediaSettingsHeaderCell.identifier) as! DeleteMediaSettingsHeaderCell
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
            headerCell.headerTitleLabel.text = "Archieved Media is stored on the Catch Cloud."
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
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if dataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: DeleteMediaOptionCell.identifier, for:indexPath as IndexPath) as! DeleteMediaOptionCell
            cell.mediaDeleteOptionLabel.text = dataSource[indexPath.row]
            cell.selectionStyle = .none
            
            if selectedOption == dataSource[indexPath.row]
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
        if dataSource.count > indexPath.row
        {
            selectedOption = dataSource[indexPath.row]
            deleteMediaSettingsTableView.reloadData()
        }
    }
}
