//
//  GroupNameViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 21/10/21.
//

import UIKit

class GroupNameViewController: UITableViewController {

    @IBOutlet weak var textField: UITextField!
    
    var isDismiss: (() -> ())?
    
    var data: String = ""
    
    var name: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Change Group Name".localized()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        textField.text = name
        textField.addTarget(self, action: #selector(didChanged(sender:)), for: .editingChanged)
        
    }

    @objc func didChanged(sender: Any) {
        if let text = textField.text, text.trimmingCharacters(in: .whitespaces).isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if let button = navigationItem.rightBarButtonItem, !button.isEnabled {
            button.isEnabled = true
        }
    }

    @objc func save(sender: Any) {
        if let text = textField.text {
            DispatchQueue.global().async {
                if let resp = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangeGroupInfo(p_group_id: self.data, p_name: text)) {
                    if resp.isOk() {
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "GROUPZ", cvalues: ["f_name": text], _where: "group_id = '\(self.data)'")
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
