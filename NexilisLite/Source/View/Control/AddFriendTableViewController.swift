//
//  AddFriendTableViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 23/09/21.
//

import UIKit

class AddFriendTableViewController: UITableViewController {
    
    var searchController: UISearchController!
    
    var data: [User] = []
    
    var fillteredData: [User] = []
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    var isDismiss: (() -> ())?
    
    func filterContentForSearchText(_ searchText: String) {
        fillteredData = data.filter{ $0.fullName.lowercased().contains(searchText.lowercased()) }
        getDataSearch(searchText: searchText) { data in
            let r = data.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
            self.fillteredData.append(contentsOf: r.filter { !self.fillteredData.contains($0) })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        isDismiss?()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Friends".localized()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(sender:)))
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        tableView.tableFooterView = UIView()
        
        getData { d in
            self.data = d
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Data source
    
    func getData(completion: @escaping ([User])->()) {
        DispatchQueue.global().async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getPersonSuggestion(p_last_seq: "0")),
               response.isOk() {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                guard !data.isEmpty else {
                    return
                }
                if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!, options: []) as? [[String: String?]] {
                    var users = jsonArray.map { json in
                        User(pin: (json[CoreMessage_TMessageKey.F_PIN] ?? "") ?? "",
                             firstName: (json[CoreMessage_TMessageKey.FIRST_NAME] ?? "") ?? "",
                             lastName: (json[CoreMessage_TMessageKey.LAST_NAME] ?? "") ?? "",
                             thumb: (json[CoreMessage_TMessageKey.THUMB_ID] ?? "") ?? "")
                    }
                    users = users.filter({ $0.fullName != "USR\($0.pin)" })
                    completion(users)
                }
            }
        }
    }
    
    func getDataSearch(searchText: String, completion: @escaping ([User]) -> ()) {
        DispatchQueue.global().async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSearchFriend(search_keyword: searchText, limit: "10")), response.isOk() {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                guard !data.isEmpty else {
                    return
                }
                if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!, options: []) as? [[String: String?]] {
                    var users = jsonArray.map { json in
                        User(pin: (json[CoreMessage_TMessageKey.F_PIN] ?? "") ?? "",
                             firstName: (json[CoreMessage_TMessageKey.FIRST_NAME] ?? "") ?? "",
                             lastName: (json[CoreMessage_TMessageKey.LAST_NAME] ?? "") ?? "",
                             thumb: (json[CoreMessage_TMessageKey.THUMB_ID] ?? "") ?? "")
                    }
                    users = users.filter({ $0.fullName != "USR\($0.pin)" })
                    completion(users)
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Suggestions"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user: User
        if isFilltering {
            user = fillteredData[indexPath.row]
        } else {
            user = data[indexPath.row]
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        controller.flag = .invite
        controller.data = user.pin
        controller.name = user.fullName
        controller.picture = user.thumb
        controller.isDismiss = {
            self.getData { d in
                self.data = d
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        navigationController?.show(controller, sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFilltering {
            return fillteredData.count
        }
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let user: User
        if isFilltering {
            user = fillteredData[indexPath.row]
        } else {
            user = data[indexPath.row]
        }
        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        getImage(name: user.thumb, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
            content.image = image
        })
        content.text = user.fullName
        content.textProperties.font = UIFont.systemFont(ofSize: 14)
        cell.contentConfiguration = content
        return cell
    }
    
}

// MARK: - Extension

extension AddFriendTableViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
}
