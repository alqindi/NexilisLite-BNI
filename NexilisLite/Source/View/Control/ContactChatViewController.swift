//
//  ContactChatViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 22/09/21.
//

import UIKit
import FMDB
import NotificationBannerSwift

class ContactChatViewController: UITableViewController {
    
    deinit {
        print(#function, ">>>> TADAA")
        NotificationCenter.default.removeObserver(self)
    }
    
    var isChooser: ((String, String) -> ())?
    
    var isAdmin: Bool = false
    
    var chats: [Chat] = []
    
    var contacts: [User] = []
    
    var groups: [Group] = []
    
    var groupMap: [String:Int] = [:]
    
    var searchController: UISearchController!
    
    var segment: UISegmentedControl!
    
    var fillteredData: [Any] = []
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    func filterContentForSearchText(_ searchText: String) {
        switch segment.selectedSegmentIndex {
        case 1:
            fillteredData = self.contacts.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
        case 2:
            fillteredData = self.groups.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        default:
            fillteredData = self.chats.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.messageText.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let me = UserDefaults.standard.string(forKey: "me")!
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select FIRST_NAME, LAST_NAME, IMAGE_ID, USER_TYPE from BUDDY where F_PIN = '\(me)'"), cursor.next() {
                isAdmin = cursor.string(forColumnIndex: 3) == "23" || cursor.string(forColumnIndex: 3) == "24"
                cursor.close()
            }
        })
        
        title = "Start Conversation".localized()
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0)]
        self.navigationController?.navigationBar.titleTextAttributes = attributes
        
        //        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        
        var childrenMenu : [UIAction] = [
            UIAction(title: "Create Group", image: UIImage(systemName: "person.and.person"), handler: {[weak self](_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "createGroupNav") as! UINavigationController
                let vc = controller.topViewController as! GroupCreateViewController
                vc.isDismiss = { id in
                    self?.groupMap.removeAll()
                    let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "groupDetailView") as! GroupDetailViewController
                    controller.data = id
                    self?.navigationController?.show(controller, sender: nil)
                }
                self?.navigationController?.present(controller, animated: true, completion: nil)
            }),
            UIAction(title: "Add Friends", image: UIImage(systemName: "person.badge.plus"), handler: {[weak self](_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "addFriendNav") as! UINavigationController
                if let vc = controller.viewControllers.first as? AddFriendTableViewController {
                    vc.isDismiss = {
                        self?.getContacts {
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                    }
                }
                self?.navigationController?.present(controller, animated: true, completion: nil)
            }),
//            UIAction(title: "Configure Email", image: UIImage(systemName: "mail"), handler: {[weak self](_) in
//
//            }),
            UIAction(title: "Favorite Messages", image: UIImage(systemName: "star"), handler: {[weak self](_) in
                let editorStaredVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "staredVC") as! EditorStarMessages
                self?.navigationController?.show(editorStaredVC, sender: nil)
            }),
        ]
        //debug only
