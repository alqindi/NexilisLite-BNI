//
//  GroupCreateViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 24/09/21.
//

import UIKit

class GroupCreateViewController: UITableViewController {

    @IBOutlet weak var name: UITextField!
    
    private let id = Date().currentTimeMillis().toHex()
    
    var isDismiss: ((String) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Create Group"

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        name.addTarget(self, action: #selector(onTextChanged(sender:)), for: .editingChanged)
    }
    
    func submit(completion: @escaping (Bool) -> ()) {
        let groupName = self.name.text!
        DispatchQueue.global().async {
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getCreateGroup(p_group_id: self.id, p_group_name: groupName)), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    @objc func onTextChanged(sender: Any) {
        if let text = name.text?.trimmingCharacters(in: .whitespaces), text.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func save(sender: Any) {
        submit { result in
            DispatchQueue.main.async {
                if result {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                    self.isDismiss?(self.id)
                } else {
                    self.showToast(message: "Server busy, please try again later".localized(), seconds: 3)
                }
            }
        }
    }
    
}
