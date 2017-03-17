
import UIKit

class AppInfoViewController: UIViewController {
    
    static let identifier = "AppInfoViewController"
    
    let optionTitle = "optionTitle"
    let accessryText = "accessryText"
    
    @IBOutlet var appInfoBackButton: UIButton!
    @IBOutlet var appInfoTableView: UITableView!
    
    var appInfoSource = [[String:String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        var build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
        
        if(build == "1"){
            build = "1.0"
        }
        
        appInfoSource = [[optionTitle:"Build Number", accessryText:build],[optionTitle:"Version", accessryText:version]]
        
        appInfoTableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        guard (navigationController?.popViewController(animated:true)) != nil
            else
        {
            dismiss(animated: true, completion: nil)
            return
        }
    }
}

extension AppInfoViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: AppInfoHeaderTableViewCell.identifier) as! AppInfoHeaderTableViewCell
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
            return appInfoSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if appInfoSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: AppInfoTableViewCell.identifier, for:indexPath as IndexPath) as! AppInfoTableViewCell
            cell.isUserInteractionEnabled = false
            cell.selectionStyle = .none
            cell.titleLabel.text = appInfoSource[indexPath.row][optionTitle]
            cell.accessryLabel.text = appInfoSource[indexPath.row][accessryText]
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
    }
}