//        isAdmin = true
        if(isAdmin){
            childrenMenu.append(UIAction(title: "Broadcast Message", image: UIImage(systemName: "envelope.open"), handler: {[weak self](_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "broadcastNav")
                self?.navigationController?.present(controller, animated: true, completion: nil)
            }))
        }
        
        let menu = UIMenu(title: "", children: childrenMenu)
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: .none, menu: menu)
        
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
        
        segment = UISegmentedControl(items: ["Chats".localized(), "Contacts".localized(), "Groups".localized()])
        segment.sizeToFit()
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(segmentChanged(sender:)), for: .valueChanged)
        segment.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12.0)], for: .normal)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: "onReceiveChat"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReload(notification:)), name: NSNotification.Name(rawValue: "onMember"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReload(notification:)), name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil)
        
        tableView.tableHeaderView = segment
        tableView.tableFooterView = UIView()
        
        pullBuddy()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        groupMap.removeAll()
        getData()
    }
    
    @objc func onReload(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        if data["member"] as? String == UserDefaults.standard.string(forKey: "me") {
            DispatchQueue.main.async {
                self.getData()
            }
        } else if data["state"] as? Int == 99 {
            DispatchQueue.main.async {
                self.getData()
            }
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        guard let dataMessage = data["message"] as? TMessage else {
            return
        }
        let isUser = User.getData(pin: dataMessage.getBody(key: CoreMessage_TMessageKey.L_PIN)) != nil
        let chatId = dataMessage.getBody(key: CoreMessage_TMessageKey.CHAT_ID, default_value: "").isEmpty ? dataMessage.getBody(key: CoreMessage_TMessageKey.L_PIN) : dataMessage.getBody(key: CoreMessage_TMessageKey.CHAT_ID, default_value: "")
        let pin = isUser ? dataMessage.getBody(key: CoreMessage_TMessageKey.F_PIN) : chatId
        let messageId = dataMessage.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
        if let index = chats.firstIndex(of: Chat(pin: pin)) {
            guard let chat = Chat.getData(messageId: messageId).first else {
                return
            }
            DispatchQueue.main.async {
                if self.segment.selectedSegmentIndex == 0 {
                    self.tableView.beginUpdates()
                    self.chats.remove(at: index)
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
                self.chats.insert(chat, at: 0)
                if self.segment.selectedSegmentIndex == 0 {
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                    self.tableView.endUpdates()
                }
            }
        } else {
            guard let chat = Chat.getData(messageId: messageId).first else {
                return
            }
            DispatchQueue.main.async {
                if self.segment.selectedSegmentIndex == 0 {
                    self.tableView.beginUpdates()
                }
                self.chats.insert(chat, at: 0)
                if self.segment.selectedSegmentIndex == 0 {
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                    self.tableView.endUpdates()
                }
            }
        }
    }
    
    @objc func add(sender: Any) {
        
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func segmentChanged(sender: Any) {
        filterContentForSearchText(searchController.searchBar.text!)
        if segment.selectedSegmentIndex == 2 {
            self.getGroups { g1 in
                self.getOpenGroups(listGroups: g1, completion: { g in
                    self.groups.removeAll()
                    self.groups.append(contentsOf: g1)
                    for og in g {
                        if self.groups.first(where: { $0.id == og.id }) == nil {
                            self.groups.append(og)
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    // MARK: - Data source
    
    func getData() {
        self.chats.removeAll()
        self.contacts.removeAll()
        getChats {
            self.getContacts {
                self.getGroups { g1 in
                    self.getOpenGroups(listGroups: g1, completion: { g in
                        self.groups.removeAll()
                        self.groups.append(contentsOf: g1)
                        for og in g {
                            if self.groups.first(where: { $0.id == og.id }) == nil {
                                self.groups.append(og)
                            }
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    })
                }
            }
        }
    }
    
    func getChats(completion: @escaping ()->()) {
        self.chats.removeAll()
        DispatchQueue.global().async {
            let chatData = Chat.getData()
            if !self.chats.contains(where: {$0.messageId == chatData.first?.messageId ?? ""}) {
                self.chats.append(contentsOf: chatData)
            }
            completion()
        }
    }
    
    private func getContacts(completion: @escaping ()->()) {
        self.contacts.removeAll()
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name, last_name, image_id, official_account, user_type FROM BUDDY where f_pin <> '\(UserDefaults.standard.string(forKey: "me")!)' order by 5 desc, 2 collate nocase asc") {
                    while cursorData.next() {
                        let user = User(pin: cursorData.string(forColumnIndex: 0) ?? "",
                                        firstName: cursorData.string(forColumnIndex: 1) ?? "",
                                        lastName: cursorData.string(forColumnIndex: 2) ?? "",
                                        thumb: cursorData.string(forColumnIndex: 3) ?? "",
                                        userType: cursorData.string(forColumnIndex: 5) ?? "")
                        if (user.firstName + " " + user.lastName).trimmingCharacters(in: .whitespaces) == "USR\(user.pin)" {
                            continue
                        }
                        user.official = cursorData.string(forColumnIndex: 4) ?? ""
                        if !self.contacts.contains(where: {$0.pin == user.pin}) {
                            self.contacts.append(user)
                        }
                    }
                    cursorData.close()
                }
                completion()
            })
        }
    }
    
    private func getGroupRecursive(fmdb: FMDatabase, id: String = "", parent: String = "") -> [Group] {
        var data: [Group] = []
        var query = "select g.group_id, g.f_name, g.image_id, g.quote, g.created_by, g.created_date, g.parent, g.group_type, g.is_open, g.official, g.is_education from GROUPZ g where "
        if id.isEmpty {
            query += "g.parent = '\(parent)'"
        } else {
            query += "g.group_id = '\(id)'"
        }
        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) {
            while cursor.next() {
                let group = Group(
                    id: cursor.string(forColumnIndex: 0) ?? "",
                    name: cursor.string(forColumnIndex: 1) ?? "",
                    profile: cursor.string(forColumnIndex: 2) ?? "",
                    quote: cursor.string(forColumnIndex: 3) ?? "",
                    by: cursor.string(forColumnIndex: 4) ?? "",
                    date: cursor.string(forColumnIndex: 5) ?? "",
                    parent: cursor.string(forColumnIndex: 6) ?? "",
                    chatId: "",
                    groupType: cursor.string(forColumnIndex: 7) ?? "",
                    isOpen: cursor.string(forColumnIndex: 8) ?? "",
                    official: cursor.string(forColumnIndex: 9) ?? "",
                    isEducation: cursor.string(forColumnIndex: 10) ?? "")
                
                if group.chatId.isEmpty {
                    let lounge = Group(id: group.id, name: "Lounge".localized(), profile: "", quote: group.quote, by: group.by, date: group.date, parent: group.id, chatId: group.chatId, groupType: group.groupType, isOpen: group.isOpen, official: group.official, isEducation: group.isEducation, isLounge: true)
                    group.childs.append(lounge)
                }
                
                if let topicCursor = Database.shared.getRecords(fmdb: fmdb, query: "select chat_id, title, thumb from DISCUSSION_FORUM where group_id = '\(group.id)'") {
                    while topicCursor.next() {
                        let topic = Group(id: group.id,
                                          name: topicCursor.string(forColumnIndex: 1) ?? "",
                                          profile: topicCursor.string(forColumnIndex: 2) ?? "",
                                          quote: group.quote,
                                          by: group.by,
                                          date: group.date,
                                          parent: group.id,
                                          chatId: topicCursor.string(forColumnIndex: 0) ?? "",
                                          groupType: group.groupType,
                                          isOpen: group.isOpen,
                                          official: group.official,
                                          isEducation: group.isEducation)
                        group.childs.append(topic)
                    }
                    topicCursor.close()
                }
                
                if !group.id.isEmpty {
                    if group.official == "1" {
                        let idMe = UserDefaults.standard.string(forKey: "me") as String?
                        if let cursorUser = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type FROM BUDDY where f_pin='\(idMe!)'"), cursorUser.next() {
//                            if cursorUser.string(forColumnIndex: 0) == "23" || cursorUser.string(forColumnIndex: 0) == "24" {
//                                group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
//                            }
                            group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
                            cursorUser.close()
                        }
                    } else if group.official != "1"{
                        group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
                    }
                    group.childs = group.childs.sorted(by: { $0.name < $1.name })
                    let dataLounge = group.childs.filter({$0.name == "Lounge".localized()})
                    group.childs = group.childs.filter({ $0.name != "Lounge".localized() })
                    group.childs.insert(contentsOf: dataLounge, at: 0)
                }
                data.append(group)
            }
            cursor.close()
        }
        return data
    }
    
    private func getOpenGroups(listGroups: [Group], completion: @escaping ([Group]) -> ()) {
        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getOpenGroups(p_account: "1,2,3,5,6,7", offset: "0", search: "")) {
            var dataGroups: [Group] = []
            if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [[String: Any?]] {
                    for dataJson in json {
                        let group = Group(
                            id: dataJson[CoreMessage_TMessageKey.GROUP_ID] as? String ?? "",
                            name: dataJson[CoreMessage_TMessageKey.GROUP_NAME] as? String ?? "",
                            profile: dataJson[CoreMessage_TMessageKey.THUMB_ID] as? String ?? "",
                            quote: dataJson[CoreMessage_TMessageKey.QUOTE] as? String ?? "",
                            by: dataJson[CoreMessage_TMessageKey.BLOCK] as? String ?? "",
                            date: "",
                            parent: "",
                            chatId: "",
                            groupType: "NOTJOINED",
                            isOpen: dataJson[CoreMessage_TMessageKey.IS_OPEN] as? String ?? "",
                            official: "0",
                            isEducation: "")
                        dataGroups.append(group)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.groups.removeAll()
                    self.groups.append(contentsOf: listGroups)
                    self.tableView.reloadData()
                }
            }
            completion(dataGroups)
        }
    }
    
    private func getGroups(id: String = "", parent: String = "", completion: @escaping ([Group]) -> ()) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                completion(self.getGroupRecursive(fmdb: fmdb, id: id, parent: parent))
            })
        }
    }
    
    private func pullBuddy() {
        if let me = UserDefaults.standard.string(forKey: "me") {
            DispatchQueue.global().async {
                let _ = Nexilis.write(message: CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: me, last_update: 0))
            }
        }
    }
    
    private func joinOpenGroup(groupId: String, flagMember: String = "0", completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            var result: Bool = false
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddGroupMember(p_group_id: groupId, p_member_pin: idMe!, p_position: "0")), response.isOk() {
                result = true
            }
            completion(result)
        }
    }
    
}

