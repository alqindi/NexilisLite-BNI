//
//  ChangePasswordViewController.swift
//  NexilisLite
//
//  Created by Qindi on 23/03/22.
//

import UIKit
import NotificationBannerSwift

class ChangePasswordViewController: UIViewController {
    @IBOutlet weak var oldPassField: PasswordTextField!
    @IBOutlet weak var newPassField: PasswordTextField!
    @IBOutlet weak var showOldPassButton: UIButton!
    @IBOutlet weak var showNewPassButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Change Password".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next".localized(), style: .plain, target: self, action: #selector(didTapNext(sender:)))
        
        oldPassField.addPadding(.right(40))
        oldPassField.isSecureTextEntry = false
        
        newPassField.addPadding(.right(40))
        newPassField.isSecureTextEntry = false
        
        showOldPassButton.addTarget(self, action: #selector(showOldPassword), for: .touchUpInside)
        showNewPassButton.addTarget(self, action: #selector(showNewPassword), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func didTapNext(sender: Any) {
        guard let odlPassword = oldPassField.text, !odlPassword.isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Old password can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if odlPassword.count < 6 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Old password min 6 character".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if odlPassword != UserDefaults.standard.string(forKey: "pwd"){
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Incorrect old password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        guard let newPassword = newPassField.text, !newPassword.isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "New password can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if newPassword.count < 6 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "New password min 6 character".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let idMe = UserDefaults.standard.string(forKey: "me")!
        DispatchQueue.global().async {
            let tMessage = CoreMessage_TMessageBank.getChangePersonInfo_New(p_f_pin: idMe)
            let md5HexOld = Utils.getMD5(string: odlPassword).map { String(format: "%02hhx", $0) }.joined()
            let md5HexNew = Utils.getMD5(string: newPassword).map { String(format: "%02hhx", $0) }.joined()
            tMessage.mBodies[CoreMessage_TMessageKey.PASSWORD] = md5HexNew
            tMessage.mBodies[CoreMessage_TMessageKey.PASSWORD_OLD] = md5HexOld
            if let resp = Nexilis.writeAndWait(message: tMessage){
                if resp.isOk() {
                    UserDefaults.standard.set(newPassword, forKey: "pwd")
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully changed password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                        self.navigationController?.popViewController(animated: true)
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
    
    @objc func showOldPassword() {
        if oldPassField.isSecureTextEntry {
            oldPassField.isSecureTextEntry = false
            showOldPassButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            oldPassField.isSecureTextEntry = true
            showOldPassButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }
    
    @objc func showNewPassword() {
        if newPassField.isSecureTextEntry {
            newPassField.isSecureTextEntry = false
            showNewPassButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            newPassField.isSecureTextEntry = true
            showNewPassButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }

}
