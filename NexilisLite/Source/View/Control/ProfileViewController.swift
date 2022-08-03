//
//  ProfileViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 17/09/21.
//

import UIKit
import NotificationBannerSwift
import nuSDKService

public class ProfileViewController: UITableViewController {
    
    @IBOutlet weak var profile: UIImageView!
    
    @IBOutlet weak var call: UIButton!
    @IBOutlet weak var video: UIButton!
    @IBOutlet weak var message: UIButton!
    @IBOutlet weak var viewUserType: UIView!
    @IBOutlet weak var imageUserType: UIImageView!
    @IBOutlet weak var labelUserType: UILabel!
    @IBOutlet weak var buttonGroup: UIStackView!
    @IBOutlet weak var myViewGroup: UIView!
    @IBOutlet weak var switchPrivateAccount: UISwitch!
    @IBOutlet weak var buttonEditPass: UIButton!
    @IBOutlet weak var switchAcceptCall: UISwitch!
    @IBOutlet weak var buttonHistoryCC: UIButton!
    @IBOutlet weak var viewFriend: UIView!
    @IBOutlet weak var countFriend: UILabel!
    
    private var imageVideoPicker : ImageVideoPicker!
    
    public enum Flag {
        case me
        case friend
        case invite
    }
    
    var user: User?
    
    public var data: String = ""
    
    public var flag: Flag = Flag.friend
    
    var name: String = ""
    
    var picture: String = ""
    
    var checkReadMessage: (() -> ())?
    
    public var isDismiss: (() -> ())?
    
    public var dismissImage: ((UIImage, String) -> ())?
    
    var fromRootViewController = false
    
    var isBNI = false
    
