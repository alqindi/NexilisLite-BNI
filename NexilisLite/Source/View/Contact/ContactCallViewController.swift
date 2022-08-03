//
//  ContactViewController.swift
//  FloatingButtonApp
//
//  Created by Yayan Dwi on 05/08/21.
//

import UIKit
import nuSDKService

class ContactCallViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataPersonNotChange: [[String: String?]] = []
    var dataPerson: [[String: String?]] = []
    var fillteredData: [[String: String?]] = []
    var isAddParticipantVideo: Bool = false
    var connectedCall: [[String: String?]] = []
    var isDismiss: (([String: String?]) -> ())?
    var searchController: UISearchController!
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "videoVC") {
            let destination = segue.destination as! QmeraVideoViewController
            let index = sender as! UIButton
            destination.dataPerson.append(dataPerson[index.tag])
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(#function, ">>>> DIDAPPEAR CONTACT CALL")
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshView"), object: nil, userInfo: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Start Call"
        if (isAddParticipantVideo) {
            title = "Friends".localized()
            
            let buttonAddFriend = UIBarButtonItem(image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default))?.withTintColor(.white), style: .plain, target: self, action: #selector(addFriend(sender:)))
            navigationItem.rightBarButtonItem = buttonAddFriend
        } else {
            let menu = UIMenu(title: "", children: [
                UIAction(title: "Create Group", image: UIImage(systemName: "person.and.person"), handler: {(_) in
                    let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "createGroupNav") as! UINavigationController
                    let vc = controller.topViewController as! GroupCreateViewController
                    vc.isDismiss = { id in
                        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "groupDetailView") as! GroupDetailViewController
                        controller.data = id
                        self.navigationController?.show(controller, sender: nil)
                    }
                    self.navigationController?.present(controller, animated: true, completion: nil)
                }),
                UIAction(title: "Add Friends", image: UIImage(systemName: "person.badge.plus"), handler: {(_) in
                    let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "addFriendNav") as! UINavigationController
                    if let vc = controller.viewControllers.first as? AddFriendTableViewController {
                        vc.isDismiss = {
                            self.getData()
                        }
                    }
                    self.navigationController?.present(controller, animated: true, completion: nil)
                }),
//                UIAction(title: "Configure Email", image: UIImage(systemName: "mail"), handler: {(_) in }),
                UIAction(title: "Favorite Messages", image: UIImage(systemName: "star"), handler: {(_) in
                    let editorStaredVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "staredVC") as! EditorStarMessages
                    self.navigationController?.show(editorStaredVC, sender: nil)
                }),
            ])
            let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel(sender:)))
            let addImage = UIImage(systemName: "plus")
            let broadcastImage = UIImage(systemName: "video.bubble.left")
            let buttonAdd = UIBarButtonItem(image: addImage, menu: menu)
            let buttonBroadcast = UIBarButtonItem(image: broadcastImage,  style: .plain, target: self, action: #selector(didTapBroadcastButton(sender:)))
            navigationItem.leftBarButtonItem = cancel
            navigationItem.rightBarButtonItems = [buttonAdd, buttonBroadcast]
        }
        getData()
        dataPersonNotChange = dataPerson
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.searchBar.barTintColor = .secondaryColor
        searchController.searchBar.searchTextField.backgroundColor = .secondaryColor
        searchController.obscuresBackgroundDuringPresentation = false
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        definesPresentationContext = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(refresh(notification:)), name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil)
    }
    
    @objc func addFriend(sender: UIBarButtonItem) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "addFriendNav") as! UINavigationController
        if let vc = controller.viewControllers.first as? AddFriendTableViewController {
            vc.isDismiss = {
                self.getData()
                self.dataPersonNotChange = self.dataPerson
                self.tableView.reloadData()
            }
        }
        self.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    @objc func refresh(notification: NSNotification) {
        DispatchQueue.main.async {
            self.getData()
            self.dataPersonNotChange = self.dataPerson
            self.tableView.reloadData()
        }
    }

    @objc func didTapCancel(sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBroadcastButton(sender: AnyObject){
        
    }
    
    func getData() {
        dataPerson.removeAll()
        let idMe = UserDefaults.standard.string(forKey: "me") as String?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name, last_name, official_account, image_id, device_id, offline_mode, user_type, ex_block FROM BUDDY where official_account<>'1' and f_pin <> '\(idMe!)' order by 2 collate nocase asc") {
                while cursorData.next() {
                    var row: [String: String?] = [:]
                    row["f_pin"] = cursorData.string(forColumnIndex: 0)
                    if(connectedCall.count > 0 && connectedCall.contains(where: { $0["f_pin"] == row["f_pin"] })) {
                        continue
                    }
                    var name = ""
                    if let firstname = cursorData.string(forColumnIndex: 1) {
                         name = firstname
                    }
                    if let lastname = cursorData.string(forColumnIndex: 2) {
                        name = name + " " + lastname
                    }
                    if name.trimmingCharacters(in: .whitespaces) == "USR\(row["f_pin"]!!)" {
                        continue
                    }
                    row["block"] = cursorData.string(forColumnIndex: 8)
                    if row["block"] == "1" || row["block"] == "-1" {
                        continue
                    }
                    row["name"] = name
                    row["picture"] = cursorData.string(forColumnIndex: 4)
                    row["isOfficial"] = cursorData.string(forColumnIndex: 3)
                    row["deviceId"] = cursorData.string(forColumnIndex: 5)
                    row["isOffline"] = cursorData.string(forColumnIndex: 6)
                    row["user_type"] = cursorData.string(forColumnIndex: 7)
                    dataPerson.append(row)
                }
                cursorData.close()
            }
        })
    }
    
    func filterContentForSearchText(_ searchText: String) {
        fillteredData = self.dataPerson.filter { $0["name"]!!.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
}

extension ContactCallViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (isAddParticipantVideo) {
            self.dismiss(animated: true, completion: {
                self.isDismiss?(self.dataPerson[indexPath.row] as [String: String?])
            })
        }
    }
    
}

