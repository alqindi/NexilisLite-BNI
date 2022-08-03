//
//  SettingTableViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 16/09/21.
//

import UIKit
import NotificationBannerSwift
import nuSDKService
import Photos

public class SettingTableViewController: UITableViewController {
    
    var language: [[String: String]] = [["Indonesia": "id"],["English": "en"]]
    var alert: UIAlertController?
    var textFields = [UITextField]()
    
    var switchVibrateMode = UISwitch()
    var switchSaveToGallery = UISwitch()
    var switchAutoDownload = UISwitch()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings".localized()
        
        makeMenu()
        
        switchVibrateMode.tintColor = .gray
        switchSaveToGallery.tintColor = .gray
        switchAutoDownload.tintColor = .gray
        switchVibrateMode.onTintColor = .mainColor
        switchSaveToGallery.onTintColor = .mainColor
        switchAutoDownload.onTintColor = .mainColor
        let vibrateMode = UserDefaults.standard.bool(forKey: "vibrateMode")
        let saveGallery = UserDefaults.standard.bool(forKey: "saveToGallery")
        let autoDownload = UserDefaults.standard.bool(forKey: "autoDownload")
        if vibrateMode {
            switchVibrateMode.setOn(true, animated: false)
        }
        if saveGallery {
            switchSaveToGallery.setOn(true, animated: false)
        }
        if autoDownload {
            switchAutoDownload.setOn(true, animated: false)
        }
        switchVibrateMode.addTarget(self, action: #selector(vibrateModeSwitch), for: .valueChanged)
        switchSaveToGallery.addTarget(self, action: #selector(saveToGallerySwitch), for: .valueChanged)
        switchAutoDownload.addTarget(self, action: #selector(autoDownloadSwitch), for: .valueChanged)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
    }
    
    @objc func didTapCancel(sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func vibrateModeSwitch() {
        UserDefaults.standard.set(switchVibrateMode.isOn, forKey: "vibrateMode")
    }
    
    @objc func saveToGallerySwitch() {
        if switchSaveToGallery.isOn {
            PHPhotoLibrary.requestAuthorization({status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        UserDefaults.standard.set(self.switchSaveToGallery.isOn, forKey: "saveToGallery")
                    } else {
                        self.switchSaveToGallery.setOn(false, animated: true)
                    }
                }
            })
        } else {
            UserDefaults.standard.set(self.switchSaveToGallery.isOn, forKey: "saveToGallery")
        }
    }
    
    @objc func autoDownloadSwitch() {
        UserDefaults.standard.set(switchAutoDownload.isOn, forKey: "autoDownload")
    }
    
    func makeMenu(imageSignIn: String = "") {
        let isChangeProfile = UserDefaults.standard.bool(forKey: "is_change_profile")
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if !isChangeProfile {
                Item.menus["Personal"] = [
                    Item(icon: UIImage(systemName: "person.crop.circle.badge.plus"), title: "Sign-Up (Change profile)".localized()),
                    Item(icon: UIImage(systemName: "arrow.up.and.person.rectangle.portrait"), title: "Sign-In (Change Device)".localized())
                ]
            } else {
                Item.menus["Personal"] = [
                    Item(icon: UIImage(systemName: "person.fill"), title: "User Profile Management".localized()),
//                    Item(icon: UIImage(systemName: "mail"), title: "Email".localized()),
                    Item(icon: UIImage(systemName: "qrcode.viewfinder"), title: "Login to Nexilis Web".localized()),
                    Item(icon: UIImage(systemName: "rectangle.portrait.and.arrow.right"), title: "Logout".localized())
                ]
                let idMe = UserDefaults.standard.string(forKey: "me") as String?
                if let cursorUser = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type, image_id FROM BUDDY where f_pin='\(idMe!)'"), cursorUser.next() {
                    var groupId = ""
                    if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id FROM GROUPZ where group_type = 1 AND official = 1"), cursorGroup.next() {
                        groupId = cursorGroup.string(forColumnIndex: 0) ?? ""
                        cursorGroup.close()
                    }
                    var position = ""
                    if let cursorIsAdmin = Database.shared.getRecords(fmdb: fmdb, query: "SELECT position FROM GROUPZ_MEMBER where group_id = '\(groupId)' AND f_pin = '\(idMe!)'"), cursorIsAdmin.next() {
                        position = cursorIsAdmin.string(forColumnIndex: 0) ?? ""
                        cursorIsAdmin.close()
                    }
                    if cursorUser.string(forColumnIndex: 0) == "23" && position == "1" {
                        Item.menus["Personal"]?.insert(Item(icon: UIImage(systemName: "person.crop.rectangle"), title: "Change Admin / Internal Password".localized()), at: 1)
                        Item.menus["Personal"]?.insert(Item(icon: UIImage(named: "ic_internal_cc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), title: "Set Internal / Officer Account".localized()), at: 2)
                        Item.menus["Personal"]?.insert(Item(icon: UIImage(systemName: "iphone.homebutton"), title: "Pulsa".localized()), at: 4)
                    } else if cursorUser.string(forColumnIndex: 0) != "23" && cursorUser.string(forColumnIndex: 0) != "24" {
                        Item.menus["Personal"]?.insert(Item(icon: UIImage(systemName: "person.crop.rectangle"), title: "Sign In Admin / Internal".localized()), at: 1)
                    } else {
                        Item.menus["Personal"]?.insert(Item(icon: UIImage(systemName: "iphone.homebutton"), title: "Pulsa".localized()), at: 2)
                    }
                    let image = cursorUser.string(forColumnIndex: 1)
                    if image != nil {
                        if !image!.isEmpty {
                            do {
                                let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                let file = documentDir.appendingPathComponent(image!)
                                if FileManager().fileExists(atPath: file.path) {
                                    let image = UIImage(contentsOfFile: file.path)
                                    Item.menus["Personal"]?[0].icon = image?.circleMasked
                                    if !imageSignIn.isEmpty {
                                        var dataImage: [AnyHashable : Any] = [:]
                                        dataImage["name"] = imageSignIn
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                    }
                                } else {
                                    Download().start(forKey: image!) { (name, progress) in
                                        guard progress == 100 else {
                                            return
                                        }

                                        DispatchQueue.main.async {
                                            let image = UIImage(contentsOfFile: file.path)
                                            Item.menus["Personal"]?[0].icon = image?.circleMasked
                                            self.tableView.reloadData()
                                            if !imageSignIn.isEmpty {
                                                var dataImage: [AnyHashable : Any] = [:]
                                                dataImage["name"] = imageSignIn
                                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                            }
                                        }
                                    }
                                }
                            } catch {}
                        }
                    }
                    cursorUser.close()
                } else {
                    if !imageSignIn.isEmpty {
                        do {
                            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                            let file = documentDir.appendingPathComponent(imageSignIn)
                            if FileManager().fileExists(atPath: file.path) {
                                let image = UIImage(contentsOfFile: file.path)
                                Item.menus["Personal"]?[0].icon = image?.circleMasked
                                var dataImage: [AnyHashable : Any] = [:]
                                dataImage["name"] = imageSignIn
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                            } else {
                                Download().start(forKey: imageSignIn) { (name, progress) in
                                    guard progress == 100 else {
                                        return
                                    }
                                    DispatchQueue.main.async {
                                        let image = UIImage(contentsOfFile: file.path)
                                        Item.menus["Personal"]?[0].icon = image?.circleMasked
                                        self.tableView.reloadData()
                                        var dataImage: [AnyHashable : Any] = [:]
                                        dataImage["name"] = imageSignIn
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                    }
                                }
                            }
                        } catch {}
                    }
                }
            }
        })
        
//        Item.menus["Language"] = [
//            Item(icon: UIImage(systemName: "textformat.abc"), title: "Change Language".localized()),
//        ]
        
        Item.menus["Call"] = [
            Item(icon: UIImage(systemName: "message"), title: "Incoming Message(s)".localized()),
            Item(icon: UIImage(systemName: "phone"), title: "Incoming Call(s)".localized()),
            Item(icon: UIImage(systemName: "iphone.homebutton.radiowaves.left.and.right"), title: "Vibrate Mode".localized()),
            Item(icon: UIImage(systemName: "photo.on.rectangle.angled"), title: "Save to Gallery".localized()),
            Item(icon: UIImage(systemName: "arrow.down.square"), title: "Auto Download".localized()),
        ]
        Item.menus["Version"] = [
            Item(icon: UIImage(systemName: "gear"), title: "Version".localized()),
            Item(icon: UIImage(named: "pb_powered", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), title: "Powered by Nexilis".localized()),
        ]
    }
    