    private func reload() {
        if let user = self.user {
            self.title = "\(user.firstName) \(user.lastName)"
            if !user.thumb.isEmpty {
                self.profile.setImage(name: user.thumb)
            }
        } else {
            getData { user in
                self.user = user
                DispatchQueue.main.async {
                    guard let user = user else {
                        return
                    }
                    if let me = UserDefaults.standard.string(forKey: "me"), me == self.data || self.flag == Flag.me {
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            let idMe = UserDefaults.standard.string(forKey: "me")!
                            if let cursorCount = Database.shared.getRecords(fmdb: fmdb, query: "select COUNT(*) from BUDDY where f_pin <> '\(idMe)' "), cursorCount.next() {
                                let count = cursorCount.string(forColumnIndex: 0)!
                                self.countFriend.text = count + " " + "Friends".localized()
                                self.countFriend.font = .systemFont(ofSize: 12)
                                self.viewFriend.layer.cornerRadius = 5.0
                                self.viewFriend.clipsToBounds = true
                                self.viewFriend.isHidden = false
                                
                                self.viewFriend.isUserInteractionEnabled = true
                                self.viewFriend.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.friendsTapped)))
                                cursorCount.close()
                            }
                        })
                    }
                    if user.userType == "23" || user.userType == "24" {
                        self.viewUserType.layer.cornerRadius = 5.0
                        self.viewUserType.clipsToBounds = true
                        self.viewUserType.isHidden = false
                        if user.userType == "24" {
                            let dataCategory = CategoryCC.getDataFromServiceId(service_id: user.ex_offmp!)
                            self.imageUserType.image = UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                            if dataCategory != nil {
                                self.labelUserType.text = "Call Center (\(dataCategory!.service_name))".localized()
                            } else {
                                self.labelUserType.text = "Call Center".localized()
                            }
//                            self.buttonHistoryCC.isHidden = true
                        }
                    }
                    self.title = "\(user.firstName) \(user.lastName)"
                    if !user.thumb.isEmpty {
                        self.profile.setImage(name: user.thumb)
                    }
                }
            }
        }
    }
    
    private func getData(completion: @escaping (User?) -> ()) {
        DispatchQueue.global().async {
            var r: User?
            Database.shared.database?.inTransaction({ fmdb, rollback in
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select FIRST_NAME, LAST_NAME, IMAGE_ID, USER_TYPE, ex_offmp from BUDDY where F_PIN = '\(self.data)'"), cursor.next() {
                    r = User(pin: self.data,
                             firstName: cursor.string(forColumnIndex: 0) ?? "",
                             lastName: cursor.string(forColumnIndex: 1) ?? "",
                             thumb: cursor.string(forColumnIndex: 2) ?? "",
                             userType: cursor.string(forColumnIndex: 3) ?? "",
                            ex_offmp: cursor.string(forColumnIndex: 4) ?? "")
                    //
                    cursor.close()
                }
                let idMe = UserDefaults.standard.string(forKey: "me")!
                if let cursorCount = Database.shared.getRecords(fmdb: fmdb, query: "select COUNT(*) from BUDDY where f_pin <> '\(idMe)' "), cursorCount.next() {
                    DispatchQueue.main.async {
                        self.countFriend.text = cursorCount.string(forColumnIndex: 0) ?? "" + " " + "Friends".localized()
                    }
                    cursorCount.close()
                }
            })
            completion(r)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            self.checkReadMessage?()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        profile.circle()
        profile.contentMode = .scaleAspectFill
        
        profile.isUserInteractionEnabled = true
        profile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
        
        let randomInt = Int.random(in: 5..<11)
        let image = UIImage(named: "lbackground_\(randomInt)")
        if image != nil {
            self.view.backgroundColor = UIColor.init(patternImage: image!)
        }
        
        if fromRootViewController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapExit(sender:)))
        }
        let myData = User.getData(pin: self.data)
        if let me = UserDefaults.standard.string(forKey: "me"), me == data || flag == Flag.me {
            buttonGroup.removeFromSuperview()
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEdit(sender:)))
            imageVideoPicker = ImageVideoPicker(presentationController: self, delegate: self)
            buttonEditPass.addTarget(self, action: #selector(editPassword(sender:)), for: .touchUpInside)
            buttonHistoryCC.addTarget(self, action: #selector(historyCC(sender:)), for: .touchUpInside)
            if myData?.privacy_flag == "1" {
                switchPrivateAccount.setOn(true, animated: false)
            }
            if myData?.offline_mode == "1" {
                switchAcceptCall.setOn(false, animated: false)
            }
            switchPrivateAccount.addTarget(self, action: #selector(privateAccountSwitch), for: .valueChanged)
            switchAcceptCall.addTarget(self, action: #selector(acceptCallSwitch), for: .valueChanged)
            reload()
        } else if flag == Flag.invite {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd(sender:)))
            call.isEnabled = false
            video.isEnabled = false
            message.isEnabled = false
            myViewGroup.removeFromSuperview()
            buttonGroup.removeFromSuperview()
            title = name
            profile.setImage(name: picture)
        } else if flag == Flag.friend {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.crop.circle.badge.xmark"), style: .plain, target: self, action: #selector(didTapUnfriend(sender:)))
            if !isBNI {
                call.addTarget(self, action: #selector(call(sender:)), for: .touchUpInside)
                video.addTarget(self, action: #selector(video(sender:)), for: .touchUpInside)
                message.addTarget(self, action: #selector(chat(sender:)), for: .touchUpInside)
            } else {
                call.isEnabled = false
                video.isEnabled = false
                message.isEnabled = false
                buttonGroup.removeFromSuperview()
            }
            myViewGroup.removeFromSuperview()
            reload()
        }
    }
    
    @objc func acceptCallSwitch(mySwitch: UISwitch) {
        let value = mySwitch.isOn
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            self.switchPrivateAccount.setOn(!value, animated: true)
            return
        }
        DispatchQueue.global().async {
            let tMessage = CoreMessage_TMessageBank.getChangePersonInfo_New(p_f_pin: self.data)
            tMessage.mBodies[CoreMessage_TMessageKey.OFFLINE_MODE] = value ? "0" : "1"
            if let resp = Nexilis.writeAndWait(message: tMessage) {
                if resp.isOk() {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                            "offline_mode" : value ? "0" : "1"
                        ], _where: "f_pin = '\(self.data)'")
                    })
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                } else {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                        self.switchPrivateAccount.setOn(!value, animated: true)
                    }
                }
            }
        }
    }
    
    @objc func privateAccountSwitch(mySwitch: UISwitch) {
        let value = mySwitch.isOn
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            self.switchPrivateAccount.setOn(!value, animated: true)
            return
        }
        DispatchQueue.global().async {
            let tMessage = CoreMessage_TMessageBank.getChangePersonInfo_New(p_f_pin: self.data)
            tMessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = value ? "1" : "0"
            if let resp = Nexilis.writeAndWait(message: tMessage) {
                if resp.isOk() {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                            "privacy_flag" : value ? "1" : "0"
                        ], _where: "f_pin = '\(self.data)'")
                    })
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                } else {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                        self.switchPrivateAccount.setOn(!value, animated: true)
                    }
                }
            }
        }
    }
    
    @objc func editPassword(sender: Any) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changePWD") as! ChangePasswordViewController
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func historyCC(sender: Any) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "myHistoryCC") as! HistoryCCViewController
        if user?.userType == "24" {
            controller.isOfficer = true
        } else {
            controller.isOfficer = false
        }
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func call(sender: Any) {
        let myData = User.getData(pin: self.data)
        if myData?.ex_block == "1" || myData?.ex_block == "-1" {
            var title = "You blocked this user".localized()
            if myData?.ex_block == "-1" {
                title = "You have been blocked by this user".localized()
            }
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: title, subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let controller = QmeraAudioViewController()
        controller.user = user
        controller.isOutgoing = true
        controller.modalPresentationStyle = .overCurrentContext
        present(controller, animated: true, completion: nil)
    }
    
    @objc func video(sender: Any) {
        let myData = User.getData(pin: self.data)
        if myData?.ex_block == "1" || myData?.ex_block == "-1" {
            var title = "You blocked this user".localized()
            if myData?.ex_block == "-1" {
                title = "You have been blocked by this user".localized()
            }
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: title, subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if let user = user {
            let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
            videoVC.fPin = user.pin
            self.show(videoVC, sender: nil)
        }
    }
    
    @objc func chat(sender: Any) {
        if let _ = previousViewController as? EditorPersonal {
            navigationController?.popViewController(animated: true)
            return
        }
        if let user = self.user {
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = user.pin
            navigationController?.show(editorPersonalVC, sender: nil)
        }
    }
    
    private func addFriend(completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            guard !self.data.isEmpty else {
                completion(false)
                return
            }
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddFriendQRCode(fpin: self.data)), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    private func unFriend(completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            guard !self.data.isEmpty else {
                completion(false)
                return
            }
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.removeFriend(lpin: self.user!.pin)), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func didTapProfile() {
        if let userImage = user?.thumb {
            if !userImage.isEmpty {
                let firstAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                firstAlert.addAction(UIAlertAction(title: "Change Profile Picture".localized(), style: .default, handler: { action in
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Take Photo".localized(), style: .default, handler: { action in
                        self.imageVideoPicker.present(source: .imageCamera)
                    }))
                    alert.addAction(UIAlertAction(title: "Choose Photo".localized(), style: .default, handler: { action in
                        self.imageVideoPicker.present(source: .imageAlbum)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { action in
                        
                    }))
                    self.navigationController?.present(alert, animated: true)
                }))
                firstAlert.addAction(UIAlertAction(title: "Remove Profile Picture".localized(), style: .default, handler: { action in
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangePersonImage(thumb_id: "")), response.isOk() {
                        guard let me = UserDefaults.standard.string(forKey: "me") else {
                            return
                        }
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["image_id": ""], _where: "f_pin = '\(me)'")
                        })
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateFifthTab"), object: nil, userInfo: nil)
                        
                        DispatchQueue.main.async {
                            self.profile.image = UIImage(systemName: "person.circle.fill")!
                            self.profile.backgroundColor = .white
                            self.user?.thumb = ""
                            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Successfully removed image".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                            banner.show()
                            self.dismissImage?(UIImage(systemName: "person.circle.fill")!, "")
                        }
                    }
                }))
                firstAlert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                self.navigationController?.present(firstAlert, animated: true)
            } else {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Take Photo".localized(), style: .default, handler: { action in
                    self.imageVideoPicker.present(source: .imageCamera)
                }))
                alert.addAction(UIAlertAction(title: "Choose Photo".localized(), style: .default, handler: { action in
                    self.imageVideoPicker.present(source: .imageAlbum)
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { action in
                    
                }))
                self.navigationController?.present(alert, animated: true)
            }
        }
    }
    
    @objc func didTapAdd(sender: Any) {
        addFriend { result in
            DispatchQueue.main.async {
                if result {
                    self.isDismiss?()
                    self.navigationController?.popViewController(animated: true)
                } else {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }
    }
    
    @objc func didTapUnfriend(sender: Any) {
        let alert = UIAlertController(title: "", message: "Are you sure to unfriend \"\(self.user!.fullName)\"?".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
            self.unFriend { result in
                DispatchQueue.main.async {
                    if result {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select * from BUDDY where f_pin = '\(self.data)'"), cursor.next() {
                                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "BUDDY", _where: "f_pin = '\(self.data)'")
                                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(self.data)'")
                                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "(f_pin='\(self.data)' or l_pin='\(self.data)') and message_scope_id='3'")
                                cursor.close()
                                var data: [AnyHashable : Any] = [:]
                                data["state"] = 99
                                data["message"] = "delete_buddy,\(self.data)"
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil, userInfo: data)
                                return
                            }
                        })
                        if self.previousViewController is GroupDetailViewController || self.isBNI {
                            self.isDismiss?()
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    } else {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func didTapExit(sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapEdit(sender: Any) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNameView") as! ChangeNameTableViewController
        controller.data = data
        controller.isDismiss = {
            self.getData { user in
                self.user = user
                DispatchQueue.main.async {
                    guard let user = user else {
                        return
                    }
                    self.title = "\(user.firstName) \(user.lastName)"
                    if !user.thumb.isEmpty {
                        self.profile.setImage(name: user.thumb)
                    }
                }
            }
            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Successfully changed named".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
            banner.show()
        }
        navigationItem.backButtonTitle = ""
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func profileTapped() {
        if let me = UserDefaults.standard.string(forKey: "me"), me == data || flag == Flag.me {
            didTapProfile()
        }
    }
    
    @objc func friendsTapped() {
        if let me = UserDefaults.standard.string(forKey: "me"), me == data || flag == Flag.me {
            let controller = QmeraCallContactViewController()
            controller.modalPresentationStyle = .custom
            controller.isInviteCC = true
            controller.listFriends = true
            show(controller, sender: nil)
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            if let me = UserDefaults.standard.string(forKey: "me"), me == data || flag == Flag.me {
                return 170
            }
            return 56
        }

        return 200
    }
}

extension ProfileViewController: ImageVideoPickerDelegate {
    
    public func didSelect(imagevideo: Any?) {
        if let info = imagevideo as? [UIImagePickerController.InfoKey: Any], let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let me = UserDefaults.standard.string(forKey: "me") else {
                return
            }
            DispatchQueue.global().async {
                let resize = image.resize(target: CGSize(width: 800, height: 600))
                let documentDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileDir = documentDir.appendingPathComponent("THUMB_\(me)\(Date().currentTimeMillis().toHex())")
                if !FileManager.default.fileExists(atPath: fileDir.path), let data = resize.jpegData(compressionQuality: 0.8) {
                    try! data.write(to: fileDir)
                    Network().upload(name: fileDir.lastPathComponent) { result, progress in
                        guard result, progress == 100 else {
                            return
                        }
                        if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangePersonImage(thumb_id: fileDir.lastPathComponent)), response.isOk() {
                            Database.shared.database?.inTransaction({ fmdb, rollback in
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["image_id": fileDir.lastPathComponent], _where: "f_pin = '\(me)'")
                            })
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateFifthTab"), object: nil, userInfo: nil)
                            
                            DispatchQueue.main.async {
                                self.profile.image = image
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                self.user?.thumb = fileDir.lastPathComponent
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Successfully changed image".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                                self.dismissImage?(image, fileDir.lastPathComponent)
                            }
                        }
                    }
                }
            }
        }
    }
    
}

//let auto = UserDefaults.standard.bool(forKey: "autoDownload")
//if auto {
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//        let objectTapAuto = ObjectGesture()
//        objectTapAuto.image_id = imageChat
//        self.contentMessageTapped(objectTap)
//    })
//}