// MARK: - Table view data source

extension ContactChatViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch segment.selectedSegmentIndex {
        case 0:
            let data: Chat
            if isFilltering {
                data = fillteredData[indexPath.row] as! Chat
            } else {
                data = chats[indexPath.row]
            }
            if let chooser = isChooser {
                if data.pin == "-999"{
                    return
                }
                chooser(data.messageScope, data.pin)
                dismiss(animated: true, completion: nil)
                return
            }
            let user = User.getData(pin: data.pin)
            if user != nil || data.pin == "-999" {
                let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                editorPersonalVC.hidesBottomBarWhenPushed = true
                editorPersonalVC.unique_l_pin = data.pin
                navigationController?.show(editorPersonalVC, sender: nil)
            } else {
                groupMap.removeAll()
                let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                editorGroupVC.hidesBottomBarWhenPushed = true
                editorGroupVC.unique_l_pin = data.pin
                navigationController?.show(editorGroupVC, sender: nil)
            }
        case 1:
            let data: User
            if isFilltering {
                data = fillteredData[indexPath.row] as! User
            } else {
                data = contacts[indexPath.row]
            }
            if let chooser = isChooser {
                chooser("3", data.pin)
                dismiss(animated: true, completion: nil)
                return
            }
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = data.pin
            navigationController?.show(editorPersonalVC, sender: nil)
        case 2:
            let group: Group
            if isFilltering {
                if indexPath.row == 0 {
                    group = fillteredData[indexPath.section] as! Group
                } else {
                    group = (fillteredData[indexPath.section] as! Group).childs[indexPath.row - 1]
                }
            } else {
                if indexPath.row == 0 {
                    group = groups[indexPath.section]
                } else {
                    group = groups[indexPath.section].childs[indexPath.row - 1]
                }
            }
            group.isSelected = !group.isSelected
            if !group.isSelected{
                var sects = 0
                var sect = indexPath.section
                var id = group.id
                if let e = groupMap[id] {
                    var loooop = true
                    repeat {
                        let c = sect + 1
                        if isFilltering {
                            if let o = self.fillteredData[c] as? Group {
                                if o.parent == id {
                                    sects = sects + 1
                                    sect = c
                                    id = o.id
                                    (self.fillteredData[c] as! Group).isSelected = false
                                    self.groupMap.removeValue(forKey: (self.fillteredData[c] as! Group).id)
                                }
                                else {
                                    loooop = false
                                }
                            }
                        }
                        else {
                            if self.groups[c].parent == id {
                                sects = sects + 1
                                sect = c
                                id = self.groups[c].id
                                self.groups[c].isSelected = false
                                self.groupMap.removeValue(forKey: self.groups[c].id)
                            }
                            else {
                                loooop = false
                            }
                        }
                    } while(loooop)
                }
                for i in stride(from: sects, to: 0, by: -1){
                    if isFilltering {
                        self.fillteredData.remove(at: indexPath.section + i)
                    }
                    else {
                        self.groups.remove(at: indexPath.section + i)
                    }
                }
                groupMap.removeValue(forKey: group.id)
            }
            if group.groupType == "NOTJOINED" {
                let alert = UIAlertController(title: "Do you want to join this group?".localized(), message: "Groups : \(group.name)\nMembers: \(group.by)".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Join".localized(), style: .default, handler: {(_) in
                    self.joinOpenGroup(groupId: group.id, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                self.groupMap.removeAll()
                                let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                                editorGroupVC.hidesBottomBarWhenPushed = true
                                editorGroupVC.unique_l_pin = group.id
                                self.navigationController?.show(editorGroupVC, sender: nil)
                            }
                        }
                    })
                }))
                self.present(alert, animated: true, completion: nil)
                return
            }
            if group.childs.count == 0 {
                let groupId = group.chatId.isEmpty ? group.id : group.chatId
                if let chooser = isChooser {
                    chooser("4", groupId)
                    dismiss(animated: true, completion: nil)
                    return
                }
                self.groupMap.removeAll()
                let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                editorGroupVC.hidesBottomBarWhenPushed = true
                editorGroupVC.unique_l_pin = groupId
                navigationController?.show(editorGroupVC, sender: nil)
            } else {
                if indexPath.row == 0 {
                    tableView.reloadData()
                } else {
                    getGroups(id: group.id) { g in
                        DispatchQueue.main.async {
                            print("index path section: \(indexPath.section)")
                            print("index path row: \(indexPath.row)")
//                            print("index path item: \(indexPath.item)")
                            if self.isFilltering {
//                                self.fillteredData.remove(at: indexPath.section)
                                if self.fillteredData[indexPath.section] is Group {
                                    self.groupMap[(self.fillteredData[indexPath.section] as! Group).id] = 1
                                    self.fillteredData.insert(contentsOf: g, at: indexPath.section + 1)
                                }
                            } else {
//                                self.groups.remove(at: indexPath.section)
                                self.groupMap[self.groups[indexPath.section].id] = 1
                                self.groups.insert(contentsOf: g, at: indexPath.section + 1)
                            }
                            print("groupMap: \(self.groupMap)")
                            tableView.reloadData()
                        }
                    }
                }
            }
        default:
            let data = contacts[indexPath.row]
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = data.pin
            navigationController?.show(editorPersonalVC, sender: nil)
        }
    }
    
}

