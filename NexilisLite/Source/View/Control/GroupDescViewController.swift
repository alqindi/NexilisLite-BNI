//
//  GroupDescViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 29/09/21.
//

import UIKit

class GroupDescViewController: UITableViewController {

    @IBOutlet weak var descText: UITextField!
    
    var isDismiss: (() -> ())?
    
    var data: String = ""
    
    var quote: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Change Description".localized()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
        descText.text = quote
        
        descText.addTarget(self, action: #selector(didChanged(sender:)), for: .editingChanged)
    }
    
    @objc func didChanged(sender: Any) {
        if let text = descText.text, text.trimmingCharacters(in: .whitespaces).isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if let button = navigationItem.rightBarButtonItem, !button.isEnabled {
            button.isEnabled = true
        }
    }

    @objc func save(sender: Any) {
        if let text = descText.text {
            DispatchQueue.global().async {
                if let resp = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangeGroupInfo(p_group_id: self.data, p_quote: text)) {
                    if resp.isOk() {
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "GROUPZ", cvalues: ["quote": text], _where: "group_id = '\(self.data)'")
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