extension ContactCallViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFilltering {
            return fillteredData.count
        }
        return dataPersonNotChange.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath ) as! ContactCallCell
        cell.imagePerson.layer.masksToBounds = false
        cell.imagePerson.circle()
        cell.imagePerson.clipsToBounds = true
        cell.imagePerson.image = UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        cell.imagePerson.contentMode = .scaleAspectFit
        if isFilltering {
            dataPerson = fillteredData
        } else {
            dataPerson = dataPersonNotChange
        }
        if dataPerson.count > 0 {
            let pictureImage = dataPerson[indexPath.row]["picture"]!
            if (pictureImage != "" && pictureImage != nil) {
                cell.imagePerson.setImage(name: pictureImage!)
                cell.imagePerson.contentMode = .scaleAspectFill
            }
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            if dataPerson[indexPath.row]["user_type"] == "23" {
                cell.namePerson.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataPerson[indexPath.row]["name"]!!)", size: 15, y: -4)
            } else if dataPerson[indexPath.row]["user_type"] == "24" {
                cell.namePerson.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataPerson[indexPath.row]["name"]!!)", size: 15, y: -4)
            } else {
                cell.namePerson.text = dataPerson[indexPath.row]["name"] as? String
            }
            if (isAddParticipantVideo) {
                cell.audioCallButton.isHidden = true
                cell.videoCallButton.isHidden = true
            } else {
                cell.audioCallButton.tag = indexPath.row
                cell.videoCallButton.tag = indexPath.row
                
                cell.audioCallButton.addTarget(self, action: #selector(call(sender:)), for: .touchUpInside)
            }
        }
        return cell
    }
    
    @objc func call(sender: Any) {
        let index = sender as! UIButton
        if let pin = dataPerson[index.tag]["f_pin"] {
            let controller = QmeraAudioViewController()
            controller.user = User.getData(pin: pin)
            controller.isOutgoing = true
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        }
    }
}

class ContactCallCell: UITableViewCell {
    @IBOutlet weak var imagePerson: UIImageView!
    @IBOutlet weak var videoCallButton: UIButton!
    @IBOutlet weak var audioCallButton: UIButton!
    @IBOutlet weak var namePerson: UILabel!
}

extension ContactCallViewController {
    func set(image: UIImage, with text: String, size: CGFloat, y: CGFloat) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: y, width: size, height: size)
        let attachmentStr = NSAttributedString(attachment: attachment)
        
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(attachmentStr)
        
        let textString = NSAttributedString(string: text)
        mutableAttributedString.append(textString)
        
        return mutableAttributedString
    }
}

extension ContactCallViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
