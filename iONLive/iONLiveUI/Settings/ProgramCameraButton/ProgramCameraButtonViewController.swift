

import UIKit

class ProgramCameraButtonViewController: UIViewController {
    
    static let identifier = "ProgramCameraButtonViewController"
    
    @IBOutlet weak var programCameraButonTableView: UITableView!
    var dataSource = ["One click picture | Double click video","One click picture | Double click GIF","One click video | Double click live-stream"]
    
    var selectedOption:String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapBackButton(_ sender: Any)
    {
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

extension ProgramCameraButtonViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: ProgramCameraButtonHeaderCell.identifier) as! ProgramCameraButtonHeaderCell
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
            let cell = tableView.dequeueReusableCell(withIdentifier: ProgramCameraButtonCell.identifier, for:indexPath) as! ProgramCameraButtonCell
            cell.cameraOptionslabel.text = dataSource[indexPath.row]
            cell.selectionStyle = .none
            
            if selectedOption == dataSource[indexPath.row]
            {
                cell.selectionImage.isHidden = false
            }
            else
            {
                cell.selectionImage.isHidden = true
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
            programCameraButonTableView.reloadData()
        }
    }
}
