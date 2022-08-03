//
//  ChangeNameTableViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 17/09/21.
//

import UIKit
import NotificationBannerSwift

class ChangeNameTableViewController: UITableViewController {
    
    @IBOutlet weak var name: UITextField!
    var isDismiss: (() -> ())?
    
    var data: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(sender:)))
        
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select FIRST_NAME || ' ' || ifnull(LAST_NAME, '') from BUDDY where F_PIN = '\(data)'"), cursor.next() {
                name.text = cursor.string(forColumnIndex: 0)?.trimmingCharacters(in: .whitespaces)
                cursor.close()
            }
        })
    }
    
    @objc func save(sender: Any) {
        guard let name = self.name.text, !name.isEmpty else {
            return
        }
        let a = name.split(separator: " ", maxSplits: 1)
        let first = String(a[0])
        let last = a.count == 2 ? String(a[1]) : ""
        DispatchQueue.global().async {
            if let resp = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangePersonInfoName(firstname: first, lastname: last)) {
                if resp.isOk() {
                    Database.shared.database?.inTransaction({ fmdb, rollback in
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["first_name": first , "last_name": last], _where: "f_pin = '\(self.data)'")
                    })
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateFifthTab"), object: nil, userInfo: nil)
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                        self.isDismiss?()
                    }
                } else if resp.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "1a" {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username has been registered, please use another name".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            }
        }
        
    }
}
