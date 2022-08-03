//
//  ChangeDeviceViewController.swift
//  NexilisLite
//
//  Created by Qindi on 23/03/22.
//

import UIKit
import NotificationBannerSwift
import nuSDKService

public class ChangeDeviceViewController: UIViewController {
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: PasswordTextField!
    @IBOutlet weak var showPasswordButton: UIButton!
    
    public var isDismiss: ((String) -> ())?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let randomInt = Int.random(in: 5..<11)
        let image = UIImage(named: "lbackground_\(randomInt)")
        if image != nil {
            self.view.backgroundColor = UIColor.init(patternImage: image!)
        }

        self.title = "Change Device".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit".localized(), style: .plain, target: self, action: #selector(didTapSubmit(sender:)))
        
        passwordField.addPadding(.right(40))
        passwordField.isSecureTextEntry = true
        showPasswordButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        
        showPasswordButton.addTarget(self, action: #selector(showPassword), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func showPassword() {
        if passwordField.isSecureTextEntry {
            passwordField.isSecureTextEntry = false
            showPasswordButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            passwordField.isSecureTextEntry = true
            showPasswordButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }
    
    @objc func didTapSubmit(sender: Any) {
        guard let name = usernameField.text, !name.isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Username can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if !name.matches("^[a-zA-Z ]*$") {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Contains prohibited characters. Only alphabetic characters are allowed.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        guard let password = passwordField.text, !password.isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Password can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if password.count < 6 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Password min 6 character".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async {
            let md5Hex = Utils.getMD5(string: password).map { String(format: "%02hhx", $0) }.joined()
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignIn(p_name: name, p_password: md5Hex), timeout: 30 * 1000) {
                if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid user / Username and password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                } else if !response.isOk() {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                } else {
                    self.deleteAllRecordDatabase()
                    let id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                    let thumb = response.getBody(key: CoreMessage_TMessageKey.THUMB_ID, default_value: "")
                    if(!id.isEmpty) {
                        Nexilis.changeUser(f_pin: id)
                        UserDefaults.standard.setValue(id, forKey: "me")
                        UserDefaults.standard.set(password, forKey: "pwd")
                        UserDefaults.standard.set(true, forKey: "is_change_profile")
                        UserDefaults.standard.synchronize()
                        // pos registration
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: id))
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getServiceBNI(p_pin: id))
                        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getWorkingAreaContactCenter(), timeout: 30 * 1000) {
                            if response.isOk() {
                                let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "[]")
                                if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                        for json in jsonArray{
                                            _ = try? Database.shared.insertRecord(fmdb: fmdb, table: "WORKING_AREA",
                                                cvalues: [
                                                    "area_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.WORKING_AREA),
                                                    "name": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.NAME),
                                                    "parent": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PARENT_ID, def: ""),
                                                    "level": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LEVEL, def: "")
                                                ],
                                                replace: true)
                                        }
                                    })
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Successfully changed device".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                            banner.show()
                            self.navigationController?.popViewController(animated: true)
                            self.isDismiss?(thumb)
                        })
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }
    }

}