    // MARK: - Table view data source
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return Item.sections.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Item.menuFor(section: section).count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.accessoryType = .none
        cell.selectionStyle = .gray
        var content = cell.defaultContentConfiguration()
        content.textProperties.font = UIFont.systemFont(ofSize: 14)
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14)
        content.secondaryTextProperties.color = .gray
        content.prefersSideBySideTextAndSecondaryText = true
        let section = Item.sections[indexPath.section]
        if let arr = Item.menus[section] {
            let menu = arr[indexPath.row]
            content.image = menu.icon
            content.imageProperties.tintColor = .mainColor
            content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
            content.text = menu.title
            cell.accessoryView = nil
            switch menu.title {
            case "User Profile Management".localized():
                cell.accessoryType = .disclosureIndicator
            case "Sign In Admin / Internal".localized():
                cell.accessoryType = .disclosureIndicator
            case "Change Admin / Internal Password".localized():
                cell.accessoryType = .disclosureIndicator
            case "Set Internal / Officer Account".localized():
                cell.accessoryType = .disclosureIndicator
            case "Pulsa".localized():
                cell.accessoryType = .disclosureIndicator
            case "Sign-Up (Change profile)".localized():
                cell.accessoryType = .disclosureIndicator
            case "Sign-In (Change Device)".localized():
                cell.accessoryType = .disclosureIndicator
            case "Login to Nexilis Web".localized():
                cell.accessoryType = .disclosureIndicator
            case "Change Language".localized():
                cell.accessoryType = .disclosureIndicator
            case "Version".localized():
                content.secondaryText = UIApplication.appVersion
            case "Vibrate Mode".localized():
                cell.accessoryView = switchVibrateMode
            case "Save to Gallery".localized():
                cell.accessoryView = switchSaveToGallery
            case "Auto Download".localized():
                cell.accessoryView = switchAutoDownload
            default:
                content.secondaryText = nil
            }
        }
        cell.contentConfiguration = content
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let item = Item.menuFor(section: indexPath.section)[indexPath.row]
        if item.title == "User Profile Management".localized() {
            let isChangeProfile = UserDefaults.standard.bool(forKey: "is_change_profile")
            if isChangeProfile {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.data = UserDefaults.standard.string(forKey: "me")!
                controller.flag = .me
                controller.dismissImage = { image, imageName in
                    var dataImage: [AnyHashable : Any] = [:]
                    dataImage["name"] = imageName
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                    self.makeMenu()
                    self.tableView.reloadData()
                }
                navigationController?.show(controller, sender: nil)
            }
        } else if item.title == "Sign-Up (Change profile)".localized() {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNS") as! ChangeNamePassswordViewController
            controller.fromSetting = true
            controller.isSuccess = {
                self.makeMenu()
                self.tableView.reloadData()
            }
            navigationController?.show(controller, sender: nil)
        } else if item.title == "Change Language".localized() {
            let vc = UIViewController()
            vc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width - 10, height: 150)
            let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 10, height: 150))
            pickerView.dataSource = self
            pickerView.delegate = self
            
            let lang = UserDefaults.standard.string(forKey: "i18n_language")
            var index = 1
            if lang == "id" {
                index = 0
            }
            pickerView.selectRow(index, inComponent: 0, animated: false)
            
            vc.view.addSubview(pickerView)
            pickerView.translatesAutoresizingMaskIntoConstraints = false
            pickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
            pickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
            
            let alert = UIAlertController(title: "Select Language".localized(), message: "", preferredStyle: .actionSheet)
            
            alert.setValue(vc, forKey: "contentViewController")
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (UIAlertAction) in
            }))
            
            alert.addAction(UIAlertAction(title: "Select", style: .default, handler: { (UIAlertAction) in
                let selectedIndex = pickerView.selectedRow(inComponent: 0)
                let lang = self.language[selectedIndex].values.first
                UserDefaults.standard.set(lang, forKey: "i18n_language")
                self.viewDidLoad()
            }))
            self.present(alert, animated: true, completion: nil)
        } else if item.title == "Sign-In (Change Device)".localized() {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeDevice") as! ChangeDeviceViewController
            controller.isDismiss = { newThumb in
                self.makeMenu(imageSignIn: newThumb)
                self.tableView.reloadData()
            }
            navigationController?.show(controller, sender: nil)
        } else if item.title == "Logout".localized() {
            let alert = UIAlertController(title: "Logout".localized(), message: "Are you sure want to logout?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: .destructive, handler: {(_) in
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                DispatchQueue.global().async {
                    self.deleteAllRecordDatabase()
                    Nexilis.destroyAll()
                    let apiKey = Nexilis.sAPIKey
                    var id = UIDevice.current.identifierForVendor?.uuidString ?? "UNK-DEVICE"
                    if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignUpApi(api: apiKey, p_pin: id), timeout: 30 * 1000) {
                        id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                        if(!id.isEmpty){
                            Nexilis.changeUser(f_pin: id)
                            UserDefaults.standard.setValue(id, forKey: "me")
                            UserDefaults.standard.set("", forKey: "pwd")
                            UserDefaults.standard.set(false, forKey: "is_change_profile")
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
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Successfully Logout".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                                var dataImage: [AnyHashable : Any] = [:]
                                dataImage["name"] = ""
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                self.makeMenu()
                                self.tableView.reloadData()
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
            }))
            self.present(alert, animated: true, completion: nil)
        } else if item.title == "Sign In Admin / Internal".localized() || item.title == "Change Admin / Internal Password".localized() {
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            if(item.title.contains("Change")){
                if let action = self.actionChangePassword(for: "admin", title: "Change Admin Password".localized()) {
                    alertController.addAction(action)
                }
                if let action = self.actionChangePassword(for: "internal", title: "Change Internal Password".localized()) {
                    alertController.addAction(action)
                }
            }
            else {
                if let action = self.actionLogin(for: "admin", title: "Login as Admin".localized()) {
                    alertController.addAction(action)
                }
                if let action = self.actionLogin(for: "internal", title: "Login as Internal Team".localized()) {
                    alertController.addAction(action)
                }
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
        } else if item.title == "Login to Nexilis Web".localized() {
            var permissionCheck = -1
            if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                permissionCheck = 1
            } else if AVCaptureDevice.authorizationStatus(for: .video) ==  .denied {
                permissionCheck = 0
            } else {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
                    if granted == true {
                        permissionCheck = 1
                    } else {
                        permissionCheck = 0
                    }
                })
            }
            
            while permissionCheck == -1 {
                sleep(1)
            }
            
            if permissionCheck == 0 {
                let alert = UIAlertController(title: "Attention!".localized(), message: "Please allow camera permission in your settings".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                }
                return
            }
            let controller = ScannerViewController()
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.navigationBar.tintColor = .white
            navigationController.navigationBar.barTintColor = .mainColor
            navigationController.navigationBar.isTranslucent = false
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController.navigationBar.titleTextAttributes = textAttributes
            navigationController.view.backgroundColor = .mainColor
            navigationController.modalPresentationStyle = .custom
            self.present(navigationController, animated: true)
        } else if item.title == "Pulsa".localized() {
            self.alert = UIAlertController(title: "Data warning in (IDR)".localized(), message: nil, preferredStyle: .alert)
            self.textFields.removeAll()
            self.alert?.addTextField{ (texfield) in
                texfield.placeholder = "Saldo"
                texfield.keyboardType = .numberPad
                texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
            }
            let submitAction = UIAlertAction(title: "Submit".localized(), style: .default, handler: { (action) -> Void in
                let textField = self.alert?.textFields![0]
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                DispatchQueue.global().async {
                    let _ = Nexilis.writeSync(message: CoreMessage_TMessageBank.isiPulsaBNI(value: textField!.text!), timeout: 30 * 1000)
                }
                
            })
            submitAction.isEnabled = false
            self.alert?.addAction(submitAction)
            self.alert?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            
            self.present(self.alert!, animated: true, completion: nil)
        } else if item.title == "Set Internal / Officer Account".localized() {
            let controller = QmeraCallContactViewController()
            controller.isDismiss = { user in
                if user.userType != "23" && user.userType != "24" {
                    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alertController.addAction(UIAlertAction(title: "Set \(user.fullName) as Internal".localized(), style: .default, handler: { _ in
                        self.setAsInternalAccount(user: user)
                    }))
                    alertController.addAction(UIAlertAction(title: "Set \(user.fullName) as Call Center".localized(), style: .default, handler: { _ in
                        let viewSetOfficer = SetOfficerBNI()
                        viewSetOfficer.f_pin = user.pin
                        viewSetOfficer.name = user.fullName
                        viewSetOfficer.modalTransitionStyle = .crossDissolve
                        viewSetOfficer.modalPresentationStyle = .custom
                        self.present(viewSetOfficer, animated: true)
                    }))
                    alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                    self.present(alertController, animated: true)
                } else if user.userType == "24" {
                    self.removeFromCCAccount(user: user)
                } else {
                    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alertController.addAction(UIAlertAction(title: "Remove \(user.fullName) from Internal".localized(), style: .default, handler: { _ in
                        self.removeFromInternalAccount(user: user)
                    }))
                    alertController.addAction(UIAlertAction(title: "Set \(user.fullName) as Call Center".localized(), style: .default, handler: { _ in
                        let viewSetOfficer = SetOfficerBNI()
                        viewSetOfficer.f_pin = user.pin
                        viewSetOfficer.name = user.fullName
                        viewSetOfficer.modalTransitionStyle = .crossDissolve
                        viewSetOfficer.modalPresentationStyle = .custom
                        self.present(viewSetOfficer, animated: true)
                    }))
                    alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                    self.present(alertController, animated: true)
                }
            }
            present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
        }
    }
    
    private func setAsInternalAccount(user: User) {
        self.alert = UIAlertController(title: "Set Internal Account".localized(), message: "Are you sure want to add \(user.fullName) to Internal Account?", preferredStyle: .alert)
        self.alert?.addAction(UIAlertAction(title: "Yes".localized(), style: .default, handler: { (action) -> Void in
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getManagementContactCenter(user_type: "3", l_pin: user.pin)) {
                if response.isOk() {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }))
        self.alert?.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
        self.present(self.alert!, animated: true, completion: nil)
    }
    
    private func removeFromCCAccount(user: User) {
        self.alert = UIAlertController(title: "Remove Officer Account".localized(), message: "Are you sure want to remove \(user.fullName) from Officer Account?", preferredStyle: .alert)
        self.alert?.addAction(UIAlertAction(title: "Yes".localized(), style: .default, handler: { (action) -> Void in
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getManagementContactCenter(user_type: "0", l_pin: user.pin)) {
                if response.isOk() {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }))
        self.alert?.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
        self.present(self.alert!, animated: true, completion: nil)
    }
    
    private func removeFromInternalAccount(user: User) {
        self.alert = UIAlertController(title: "Remove Officer Account".localized(), message: "Are you sure want to remove \(user.fullName) from Internal Account?", preferredStyle: .alert)
        self.alert?.addAction(UIAlertAction(title: "Yes".localized(), style: .default, handler: { (action) -> Void in
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getManagementContactCenter(user_type: "2", l_pin: user.pin)) {
                if response.isOk() {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }))
        self.alert?.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
        self.present(self.alert!, animated: true, completion: nil)
    }
    
    private func actionLogin(for type: String, title: String) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .default) { _ in
            self.alert = UIAlertController(title: "Login as Admin".localized(), message: nil, preferredStyle: .alert)
            if type == "internal" {
                self.alert = UIAlertController(title: "Login as Internal Team".localized(), message: nil, preferredStyle: .alert)
            }
            self.textFields.removeAll()
            self.alert?.addTextField{ (texfield) in
                texfield.placeholder = "Password"
                texfield.isSecureTextEntry = true
                texfield.addPadding(.right(40))
                texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
                
                let buttonHideUnhide = UIButton()
                buttonHideUnhide.tag = 0
                texfield.addSubview(buttonHideUnhide)
                buttonHideUnhide.anchor(top: texfield.topAnchor, right: texfield.rightAnchor, paddingTop: -7, width: 30, height: 30)
                buttonHideUnhide.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
                buttonHideUnhide.tintColor = .black
                buttonHideUnhide.addTarget(self, action: #selector(self.showPassword), for: .touchUpInside)
            }
            let submitAction = UIAlertAction(title: "Sign In".localized(), style: .default, handler: { (action) -> Void in
                let textField = self.alert?.textFields![0]
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                if type == "admin" {
                    self.signInAdmin(password: textField!.text!, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Successfully login Admin".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                                let itemCP = Item(icon: UIImage(systemName: "person.crop.rectangle"), title: "Change Admin / Internal Password".localized())
                                Item.menus["Personal"]?[1] = itemCP
                                self.tableView.reloadData()
                            }
                        }
                    })
                } else {
                    self.signInInternal(password: textField!.text!, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Successfully login Internal Team".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                                Item.menus["Personal"]?.remove(at: 1)
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
            })
            submitAction.isEnabled = false
            self.alert?.addAction(submitAction)
            self.alert?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            
            self.present(self.alert!, animated: true, completion: nil)
        }
    }
    
    private func actionChangePassword(for type: String, title: String) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .default) { _ in
            self.alert = UIAlertController(title: "Change Admin Password".localized(), message: nil, preferredStyle: .alert)
            if type == "internal" {
                self.alert = UIAlertController(title: "Change Internal Password".localized(), message: nil, preferredStyle: .alert)
            }
            self.textFields.removeAll()
            self.alert?.addTextField{ (texfield) in
                texfield.placeholder = "Old Password"
                texfield.isSecureTextEntry = true
                texfield.addPadding(.right(40))
                texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
                self.textFields.append(texfield)
                
                let buttonHideUnhide = UIButton()
                buttonHideUnhide.tag = 0
                texfield.addSubview(buttonHideUnhide)
                buttonHideUnhide.anchor(top: texfield.topAnchor, right: texfield.rightAnchor, paddingTop: -7, width: 30, height: 30)
                buttonHideUnhide.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
                buttonHideUnhide.tintColor = .black
                buttonHideUnhide.addTarget(self, action: #selector(self.showPassword), for: .touchUpInside)
            }
            self.alert?.addTextField{ (texfield) in
                texfield.placeholder = "New Password"
                texfield.isSecureTextEntry = true
                texfield.addPadding(.right(40))
                texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
                self.textFields.append(texfield)
                
                let buttonHideUnhide = UIButton()
                buttonHideUnhide.tag = 1
                texfield.addSubview(buttonHideUnhide)
                buttonHideUnhide.anchor(top: texfield.topAnchor, right: texfield.rightAnchor, paddingTop: -7, width: 30, height: 30)
                buttonHideUnhide.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
                buttonHideUnhide.tintColor = .black
                buttonHideUnhide.addTarget(self, action: #selector(self.showPassword), for: .touchUpInside)
            }
            let submitAction = UIAlertAction(title: "Change Password".localized(), style: .default, handler: { (action) -> Void in
                let textFieldOld = self.alert?.textFields![0]
                let textFieldNew = self.alert?.textFields![1]
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                if type == "admin" {
                    self.changePasswordAdmin(oldPassword: textFieldOld!.text!, newPassword: textFieldNew!.text!, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Admin password changed successfully".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        }
                    })
                } else {
                    self.changePasswordInternal(oldPassword: textFieldOld!.text!, newPassword: textFieldNew!.text!, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Internal password changed successfully".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        }
                    })
                }
            })
            submitAction.isEnabled = false
            self.alert?.addAction(submitAction)
            self.alert?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            
            self.present(self.alert!, animated: true, completion: nil)
        }
    }
    
    @objc func showPassword(_ sender:UIButton) {
        if alert!.textFields![sender.tag].isSecureTextEntry {
            alert!.textFields![sender.tag].isSecureTextEntry = false
            let buttonImage = alert!.textFields![sender.tag].subviews[0] as! UIButton
            buttonImage.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            alert!.textFields![sender.tag].isSecureTextEntry = true
            let buttonImage = alert!.textFields![sender.tag].subviews[0] as! UIButton
            buttonImage.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }
    
    @objc func alertTextFieldDidChange(_ sender: UITextField) {
        if(!textFields.isEmpty){
            alert?.actions[0].isEnabled = textFields[0].text!.count > 0 && textFields[1].text!.count > 0
        }
        else {
            alert?.actions[0].isEnabled = sender.text!.count > 0
        }
    }
    
    private func signInAdmin(password: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            let p_password = password
            let md5Hex = Utils.getMD5(string: p_password).map { String(format: "%02hhx", $0) }.joined()
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignInApiAdmin(p_name: idMe!, p_password: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
            completion(result)
        }
    }
    
    private func signInInternal(password: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            let p_password = password
            let md5Hex = Utils.getMD5(string: p_password).map { String(format: "%02hhx", $0) }.joined()
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignInApiInternal(p_name: idMe!, p_password: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
            completion(result)
        }
    }
    
    private func changePasswordAdmin(oldPassword: String, newPassword: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            let p_password = oldPassword
            let n_password = newPassword
            let md5Hex = Utils.getMD5(string: p_password).map { String(format: "%02hhx", $0) }.joined()
            let md5HexNew = Utils.getMD5(string: n_password).map { String(format: "%02hhx", $0) }.joined()
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getChangePasswordAdmin(p_f_pin: idMe!, pwd_en: md5HexNew, pwd_old: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
            completion(result)
        }
    }
    
    private func changePasswordInternal(oldPassword: String, newPassword: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            let p_password = oldPassword
            let n_password = newPassword
            let md5Hex = Utils.getMD5(string: p_password).map { String(format: "%02hhx", $0) }.joined()
            let md5HexNew = Utils.getMD5(string: n_password).map { String(format: "%02hhx", $0) }.joined()
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getChangePasswordInternal(p_f_pin: idMe!, pwd_en: md5HexNew, pwd_old: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
            completion(result)
        }
    }
}

// MARK: - Item

struct Item: Hashable {
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.title == rhs.title
    }
    
    var icon: UIImage?
    var title = ""
    
    static var sections: [String] {
        return ["Personal", "Call", "Version"]
    }
    
    static var menus: [String: [Item]] = [:]
    
    static func menuFor(section: Int) -> [Item] {
        let sec = sections[section]
        if let arr = menus[sec] {
            return arr
        }
        return []
    }
    
}

extension SettingTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return language.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 60
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 10, height: 30))
        label.text = (language[row]).keys.first
        label.sizeToFit()
        return label
    }
}
