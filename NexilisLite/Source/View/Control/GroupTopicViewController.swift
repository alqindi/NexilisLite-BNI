//
//  GroupTopicViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 30/09/21.
//

import UIKit

class GroupTopicViewController: UITableViewController {

    @IBOutlet weak var topic: UITextField!
    
    var isDismiss: (() -> ())?
    
    var data: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Topic".localized()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        topic.addTarget(self, action: #selector(didChanged(sender:)), for: .editingChanged)
    }

    @objc func didChanged(sender: Any) {
        if let text = topic.text, text.trimmingCharacters(in: .whitespaces).isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if let button = navigationItem.rightBarButtonItem, !button.isEnabled {
            button.isEnabled = true
        }
    }

    @objc func save(sender: Any) {
        let id = Date().currentTimeMillis().toHex()
        if let text = topic.text {
            DispatchQueue.global().async {
                if let resp = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getCreateChat(chat_id: id, title: text, group_id: self.data)) {
                    if resp.isOk() {
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            _ = try! Database.shared.insertRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", cvalues: ["chat_id": id, "title": text, "group_id": self.data, "scope_id": "4"], replace: true)
                        })
                        DispatchQueue.main.async {
                            self.navigationController?.dismiss(animated: true, completion: {
                                self.isDismiss?()
                            })
                        }
                    }
                }
            }
        }
    }
    
}
