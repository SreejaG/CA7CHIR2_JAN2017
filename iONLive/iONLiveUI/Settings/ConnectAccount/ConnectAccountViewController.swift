
import UIKit

class ConnectAccountViewController: UIViewController {
    
    static let identifier = "ConnectAccountViewController"
    @IBOutlet weak var accountOptionsTableView: UITableView!
    
    var dataSource = ["Facebook","Twitter","Instagram"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func didTapBackButton(_ sender: Any)
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
}

extension ConnectAccountViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: ConnectAccountOptionsHeaderCell.identifier) as! ConnectAccountOptionsHeaderCell
        headerCell.topBorder.isHidden = false
        headerCell.bottomBorder.isHidden = false
        
        switch section
        {
        case 0:
            headerCell.topBorder.isHidden = true
            headerCell.headerTitle.text = ""
            break
        case 1:
            headerCell.bottomBorder.isHidden = true
            headerCell.headerTitle.text = ""
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
            let cell = tableView.dequeueReusableCell(withIdentifier: ConnectAccountOptionsCell.identifier, for:indexPath) as! ConnectAccountOptionsCell
            cell.accountOptionsLabel.text = dataSource[indexPath.row]
            cell.selectionStyle = .none
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        
    }
}