extension ContactChatViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isFilltering {
            if segment.selectedSegmentIndex == 2 {
                return fillteredData.count
            }
            return 1
        } else {
            if segment.selectedSegmentIndex == 2 {
                return groups.count
            }
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var value = 0
        if isFilltering {
            if segment.selectedSegmentIndex == 2, let groups = fillteredData as? [Group] {
                let group = groups[section]
                if group.isSelected {
                    if let g = groupMap[group.id] {
                        value = 1
                    }
                    else {
                        value = group.childs.count + 1
                    }
                } else {
                    value = 1
                }
            }
            return fillteredData.count
        }
        switch segment.selectedSegmentIndex {
        case 0:
            value = chats.count
        case 1:
            value = contacts.count
        case 2:
            let group = groups[section]
            if group.isSelected {
                if let g = groupMap[group.id] {
                    value = 1
                }
                else {
                    value = group.childs.count + 1
                }
            } else {
                value = 1
            }
        default:
            value = chats.count
        }
        return value
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        switch segment.selectedSegmentIndex {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierChat", for: indexPath)
            cell.separatorInset.left = 60.0
            let content = cell.contentView
            if content.subviews.count > 0 {
                content.subviews.forEach { $0.removeFromSuperview() }
            }
            let data: Chat
            if isFilltering {
                data = fillteredData[indexPath.row] as! Chat
            } else {
                data = chats[indexPath.row]
            }
            let imageView = UIImageView()
            content.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10.0),
                imageView.topAnchor.constraint(equalTo: content.topAnchor, constant: 10.0),
                imageView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20.0),
                imageView.widthAnchor.constraint(equalToConstant: 40.0),
                imageView.heightAnchor.constraint(equalToConstant: 40.0)
            ])
            if data.profile.isEmpty && data.pin != "-999" {
                let user = User.getData(pin: data.pin)
                if user != nil {
                    imageView.image = UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                } else {
                    imageView.image = UIImage(named: "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
            } else {
                getImage(name: data.profile, placeholderImage: UIImage(named: data.pin == "-999" ? "pb_ball" : "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                    imageView.image = image
                })
            }
            let titleView = UILabel()
            content.addSubview(titleView)
            titleView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10.0),
                titleView.topAnchor.constraint(equalTo: content.topAnchor, constant: 10.0),
                titleView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40.0),
            ])
            titleView.text = data.name
            titleView.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            
            let messageView = UILabel()
            content.addSubview(messageView)
            messageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                messageView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10.0),
                messageView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 5.0),
                messageView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40.0),
            ])
            messageView.textColor = .gray
            let text = Utils.previewMessageText(chat: data)
            if let attributeText = text as? NSAttributedString {
                messageView.attributedText = attributeText
            } else if let stringText = text as? String {
                messageView.text = stringText
            }
            messageView.font = UIFont.systemFont(ofSize: 12)
            messageView.numberOfLines = 2
            
            if data.counter != "0" {
                let viewCounter = UIView()
                content.addSubview(viewCounter)
                viewCounter.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    viewCounter.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                    viewCounter.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
                    viewCounter.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
                    viewCounter.heightAnchor.constraint(equalToConstant: 20)
                ])
                viewCounter.backgroundColor = .systemRed
                viewCounter.layer.cornerRadius = 10
                viewCounter.clipsToBounds = true
                viewCounter.layer.borderWidth = 0.5
                viewCounter.layer.borderColor = UIColor.secondaryColor.cgColor

                let labelCounter = UILabel()
                viewCounter.addSubview(labelCounter)
                labelCounter.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelCounter.centerYAnchor.constraint(equalTo: viewCounter.centerYAnchor),
                    labelCounter.leadingAnchor.constraint(equalTo: viewCounter.leadingAnchor, constant: 2),
                    labelCounter.trailingAnchor.constraint(equalTo: viewCounter.trailingAnchor, constant: -2),
                ])
                labelCounter.font = UIFont.systemFont(ofSize: 11)
                if Int(data.counter)! > 99 {
                    labelCounter.text = "99+"
                } else {
                    labelCounter.text = data.counter
                }
                labelCounter.textColor = .secondaryColor
                labelCounter.textAlignment = .center
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierContact", for: indexPath)
            var content = cell.defaultContentConfiguration()
            let data: User
            if isFilltering {
                data = fillteredData[indexPath.row] as! User
            } else {
                data = contacts[indexPath.row]
            }
            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            getImage(name: data.thumb, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                content.image = image
            })
            if (data.official == "1") {
                content.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4)
            }
            else if data.userType == "23" {
                content.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4)
            } else if data.userType == "24" {
                content.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4)
            }
            else {
                content.text = data.fullName
            }
            content.textProperties.font = UIFont.systemFont(ofSize: 14)
            cell.contentConfiguration = content
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierGroup", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.font = UIFont.systemFont(ofSize: 14)
            let group: Group
            if isFilltering {
                if indexPath.row == 0 {
                    group = fillteredData[indexPath.section] as! Group
                } else {
                    group = (fillteredData[indexPath.section] as! Group).childs[indexPath.row - 1]
                }
            } else {
                if indexPath.row == 0 {
                    group = groups[indexPath.section]
                } else {
                    group = groups[indexPath.section].childs[indexPath.row - 1]
                }
            }
            if group.official == "1" && group.parent == "" {
                content.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(group.name)", size: 15, y: -4)
            }
            else if group.isOpen == "1" && group.parent == "" {
                if self.traitCollection.userInterfaceStyle == .dark {
                    content.attributedText = self.set(image: UIImage(systemName: "globe")!.withTintColor(.white), with: "  \(group.name)", size: 15, y: -4)
                } else {
                    content.attributedText = self.set(image: UIImage(systemName: "globe")!, with: "  \(group.name)", size: 15, y: -4)
                }
            } else if group.parent == "" {
                if self.traitCollection.userInterfaceStyle == .dark {
                    content.attributedText = self.set(image: UIImage(systemName: "lock.fill")!.withTintColor(.white), with: "  \(group.name)", size: 15, y: -4)
                } else {
                    content.attributedText = self.set(image: UIImage(systemName: "lock.fill")!, with: "  \(group.name)", size: 15, y: -4)
                }
            } else {
                content.text = group.name
            }
            if group.childs.count > 0 {
                let iconName = (group.isSelected) ? "chevron.up.circle" : "chevron.down.circle"
                let imageView = UIImageView(image: UIImage(systemName: iconName))
                imageView.tintColor = .black
                cell.accessoryView = imageView
            }
            else {
                cell.accessoryView = nil
                cell.accessoryType = .none
            }
            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            getImage(name: group.profile, placeholderImage: UIImage(named: "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                content.image = image
            }
            cell.contentConfiguration = content
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierContact", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = ""
            cell.contentConfiguration = content
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
}


extension ContactChatViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
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
