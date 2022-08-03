//
//  EditorGroup.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 20/09/21.
//

import UIKit
import AVKit
import AVFoundation
import QuickLook
import ReadabilityKit
import Photos

public class EditorGroup: UIViewController {
    @IBOutlet var viewButton: UIView!
    @IBOutlet var constraintViewTextField: NSLayoutConstraint!
    @IBOutlet var buttonVoice: UIButton!
    @IBOutlet var buttonSendImage: UIButton!
    @IBOutlet var buttonSendPhoto: UIButton!
    @IBOutlet var buttonSendSticker: UIButton!
    @IBOutlet var buttonSendFile: UIButton!
    @IBOutlet var textFieldSend: UITextView!
    @IBOutlet var heightTextFieldSend: NSLayoutConstraint!
    @IBOutlet var buttonSendChat: UIButton!
    @IBOutlet var tableChatView: UITableView!
    @IBOutlet var constraintTopTextField: NSLayoutConstraint!
    @IBOutlet var constraintBottomAttachment: NSLayoutConstraint!
    @IBOutlet var viewTextfield: UIView!
    public var dataGroup: [String: Any?] = [:]
    public var dataTopic: [String: Any?] = [:]
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []
    public var dataMessageForward: [[String: Any?]]?
    var imageVideoPicker: ImageVideoPicker!
    var documentPicker: DocumentPicker!
    var currentIndexpath: IndexPath?
    var previewItem: NSURL?
    var reffId: String?
    var stickers = [String]()
    public var unique_l_pin = ""
    public var fromNotification = false
    var isHistoryCC = false
    var complaintId = ""
    var counter = 0
    var markerCounter: String?
    var buttonScrollToBottom = UIButton()
    let indicatorCounterBSTB = UIView()
    let labelCounter = UILabel()
    let containerActionGroup = UIView()
    var removed = false
    var copySession = false
    var forwardSession = false
    var deleteSession = false
    let containerMultpileSelectSession = UIView()
    let viewSticker = UIView()
    let containerLink = UIView()
    let containerPreviewReply = UIView()
    var bottomAnchorPreviewReply = NSLayoutConstraint()
    let containerAction = UIView()
    var allowTyping = true
    
    public override func viewDidDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            UserDefaults.standard.removeObject(forKey: "inEditorGroup")
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    deinit {
        UserDefaults.standard.removeObject(forKey: "inEditorGroup")
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshView"), object: nil, userInfo: nil)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if self.navigationController?.isNavigationBarHidden ?? false {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        updateProfile()
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor.mainColor
        navigationController?.navigationBar.tintColor = .white
//        navigationController?.navigationBar.topItem?.title = ""
        
        viewButton.layer.shadowColor = UIColor.gray.cgColor
        viewButton.layer.shadowOpacity = 1
        viewButton.layer.shadowOffset = .zero
        viewButton.layer.shadowRadius = 3
        
        buttonVoice.setImage(resizeImage(image: UIImage(named: "Voice-Record", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
        buttonSendImage.setImage(resizeImage(image: UIImage(named: "Send-Image", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
        buttonSendPhoto.setImage(resizeImage(image: UIImage(named: "Camera", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
        buttonSendSticker.setImage(resizeImage(image: UIImage(named: "Sticker---Emoji", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
        buttonSendFile.setImage(resizeImage(image: UIImage(named: "File---Documents", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
        
        buttonSendChat.setImage(resizeImage(image: UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
        
        buttonSendChat.circle()
        buttonSendChat.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        textFieldSend.layer.cornerRadius = textFieldSend.maxCornerRadius()
        textFieldSend.layer.borderWidth = 1.0
        textFieldSend.text = "Send message".localized()
        textFieldSend.textColor = UIColor.lightGray
        textFieldSend.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 11, right: 40)
        textFieldSend.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        textFieldSend.font = UIFont.systemFont(ofSize: 12)
        textFieldSend.delegate = self
        
        navigationItem.rightBarButtonItem?.tintColor = UIColor.secondaryColor
        
        imageVideoPicker = ImageVideoPicker(presentationController: self, delegate: self)
        documentPicker = DocumentPicker(presentationController: self, delegate: self)
        
        let fm = FileManager.default
        let path = Bundle.resourceBundle(for: Nexilis.self).resourcePath!
        let items = try! fm.contentsOfDirectory(atPath: path)
        
        for item in items {
            if item.hasPrefix("sticker") {
                stickers.append(item)
            }
        }
        
        loadData()
        setRightButtonItem()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: "onReceiveChat"), object: nil)
        center.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: "onMessageChat"), object: nil)
        center.addObserver(self, selector: #selector(onUploadChat(notification:)), name: NSNotification.Name(rawValue: "onUploadChat"), object: nil)
        center.addObserver(self, selector: #selector(onMemberTopic(notification:)), name: NSNotification.Name(rawValue: "onMember"), object: nil)
        center.addObserver(self, selector: #selector(onGroup(notification:)), name: NSNotification.Name(rawValue: "onGroup"), object: nil)
        center.addObserver(self, selector: #selector(onMemberTopic(notification:)), name: NSNotification.Name(rawValue: "onTopic"), object: nil)
        
        if dataMessageForward != nil {
            for i in 0..<dataMessageForward!.count {
                sendChat(message_scope_id: "4", status: "2", message_text: dataMessageForward![i]["message_text"] as! String, credential: "0", attachment_flag: dataMessageForward![i]["attachment_flag"] as! String, ex_blog_id: "", message_large_text: "", ex_format: "", image_id: dataMessageForward![i]["image_id"] as! String, audio_id: dataMessageForward![i]["audio_id"] as! String, video_id: dataMessageForward![i]["video_id"] as! String, file_id: dataMessageForward![i]["file_id"] as! String, thumb_id: dataMessageForward![i]["thumb_id"] as! String, reff_id: "", read_receipts: "", is_call_center: "0", call_center_id: "", viewController: self)
            }
            dataMessageForward = nil
        }
    }
    
    private func updateProfile() {
        let idMe = UserDefaults.standard.string(forKey: "me") as String?
        DispatchQueue.global().async {
            let message = CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: idMe!, last_update: 0)
            let _ = Nexilis.write(message: message)
        }
    }
    
    private func setRightButtonItem() {
        let menu = UIMenu(title: "", children: [
            UIAction(title: "Delete Conversation".localized(), handler: {(_) in
                let alert = UIAlertController(title: "", message: "Are you sure to delete all message in this conversation?".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
                    var l_pin = self.dataGroup["group_id"] as! String
                    DispatchQueue.global().async {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            if (self.dataTopic["chat_id"] as! String != "") {
                                l_pin = self.dataTopic["chat_id"] as! String
                            }
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(l_pin)'")
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "(l_pin='\(self.dataGroup["group_id"]!!)' and chat_id='\(self.dataTopic["chat_id"]!!)') and message_scope_id='4'")
                        })
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                    }
                    if self.fromNotification {
                        self.didTapExit()
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
//                    self.dataMessages.removeAll()
//                    self.dataDates.removeAll()
//                    self.tableChatView.reloadData()
                }))
                self.present(alert, animated: true, completion: nil)
            }),
        ])
        if !isHistoryCC {
            let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
            navigationItem.rightBarButtonItem = moreIcon
        }
    }
    
    private func getOfficialGroup() {
        let query = "SELECT group_id, f_name, official, image_id FROM GROUPZ where group_type = 1 AND official = 1"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                if cursorData.next() {
                    dataGroup["group_id"] = cursorData.string(forColumnIndex: 0)
                    dataTopic["chat_id"] = ""
                    dataGroup["f_name"] = cursorData.string(forColumnIndex: 1)
                    dataGroup["image_id"] = cursorData.string(forColumnIndex: 3)
                    dataGroup["official"] = cursorData.string(forColumnIndex: 2)
                }
                cursorData.close()
            }
        })
    }
    
    func loadData() {
        if (unique_l_pin != "") {
            dataDates.removeAll()
            dataGroup.removeAll()
            dataTopic.removeAll()
            dataMessages.removeAll()
            tableChatView.reloadData()
            currentIndexpath = nil
            reffId = nil
            getDataGroup(unique_l_pin: unique_l_pin)
        }
        
        if removed {
            removed = false
            containerActionGroup.removeConstraints(containerActionGroup.constraints)
            containerActionGroup.removeFromSuperview()
            setRightButtonItem()
        }
        
        if !isHistoryCC {
            UserDefaults.standard.set([dataGroup["group_id"], dataTopic["chat_id"]], forKey: "inEditorGroup")
            
            if dataTopic["chat_id"] as! String == "" {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataGroup["group_id"] as! String])
                sendTyping(l_pin: dataGroup["group_id"] as! String)
            } else {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataTopic["chat_id"] as! String])
                sendTyping(l_pin: dataTopic["chat_id"] as! String)
            }
        } else {
            getOfficialGroup()
            disableEditor()
        }
        
        if fromNotification {
            let imageButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 44))
            imageButton.image = UIImage(systemName: "chevron.backward")?.withTintColor(.white)
            imageButton.contentMode = .right
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapExit))
            imageButton.isUserInteractionEnabled = true
            imageButton.addGestureRecognizer(tapGestureRecognizer)
            let leftItem = UIBarButtonItem(customView: imageButton)
            self.navigationItem.leftBarButtonItem = leftItem
        }
        
        changeAppBar()
        getData()
        getCounter()
        if counter > 0 {
            markerCounter = dataMessages[dataMessages.count - counter]["message_id"] as? String
        }
        
        tableChatView.alpha = 0
        tableChatView.delegate = self
        tableChatView.dataSource = self
        tableChatView.reloadData()
        if counter != 0 {
            if dataMessages.firstIndex(where: {$0["message_id"] as? String == markerCounter} ) != 0 {
                DispatchQueue.main.async {
                    let data = self.dataMessages.filter({ $0["message_id"] as? String == self.markerCounter })
                    let section = self.dataDates.firstIndex(of: data[0]["chat_date"] as! String)
                    let row = self.dataMessages.filter({$0["chat_date"] as! String == data[0]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.markerCounter})
                    self.tableChatView.scrollToRow(at: IndexPath(row: row!, section: section!), at: .bottom, animated: false)
                }
            } else {
                tableChatView.scrollToTop()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                if currentIndexpath == nil && counter != 0 {
                    let idMe = UserDefaults.standard.string(forKey: "me") as String?
                    if let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == markerCounter}) {
                        for i in idx..<dataMessages.count {
                            if dataMessages[i]["f_pin"] as? String != idMe {
                                sendReadMessageStatus(chat_id: self.dataTopic["chat_id"] as! String, f_pin: dataMessages[i]["f_pin"] as! String, message_scope_id: "4", message_id: dataMessages[i]["message_id"] as! String)
                            }
                        }
                        counter = 0
                        updateCounter(counter: counter)
                    }
                }
            }
        } else {
            tableChatView.scrollToBottom(isAnimated: false)
        }
        tableChatView.keyboardDismissMode = .interactive
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableChatView.addGestureRecognizer(tapGesture)
        UIView.animate(withDuration: 0.5, animations: {
            self.tableChatView.alpha = 1.0
        })
    }
    
    func getDataProfile(f_pin: String, message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database().database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, image_id from BUDDY where f_pin = '\(f_pin)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1)!
                c.close()
            }
            else if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, thumb_id from GROUPZ_MEMBER where f_pin = '\(f_pin)' AND group_id = '\(dataGroup["group_id"]!!)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1)!
                c.close()
            } else if let c = Database().getRecords(fmdb: fmdb, query: "select f_display_name from MESSAGE where message_id = '\(message_id)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!
                data["image_id"] = ""
                c.close()
            } else {
                data["name"] = "Unknown".localized()
            }
        })
        return data
    }
    
    private func getDataGroup(unique_l_pin: String) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id, f_name, image_id, official, parent FROM GROUPZ WHERE group_id='\(unique_l_pin)'"), cursorGroup.next() {
                dataGroup["group_id"] = cursorGroup.string(forColumnIndex: 0)
                dataGroup["f_name"] = cursorGroup.string(forColumnIndex: 1)
                dataGroup["image_id"] = cursorGroup.string(forColumnIndex: 2)
                dataGroup["official"] = cursorGroup.string(forColumnIndex: 3)
                dataGroup["parent"] = cursorGroup.string(forColumnIndex: 4)
                dataTopic["title"] = "Lounge".localized()
                dataTopic["chat_id"] = ""
                cursorGroup.close()
            } else if let cursorTopic = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id, title FROM DISCUSSION_FORUM where chat_id = '\(unique_l_pin)'"), cursorTopic.next() {
                dataGroup["group_id"] = cursorTopic.string(forColumnIndex: 0)
                dataTopic["title"] = cursorTopic.string(forColumnIndex: 1)
                dataTopic["chat_id"] = unique_l_pin
                cursorTopic.close()
                if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_name, image_id, official, parent FROM GROUPZ where group_id = '\(dataGroup["group_id"] as! String)'"), cursorGroup.next() {
                    dataGroup["f_name"] = cursorGroup.string(forColumnIndex: 0)
                    dataGroup["image_id"] = cursorGroup.string(forColumnIndex: 1)
                    dataGroup["official"] = cursorGroup.string(forColumnIndex: 2)
                    dataGroup["parent"] = cursorGroup.string(forColumnIndex: 3)
                    cursorGroup.close()
                }
            }
        })
    }
    
    private func getData() {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            var query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id FROM MESSAGE where chat_id='' AND l_pin='\(dataGroup["group_id"] as! String)' order by server_date asc"
            if isHistoryCC {
                query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared FROM MESSAGE where call_center_id='\(complaintId)' order by server_date asc"
            } else if (dataTopic["chat_id"] as! String != "") {
                query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared FROM MESSAGE where chat_id='\(dataTopic["chat_id"] as! String)' order by server_date asc"
            }
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                while cursorData.next() {
                    var row: [String: Any?] = [:]
                    row["message_id"] = cursorData.string(forColumnIndex: 0)
                    row["f_pin"] = cursorData.string(forColumnIndex: 1)
                    row["l_pin"] = cursorData.string(forColumnIndex: 2)
                    row["message_scope_id"] = cursorData.string(forColumnIndex: 3)
                    row["server_date"] = cursorData.string(forColumnIndex: 4)
                    row["status"] = cursorData.string(forColumnIndex: 5)
                    row["message_text"] = cursorData.string(forColumnIndex: 6)
                    row["audio_id"] = cursorData.string(forColumnIndex: 7)
                    row["video_id"] = cursorData.string(forColumnIndex: 8)
                    row["image_id"] = cursorData.string(forColumnIndex: 9)
                    row["thumb_id"] = cursorData.string(forColumnIndex: 10)
                    row["read_receipts"] = cursorData.int(forColumnIndex: 11)
                    row["chat_id"] = cursorData.string(forColumnIndex: 12)
                    row["file_id"] = cursorData.string(forColumnIndex: 13)
                    row["attachment_flag"] = cursorData.string(forColumnIndex: 14)
                    row["reff_id"] = cursorData.string(forColumnIndex: 15)
                    row["lock"] = cursorData.string(forColumnIndex: 16)
                    row["is_stared"] = cursorData.string(forColumnIndex: 17)
                    row["blog_id"] = cursorData.string(forColumnIndex: 18)
                    row["isSelected"] = false
                    if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS WHERE message_id='\(row["message_id"] as! String)'") {
                        while cursorStatus.next() {
                            row["status"] = cursorStatus.string(forColumnIndex: 0)
                        }
                        cursorStatus.close()
                    }
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"] as! String)
                        let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"] as! String)
                        if ((row["video_id"] as! String) != "") {
                            if FileManager.default.fileExists(atPath: videoURL.path){
                                row["progress"] = 100.0
                            } else {
                                row["progress"] = 0.0
                            }
                        } else {
                            if FileManager.default.fileExists(atPath: fileURL.path){
                                row["progress"] = 100.0
                            } else {
                                row["progress"] = 0.0
                            }
                        }
                    }
                    row["chat_date"] = chatDate(stringDate: row["server_date"] as! String, messageId: row["message_id"] as! String)
                    dataMessages.append(row)
                }
//                if isHistoryCC {
//                    dataMessages.remove(at: 0)
//                }
                cursorData.close()
            }
        })
    }
    
    private func chatDate(stringDate: String, messageId: String) -> String {
        let date = Date(milliseconds: Int64(stringDate)!)
        let calendar = Calendar.current
        if (calendar.isDateInToday(date)) {
            if !dataDates.contains("Today".localized()){
                dataDates.append("Today".localized())
            }
            return "Today".localized()
        } else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfTimeStamp = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
            let day = -(components.day!)
            if day == 1{
                if !dataDates.contains("Yesterday".localized()){
                    dataDates.append("Yesterday".localized())
                }
                return "Yesterday".localized()
            } else if day < 7 {
                if !dataDates.contains("\(day) " + "days".localized() + " " + "ago".localized()){
                    dataDates.append("\(day) " + "days".localized() + " " + "ago".localized())
                }
                return "\(day) " + "days".localized() + " " + "ago".localized()
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd MMMM yyyy"
                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                let stringFormat = formatter.string(from: date as Date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            }
        }
    }
    
    private func changeAppBar() {
        let viewAppBar = UIView()
        viewAppBar.frame.size = CGSize(width: self.view.frame.size.width, height: 44)
        
        let imageProfile = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
        imageProfile.circle()
        imageProfile.clipsToBounds = true
        viewAppBar.addSubview(imageProfile)
        let pictureImage = dataGroup["image_id"]!
        if (pictureImage as! String != "" && pictureImage != nil) {
            imageProfile.setImage(name: pictureImage! as! String)
            imageProfile.contentMode = .scaleAspectFill
        } else {
            imageProfile.image = UIImage(systemName: "person.3")
            imageProfile.contentMode = .scaleAspectFit
            imageProfile.backgroundColor = .lightGray
        }
        
        let titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: viewAppBar.frame.size.width - 150, height: 44))
        viewAppBar.addSubview(titleNavigation)
        if (dataGroup["official"] as! String == "1") {
            if !isHistoryCC {
                titleNavigation.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.white), with: "  \(dataGroup["f_name"]!!) (\(dataTopic["title"]!!))", size: 15, y: -4)
            } else {
                titleNavigation.text = (dataGroup["f_name"] as? String)! + " " + "Contact Center".localized()
            }
        } else {
            titleNavigation.text = (dataGroup["f_name"] as? String)! + " (\(dataTopic["title"]!!))"
        }
        titleNavigation.textColor = .white
        titleNavigation.font = UIFont.systemFont(ofSize: 12).bold
        
        navigationItem.titleView = viewAppBar
        
        if copySession || forwardSession || deleteSession {
            navigationItem.hidesBackButton = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationItem.hidesBackButton = false
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
        
        viewAppBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(seeProfileTapped)))
    }
    
    @objc func onUploadChat(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        var isImage = false
        var idx = dataMessages.lastIndex(where: { $0["video_id"] as! String == data["name"] as! String })
        if (idx == nil) {
            idx = dataMessages.lastIndex(where: { $0["image_id"] as! String == data["name"] as! String })
            isImage = true
        }
        if (idx != nil) {
            let section = dataDates.firstIndex(of: dataMessages[idx!]["chat_date"] as! String)
            if section == nil {
                return
            }
            let row = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section!]}).firstIndex(where: { $0["message_id"] as! String == dataMessages[idx!]["message_id"] as! String})
            if row == nil {
                return
            }
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: row!, section: section!)
                if let cell = self.tableChatView.cellForRow(at: indexPath) {
                    for view in cell.contentView.subviews {
                        if !(view is UILabel) && !(view is UIImageView) {
                            for viewInContainer in view.subviews {
                                if viewInContainer is UIImageView {
                                    if viewInContainer.subviews.count == 0 {
                                        return
                                    }
                                    var containerView = UIView()
                                    if (isImage) {
                                        containerView = viewInContainer.subviews[0]
                                    } else {
                                        containerView = viewInContainer.subviews[1]
                                    }
                                    let loading = containerView.layer.sublayers![1] as! CAShapeLayer
                                    loading.strokeEnd = CGFloat(data["progress"] as! Double / 100)
                                    if (data["progress"] as! Double == 100.0) {
                                        self.dataMessages[idx!]["progress"] = data["progress"]
                                        self.tableChatView.reloadRows(at: [indexPath], with: .none)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            idx = dataMessages.lastIndex(where: { $0["file_id"] as! String == data["name"] as! String })
            if (idx != nil) {
                DispatchQueue.main.async {
                    let section = 0
                    let indexPath = IndexPath(row: idx!, section: section)
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        for view in cell.contentView.subviews {
                            if !(view is UILabel) && !(view is UIImageView) {
                                for viewSubviews in view.subviews {
                                    if !(viewSubviews is UILabel) {
                                        for viewInContainer in viewSubviews.subviews {
                                            if !(viewInContainer is UILabel) && !(viewInContainer is UIImageView) {
                                                if viewInContainer.layer.sublayers!.count < 2 {
                                                    return
                                                }
                                                let loading = viewInContainer.layer.sublayers![1] as! CAShapeLayer
                                                loading.strokeEnd = CGFloat(data["progress"] as! Double / 100)
                                                if (data["progress"] as! Double == 100.0) {
                                                    self.dataMessages[idx!]["progress"] = data["progress"]
                                                    self.tableChatView.reloadRows(at: [indexPath], with: .none)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                let group_id = self.dataGroup["group_id"] as! String
                let chat_id = self.dataTopic["chat_id"] as! String
                if chatData[CoreMessage_TMessageKey.L_PIN] == group_id && (chatData[CoreMessage_TMessageKey.CHAT_ID] ?? "") == chat_id {
                    var row: [String: Any?] = [:]
                    row["message_id"] = chatData[CoreMessage_TMessageKey.MESSAGE_ID]
                    row["f_pin"] = chatData[CoreMessage_TMessageKey.F_PIN]
                    row["l_pin"] = chatData[CoreMessage_TMessageKey.L_PIN]
                    row["message_scope_id"] = chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]
                    row["server_date"] = chatData[CoreMessage_TMessageKey.SERVER_DATE]
                    row["status"] = chatData[CoreMessage_TMessageKey.STATUS]
                    row["message_text"] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
                    if (chatData.keys.contains(CoreMessage_TMessageKey.AUDIO_ID)) {
                        row["audio_id"] = chatData[CoreMessage_TMessageKey.AUDIO_ID]
                    } else {
                        row["audio_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.VIDEO_ID)) {
                        row["video_id"] = chatData[CoreMessage_TMessageKey.VIDEO_ID]
                    } else {
                        row["video_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.IMAGE_ID)) {
                        row["image_id"] = chatData[CoreMessage_TMessageKey.IMAGE_ID]
                    } else {
                        row["image_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.THUMB_ID)) {
                        row["thumb_id"] = chatData[CoreMessage_TMessageKey.THUMB_ID]
                    } else {
                        row["thumb_id"] = ""
                    }
                    row["read_receipts"] = 0
                    row["chat_id"] = ""
                    if (chatData.keys.contains(CoreMessage_TMessageKey.FILE_ID)) {
                        row["file_id"] = chatData[CoreMessage_TMessageKey.FILE_ID]
                    } else {
                        row["file_id"] = ""
                    }
                    row["progress"] = 0.0
                    row["attachment_flag"] = chatData[CoreMessage_TMessageKey.ATTACHMENT_FLAG]
                    row["reff_id"] = chatData[CoreMessage_TMessageKey.REF_ID] ?? ""
                    row["lock"] = ""
                    row["is_stared"] = "0"
                    row["isSelected"] = false
                    if !self.dataDates.contains("Today".localized()){
                        self.dataDates.append("Today".localized())
                        self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .fade)
                    }
                    row["chat_date"] = "Today".localized()
                    row["blog_id"] = chatData[CoreMessage_TMessageKey.BLOG_ID]
                    self.counter += 1
                    self.dataMessages.append(row)
                    self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .fade)
                    if  self.currentIndexpath?.row == (self.dataMessages.count - 2) {
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"] as! String, f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                        self.tableChatView.scrollToBottom()
                        if (self.currentIndexpath!.section <= self.dataDates.count - 1 && self.currentIndexpath!.row <= self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1)  {
                            self.counter = 0
                            self.updateCounter(counter: self.counter)
                        }
                        if self.markerCounter != nil {
                            self.markerCounter = nil
                        }
                        self.tableChatView.reloadData()
                    }
                    else if self.currentIndexpath == nil {
                        self.counter = 0
                        self.updateCounter(counter: self.counter)
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"] as! String, f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                    }
                    else if self.counter != 0 {
                        if !self.indicatorCounterBSTB.isDescendant(of: self.view) && self.buttonScrollToBottom.isDescendant(of: self.view) {
                            self.markerCounter = row["message_id"] as? String
                            self.addCounterAtButttonScrollToBottom()
                            self.tableChatView.reloadData()
                        } else if self.indicatorCounterBSTB.isDescendant(of: self.view) {
                            self.labelCounter.text = "\(self.counter)"
                        }
                    }
                }
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            }
        }
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async {
            if (self.viewIfLoaded?.window != nil) {
                let data:[AnyHashable : Any] = notification.userInfo!
                if let dataMessage = data["message"] as? TMessage {
                    let idMe = UserDefaults.standard.string(forKey: "me") as String?
                    let chatData = dataMessage.mBodies
                    if (chatData[CoreMessage_TMessageKey.F_PIN] == idMe || chatData[CoreMessage_TMessageKey.L_PIN] == self.dataGroup["group_id"] as? String || chatData[CoreMessage_TMessageKey.F_PIN] == self.dataGroup["group_id"] as? String) && chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == "4" {
                        if (chatData.keys.contains(CoreMessage_TMessageKey.MESSAGE_ID) && !(chatData[CoreMessage_TMessageKey.MESSAGE_ID]!).contains("-2,")) {
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! })
                            if (idx != nil) {
                                if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                    self.dataMessages[idx!]["lock"] = "1"
                                    self.dataMessages[idx!]["reff_id"] = ""
                                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                    let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[idx!]["message_id"] as! String })
                                    if row != nil && section != nil  {
                                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                    }
                                } else {
                                    self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                    let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[idx!]["message_id"] as! String })
                                    if row != nil && section != nil  {
                                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                    }
                                }
                                if self.reffId != nil && self.reffId == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! {
                                    self.deleteReplyView()
                                }
                            }
                        }
                        else if (chatData.keys.contains("message_id")) {
                            let idx = self.dataMessages.firstIndex(where: { "'\($0["message_id"] as! String)'" == chatData["message_id"]! })
                            if (idx != nil) {
                                if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                    self.dataMessages[idx!]["lock"] = "1"
                                    self.dataMessages[idx!]["reff_id"] = ""
                                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                    let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[idx!]["message_id"] as! String })
                                    if row != nil && section != nil  {
                                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                    }
                                } else {
                                    self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                    let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[idx!]["message_id"] as! String })
                                    if row != nil && section != nil  {
                                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                    }
                                }
                                if self.reffId != nil && self.reffId == chatData["message_id"]! {
                                    self.deleteReplyView()
                                }
                            }
                        }
                        else {
                            let messageId = chatData[CoreMessage_TMessageKey.MESSAGE_ID]!.split(separator: ",")[1]
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == messageId })
                            if (idx != nil) {
                                self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[idx!]["message_id"] as! String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                                if self.reffId != nil && self.reffId! == messageId {
                                    self.deleteReplyView()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func onMemberTopic(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        DispatchQueue.main.async { [self] in
            if data["member"] == nil || data["code"] as! String == CoreMessage_TMessageCode.EXIT_GROUP && data["member"] as! String == UserDefaults.standard.string(forKey: "me")! && data["groupId"] as! String == self.dataGroup["group_id"] as! String && !containerActionGroup.isDescendant(of: self.view) {
                dismissKeyboard()
                let labelKicked = UILabel()
                if data["member"] == nil && data["code"] as! String == CoreMessage_TMessageCode.DELETE_CHAT && data["topicId"] as! String == dataTopic["chat_id"] as! String {
                    labelKicked.text = "This topic has been deleted".localized()
                } else if data["member"] != nil && data["member"] as! String == data["f_pin"] as! String {
                    labelKicked.text = "You have left this group".localized()
                } else if data["member"] != nil {
                    labelKicked.text = "You have been removed from this group".localized()
                } else if data["code"] as! String == CoreMessage_TMessageCode.UPDATE_CHAT {
                    dataGroup.removeAll()
                    dataTopic.removeAll()
                    getDataGroup(unique_l_pin: unique_l_pin)
                    changeAppBar()
                    return
                } else {
                    return
                }
                removed = true
                navigationItem.rightBarButtonItem = nil
                view.addSubview(containerActionGroup)
                containerActionGroup.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    containerActionGroup.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    containerActionGroup.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    containerActionGroup.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    containerActionGroup.heightAnchor.constraint(equalToConstant: 120)
                ])
                containerActionGroup.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
                containerActionGroup.addSubview(labelKicked)
                labelKicked.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelKicked.centerYAnchor.constraint(equalTo: containerActionGroup.centerYAnchor),
                    labelKicked.centerXAnchor.constraint(equalTo: containerActionGroup.centerXAnchor),
                ])
                labelKicked.textColor = .black
                labelKicked.font = UIFont.systemFont(ofSize: 12).bold
            }
        }
    }
    
    @objc func onGroup(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        if data["code"] as! String == "A010" && data["groupId"] as! String == self.dataGroup["group_id"] as! String {
            DispatchQueue.main.async {
                Database().database?.inTransaction({ fmdb, rollback in
                    if let c = Database().getRecords(fmdb: fmdb, query: "select f_name, image_id from GROUPZ where group_id = '\(self.dataGroup["group_id"]!!)'"), c.next() {
                        self.dataGroup["f_name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.dataGroup["image_id"] = c.string(forColumnIndex: 1)!
                        c.close()
                    }
                })
                self.changeAppBar()
            }
        }
    }
    
    @IBAction func voiceTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
    }
    
    @IBAction func imageTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let action = self.actionImageVideo(for: "image", title: "Choose Photo".localized()) {
            alertController.addAction(action)
        }
        if let action = self.actionImageVideo(for: "video", title: "Choose Video".localized()) {
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
    
    private func actionImageVideo(for type: String, title: String) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            switch type {
            case "image":
                imageVideoPicker.present(source: .imageAlbum)
            case "video":
                imageVideoPicker.present(source: .videoAlbum)
            case "imageCamera":
                imageVideoPicker.present(source: .imageCamera)
            case "videoCamera":
                imageVideoPicker.present(source: .videoCamera)
            default:
                imageVideoPicker.present(source: .imageAlbum)
            }
        }
    }
    
    @IBAction func photoTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let action = self.actionImageVideo(for: "imageCamera", title: "Take Photo".localized()) {
            alertController.addAction(action)
        }
        if let action = self.actionImageVideo(for: "videoCamera", title: "Take Video".localized()) {
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
    
    @IBAction func stickerTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            if (self.constraintBottomAttachment.constant == 0.0) {
                self.constraintBottomAttachment.constant = 200.0
                self.view.addSubview(self.viewSticker)
                self.viewSticker.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    self.viewSticker.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    self.viewSticker.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    self.viewSticker.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    self.viewSticker.heightAnchor.constraint(equalToConstant: 200)
                ])
                
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .vertical
                let collectionSticker = UICollectionView(frame: .zero, collectionViewLayout: layout)
                collectionSticker.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cellSticker")
                collectionSticker.delegate = self
                collectionSticker.dataSource = self
                collectionSticker.backgroundColor = .clear
                self.viewSticker.addSubview(collectionSticker)
                collectionSticker.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    collectionSticker.topAnchor.constraint(equalTo: self.viewSticker.topAnchor, constant: 20),
                    collectionSticker.bottomAnchor.constraint(equalTo: self.viewSticker.bottomAnchor, constant: -20),
                    collectionSticker.leadingAnchor.constraint(equalTo: self.viewSticker.leadingAnchor, constant: 20),
                    collectionSticker.trailingAnchor.constraint(equalTo: self.viewSticker.trailingAnchor, constant: -20)
                ])
                if (self.currentIndexpath != nil) {
                    DispatchQueue.main.async {
                        self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                    }
                } else {
                    self.tableChatView.scrollToBottom()
                }
            } else {
                self.constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
            }
        }
    }
    
    @IBAction func fileTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        documentPicker.present()
    }
    
    @objc func didTapExit() {
        UserDefaults.standard.removeObject(forKey: "inEditorGroup")
        NotificationCenter.default.removeObserver(self)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func profilePersonTapped(_ sender: ObjectGesture) {
        if isHistoryCC {
            return
        }
        let idMe = UserDefaults.standard.string(forKey: "me") as String?
        if sender.message_id == idMe {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
            controller.data = sender.message_id
            controller.flag = .me
            navigationController?.show(controller, sender: nil)
        } else {
            let data = User.getData(pin: sender.message_id)
            if data != nil {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.flag = .friend
                controller.user = data
                controller.name = data!.fullName
                controller.data = sender.message_id
                controller.picture = data!.thumb
                self.navigationController?.show(controller, sender: nil)
            } else {
                let dataUser = getDataProfile(f_pin: sender.message_id, message_id: "")
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.flag = .invite
                controller.user = nil
                controller.name = dataUser["name"]!
                controller.data = sender.message_id
                controller.picture = dataUser["image_id"]!
                self.navigationController?.show(controller, sender: nil)
            }
        }
    }
    
    @objc func seeProfileTapped() {
        if isHistoryCC || removed || copySession || forwardSession || deleteSession || (dataGroup["official"] as? String == "1" && (dataGroup["parent"] as? String)!.isEmpty) {
            return
        }
        dismissKeyboard()
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "groupDetailView") as! GroupDetailViewController
        controller.data = dataGroup["group_id"] as! String
        controller.checkReadMessage = {
            if self.currentIndexpath == nil {
                var listData = self.dataMessages
                listData = listData.filter({$0["status"] as! String != "4" && $0["status"] as! String != "8"})
                if listData.count != 0 {
                    let idMe = UserDefaults.standard.string(forKey: "me") as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"] as! String, f_pin: listData[i]["f_pin"] as! String, message_scope_id: "4", message_id: listData[i]["message_id"] as! String)
                        }
                    }
                }
            } else {
                let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.currentIndexpath!.section] })
                var listData = dataMessages
                listData = listData.filter({$0["status"] as! String != "4" && $0["status"] as! String != "8"})
                if listData.count != 0 {
                    let idMe = UserDefaults.standard.string(forKey: "me") as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"] as! String, f_pin: listData[i]["f_pin"] as! String, message_scope_id: "4", message_id: listData[i]["message_id"] as! String)
                        }
                    }
                }
            }
        }
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func dismissKeyboard() {
        textFieldSend.resignFirstResponder() // dismiss keyoard
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil {
            if (self.constraintBottomAttachment.constant != 0.0) {
                self.constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
            }
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            if self.constraintViewTextField.constant != keyboardHeight - 60 {
                self.constraintViewTextField.constant = keyboardHeight - 60
                UIView.animate(withDuration: TimeInterval(duration), animations: {
                    self.view.layoutIfNeeded()
                })
                if (self.currentIndexpath != nil) {
                    self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                } else {
                    self.tableChatView.scrollToBottom()
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            self.constraintViewTextField.constant = 0
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func sendTapped() {
        sendChat(message_text: textFieldSend.text!, viewController: self)
    }
    
    private func sendChat(message_scope_id:String =  "4", status:String =  "2", message_text:String =  "", credential:String = "0", attachment_flag: String = "0", ex_blog_id: String = "", message_large_text: String = "", ex_format: String = "", image_id: String = "", audio_id: String = "", video_id: String = "", file_id: String = "", thumb_id: String = "", reff_id: String = "", read_receipts: String = "", is_call_center: String = "0", call_center_id: String = "", viewController: UIViewController) {
        if viewController is EditorGroup && file_id == "" && dataMessageForward == nil {
            if ((textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray && attachment_flag != "11") || textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ) {
                dismissKeyboard()
                viewController.showToast(message: "Type Messages".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized()) {
                    textFieldSend.text = ""
                }
                if (self.heightTextFieldSend.constant != 40) {
                    self.heightTextFieldSend.constant = 40
                }
                return
            }
        }
        var reff_id = reff_id
        if (reffId != nil) {
            reff_id = reffId!
        }
        let message_text = message_text.trimmingCharacters(in: .whitespacesAndNewlines)
        let idMe = UserDefaults.standard.string(forKey: "me") as String?
        let message = CoreMessage_TMessageBank.sendMessage(l_pin: dataGroup["group_id"] as! String, message_scope_id: message_scope_id, status: status, message_text: message_text, credential: credential, attachment_flag: attachment_flag, ex_blog_id: ex_blog_id, message_large_text: message_large_text, ex_format: ex_format, image_id: image_id, audio_id: audio_id, video_id: video_id, file_id: file_id, thumb_id: thumb_id, reff_id: reff_id, read_receipts: read_receipts, chat_id: dataTopic["chat_id"] as! String, is_call_center: is_call_center, call_center_id: call_center_id, opposite_pin: "")
        Nexilis.addQueueMessage(message: message)
        let messageId = String(message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID]!)
        var row: [String: Any?] = [:]
        row["message_id"] = messageId
        row["f_pin"] = idMe
        row["l_pin"] = dataGroup["group_id"]!!
        row["message_scope_id"] = message_scope_id
        row["server_date"] = "\(Date().millisecondsSince1970)"
        row["status"] = status
        row["message_text"] = message_text
        row["audio_id"] = audio_id
        row["video_id"] = video_id
        row["image_id"] = image_id
        row["thumb_id"] = thumb_id
        row["read_receipts"] = 0
        row["chat_id"] = dataTopic["chat_id"]!!
        row["file_id"] = file_id
        row["attachment_flag"] = attachment_flag
        row["reff_id"] = reff_id
        row["progress"] = 0.0
        row["lock"] = "0"
        row["is_stared"] = "0"
        row["isSelected"] = false
        if !dataDates.contains("Today".localized()){
            dataDates.append("Today".localized())
            tableChatView.insertSections(IndexSet(integer: dataDates.count - 1), with: .fade)
        }
        row["chat_date"] = "Today".localized()
        dataMessages.append(row)
        tableChatView.insertRows(at: [IndexPath(row: dataMessages.filter({ $0["chat_date"] as! String == dataDates[dataDates.count - 1]}).count - 1, section: dataDates.count - 1)], with: .fade)
        if textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized() && textFieldSend.textColor != UIColor.lightGray && constraintViewTextField.constant == 0 {
            textFieldSend.text = "Send message".localized()
            textFieldSend.textColor = UIColor.lightGray
        } else if constraintViewTextField.constant != 0 {
            textFieldSend.text = ""
            heightTextFieldSend.constant = 40
        }
        deleteReplyView()
        deleteLinkPreview()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.tableChatView.scrollToBottom()
            if self.markerCounter != nil {
                self.markerCounter = nil
                self.tableChatView.reloadData()
            }
        }
    }
    
    private func getCounter() {
        Database().database?.inTransaction({ fmdb, rollback in
            var l_pin = self.dataGroup["group_id"]!!
            if (self.dataTopic["chat_id"] as! String != "") {
                l_pin = self.dataTopic["chat_id"] as! String
            }
            
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT counter FROM MESSAGE_SUMMARY where l_pin='\(l_pin)'"), c.next() {
                counter = Int(c.int(forColumnIndex: 0))
                c.close()
            }
        })
    }
    
    private func updateCounter(counter: Int) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                var l_pin = self.dataGroup["group_id"]!!
                if (self.dataTopic["chat_id"] as! String != "") {
                    l_pin = self.dataTopic["chat_id"] as! String
                }
                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "counter" : "\(counter)"
                ], _where: "l_pin = '\(l_pin)'")
            })
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        }
        
    }
    
    private func disableEditor() {
        view.addSubview(containerAction)
        containerAction.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerAction.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerAction.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            containerAction.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            containerAction.heightAnchor.constraint(equalToConstant: 120)
        ])
        containerAction.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
        let labelDisable = UILabel()
        containerAction.addSubview(labelDisable)
        labelDisable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelDisable.centerYAnchor.constraint(equalTo: containerAction.centerYAnchor),
            labelDisable.centerXAnchor.constraint(equalTo: containerAction.centerXAnchor),
        ])
        labelDisable.textColor = .black
        labelDisable.font = UIFont.systemFont(ofSize: 12).bold
        labelDisable.text = "Call Center Session has ended".localized()
    }
    
    private func addButtonScrollToBottom() {
        self.view.addSubview(buttonScrollToBottom)
        buttonScrollToBottom.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonScrollToBottom.bottomAnchor.constraint(equalTo: buttonSendChat.topAnchor, constant: -50),
            buttonScrollToBottom.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            buttonScrollToBottom.widthAnchor.constraint(equalToConstant: 60),
            buttonScrollToBottom.heightAnchor.constraint(equalToConstant: 30.0)
        ])
        buttonScrollToBottom.backgroundColor = .greenColor
        buttonScrollToBottom.setImage(UIImage(systemName: "chevron.down.circle"), for: .normal)
        buttonScrollToBottom.imageView?.contentMode = .scaleAspectFit
        buttonScrollToBottom.imageView?.tintColor = .white
        buttonScrollToBottom.contentVerticalAlignment = .fill
        buttonScrollToBottom.contentHorizontalAlignment = .fill
        buttonScrollToBottom.imageEdgeInsets.top = 2.0
        buttonScrollToBottom.imageEdgeInsets.bottom = 2.0
        buttonScrollToBottom.layer.cornerRadius = 10.0
        buttonScrollToBottom.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        buttonScrollToBottom.clipsToBounds = true
        buttonScrollToBottom.addTarget(self, action: #selector(scrollTobottomAction), for: .touchUpInside)
    }
    
    private func addCounterAtButttonScrollToBottom() {
        self.view.addSubview(indicatorCounterBSTB)
        indicatorCounterBSTB.translatesAutoresizingMaskIntoConstraints = false
        indicatorCounterBSTB.backgroundColor = .systemRed
        indicatorCounterBSTB.layer.cornerRadius = 7.5
        indicatorCounterBSTB.clipsToBounds = true
        indicatorCounterBSTB.layer.borderWidth = 0.5
        indicatorCounterBSTB.layer.borderColor = UIColor.secondaryColor.cgColor
        NSLayoutConstraint.activate([
            indicatorCounterBSTB.bottomAnchor.constraint(equalTo: buttonScrollToBottom.topAnchor, constant: 5),
            indicatorCounterBSTB.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -50),
            indicatorCounterBSTB.widthAnchor.constraint(greaterThanOrEqualToConstant: 15),
            indicatorCounterBSTB.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        indicatorCounterBSTB.addSubview(labelCounter)
        labelCounter.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelCounter.leadingAnchor.constraint(equalTo: indicatorCounterBSTB.leadingAnchor, constant: 2),
            labelCounter.trailingAnchor.constraint(equalTo: indicatorCounterBSTB.trailingAnchor, constant: -2),
            labelCounter.centerXAnchor.constraint(equalTo: indicatorCounterBSTB.centerXAnchor),
        ])
        labelCounter.font = UIFont.systemFont(ofSize: 11)
        labelCounter.text = "\(counter)"
        labelCounter.textColor = .secondaryColor
        labelCounter.textAlignment = .center
    }
    
    @objc func scrollTobottomAction() {
        tableChatView.scrollToBottom()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            if buttonScrollToBottom.isDescendant(of: self.view) {
                buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
                buttonScrollToBottom.removeFromSuperview()
                if indicatorCounterBSTB.isDescendant(of: self.view) {
                    indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                    indicatorCounterBSTB.removeFromSuperview()
                }
            }
        }
    }
    
    private func sendReadMessageStatus(chat_id: String, f_pin: String, message_scope_id: String, message_id: String) {
        let message = CoreMessage_TMessageBank.getUpdateRead(p_chat_id: chat_id, p_f_pin: f_pin, p_scope_id: message_scope_id, qty: 1)
        let fPin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        let scope = message.getBody(key: CoreMessage_TMessageKey.SCOPE_ID)
        message.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = String(Date().currentTimeMillis())
        if (fPin.elementsEqual("-999") || scope.elementsEqual("16") || scope.elementsEqual("15")){
            return
        }
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                    "status" : "4"
                ], _where: "message_id = '\(message_id)'")
            })
            message.mStatus = CoreMessage_TMessageUtil.getTID()
            message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
            message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = "-2,\(message_id)"
            _ = Nexilis.write(message: message)
        }
        if let index = dataMessages.firstIndex(where: {$0["message_id"] as? String == message_id}) {
            dataMessages[index]["status"] = "4"
            let auto = UserDefaults.standard.bool(forKey: "autoDownload")
            if auto {
                if dataMessages[index]["image_id"] as? String != nil && !((dataMessages[index]["image_id"] as? String)!.isEmpty) {
                    Download().start(forKey:dataMessages[index]["image_id"] as! String) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.dataMessages[index]["image_id"] as! String)
                            let image    = UIImage(contentsOfFile: imageURL.path)
                            let save = UserDefaults.standard.bool(forKey: "saveToGallery")
                            if save {
                                UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                            }
                        }
                        DispatchQueue.main.async { [self] in
                            let section = self.dataDates.firstIndex(of: dataMessages[index]["chat_date"] as! String)
                            let row = self.dataMessages.filter({$0["chat_date"] as! String == dataMessages[index]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == message_id})
                            if row != nil && section != nil{
                                tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .automatic)
                            }
                        }
                    }
                }  else if dataMessages[index]["video_id"] as? String != nil && !((dataMessages[index]["video_id"] as? String)!.isEmpty){
                    let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"] as! String)
                    let row = dataMessages.filter({$0["chat_date"] as! String == dataMessages[index]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == message_id})
                    if row != nil && section != nil{
                        let indexPath = IndexPath(row: row!, section: section!)
                        if let cell = tableChatView.cellForRow(at: indexPath) {
                            for view in cell.contentView.subviews {
                                if view is UIImageView {
                                    let objectTap = ObjectGesture()
                                    objectTap.video_id = dataMessages[index]["video_id"] as! String
                                    objectTap.imageView = view as! UIImageView
                                    objectTap.indexPath = indexPath
                                    contentMessageTapped(objectTap)
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func sendTyping(l_pin: String, isTyping: Bool = false) {
        DispatchQueue.global().async {
            let tmessage = CoreMessage_TMessageBank.getUpdateTypingStatus(p_opposite: l_pin, p_scope: "4", p_status: isTyping ? "3": "4")
            _ = Nexilis.write(message: tmessage)
        }
    }
    
    private func checkNewMessage(tableView: UITableView) {
        currentIndexpath = tableView.indexPathsForVisibleRows?.last
        if currentIndexpath != nil {
            let dataMessages = dataMessages.filter({ $0["chat_date"] as! String == dataDates[currentIndexpath!.section] })
            if dataMessages.count == 0 {
                return
            }
            if currentIndexpath!.section == dataDates.count - 1 && currentIndexpath!.row != dataMessages.count - 1 && currentIndexpath!.row != dataMessages.count - 2 && !buttonScrollToBottom.isDescendant(of: self.view) {
                addButtonScrollToBottom()
                addCounterAtButttonScrollToBottom()
            } else if currentIndexpath!.section == dataDates.count - 1 && currentIndexpath!.row == dataMessages.count - 1 {
                if buttonScrollToBottom.isDescendant(of: self.view) {
                    buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
                    buttonScrollToBottom.removeFromSuperview()
                    if indicatorCounterBSTB.isDescendant(of: self.view) {
                        indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                        indicatorCounterBSTB.removeFromSuperview()
                    }
                }
            }
            if dataMessages.count - 1 < currentIndexpath!.row {
                return
            }
            var listData = dataMessages[0...currentIndexpath!.row]
            listData = listData.filter({$0["status"] as! String != "4" && $0["status"] as! String != "8"})
            if listData.count != 0 {
                let idMe = UserDefaults.standard.string(forKey: "me") as String?
                for i in 0...listData.count - 1 {
                    if listData[i]["f_pin"] as? String != idMe {
                        sendReadMessageStatus(chat_id: self.dataTopic["chat_id"] as! String, f_pin: listData[i]["f_pin"] as! String, message_scope_id: "4", message_id: listData[i]["message_id"] as! String)
                    }
                }
            }
        }
        if counter == 0 && indicatorCounterBSTB.isDescendant(of: self.view) {
            indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
            indicatorCounterBSTB.removeFromSuperview()
        } else if counter != 0 && currentIndexpath != nil {
            let dataFilter = dataMessages.filter({ $0["chat_date"] as! String == dataDates[currentIndexpath!.section] })
            if dataFilter.count == 0 {
                return
            }
            let idx = dataMessages.firstIndex(where: { $0["message_id"] as! String == dataFilter[currentIndexpath!.row]["message_id"] as! String})
            if idx == nil {
                return
            }
            if (dataMessages.count - counter) <= idx! {
                let countUpdate = idx! - (dataMessages.count - counter)
                counter = counter - (countUpdate + 1)
                if indicatorCounterBSTB.isDescendant(of: self.view) {
                    labelCounter.text = "\(counter)"
                }
                updateCounter(counter: counter)
            }
        }
    }
}

extension EditorGroup: ImageVideoPickerDelegate, PreviewAttachmentImageVideoDelegate {
    public func didSelect(imagevideo: Any?) {
        if (imagevideo != nil) {
            let imageVideoData = imagevideo as! [UIImagePickerController.InfoKey: Any]
            let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
            previewImageVC.imageVideoData = imageVideoData
            if (textFieldSend.textColor != .lightGray) {
                previewImageVC.currentTextTextField = textFieldSend.text
            }
            previewImageVC.modalPresentationStyle = .custom
            previewImageVC.delegate = self
            self.present(previewImageVC, animated: true, completion: nil)
        }
    }
    
    func sendChatFromPreviewImage(message_text: String, attachment_flag: String, image_id: String, video_id: String, thumb_id: String, viewController: UIViewController) {
        sendChat(message_text: message_text, attachment_flag: attachment_flag, image_id: image_id, video_id: video_id, thumb_id: thumb_id, viewController: viewController)
    }
}

extension EditorGroup: UIDocumentPickerDelegate, DocumentPickerDelegate, QLPreviewControllerDataSource {
    public func didSelectDocument(document: Any?) {
        if (document != nil) {
            self.previewItem = (document as! [URL])[0] as NSURL
            let previewController = QLPreviewController()
            let navController = UINavigationController(rootViewController: previewController)
            let leftBarButton = navigationQLPreviewDocument(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancelDocumentPreview))
            let rightBarButton = navigationQLPreviewDocument(title: "Send".localized(), style: .done, target: self, action: #selector(sendDocument))
//            leftBarButton.tintColor = .white
//            rightBarButton.tintColor = .white
            leftBarButton.navigation = navController
            rightBarButton.navigation = navController
//            navController.navigationBar.barTintColor = .mainColor
            navController.navigationBar.isTranslucent = false
            previewController.navigationItem.leftBarButtonItem = leftBarButton
            previewController.navigationItem.rightBarButtonItem = rightBarButton
            previewController.dataSource = self
            previewController.modalPresentationStyle = .pageSheet
            
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    @objc private func cancelDocumentPreview(sender: navigationQLPreviewDocument) {
        sender.navigation.dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendDocument(sender: navigationQLPreviewDocument) {
        sender.navigation.dismiss(animated: true, completion: nil)
        do {
            let dataFile = try Data(contentsOf: self.previewItem! as URL)
            let urlFile = self.previewItem?.absoluteString
            var originaFileName = (urlFile! as NSString).lastPathComponent
            originaFileName = NSString(string: originaFileName).removingPercentEncoding!
            let renamedNameFile = "Qmera_doc_" + "\(Date().millisecondsSince1970)_" + originaFileName
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(renamedNameFile)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try dataFile.write(to: fileURL)
                    print("file saved")
                } catch {
                    print("error saving file:", error)
                }
            }
            sendChat(message_text: "\(originaFileName)|", attachment_flag: "6", file_id: renamedNameFile, viewController: self)
        } catch {
            
        }
    }
}

extension EditorGroup: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        if allowTyping {
            allowTyping = false
            if dataTopic["chat_id"] as! String == "" {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataGroup["group_id"] as! String])
                sendTyping(l_pin: dataGroup["group_id"] as! String)
            } else {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataTopic["chat_id"] as! String])
                sendTyping(l_pin: dataTopic["chat_id"] as! String)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                self.allowTyping = true
            })
        }
        if let selectedRange = textView.selectedTextRange {
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            let beforeCursor = textView.text.substring(from: cursorPosition - cursorPosition, to: cursorPosition - 1).split(separator: " ").last
            let afterCursor = textView.text.substring(from: cursorPosition, to: textView.text.count - 1).split(separator: " ").first
            var firstCount = 0
            var lastCount = textView.text.count
            if beforeCursor != nil {
                firstCount = cursorPosition - beforeCursor!.count - 1
                if firstCount == -1 {
                    firstCount = 0
                }
                if beforeCursor!.lowercased().checkStartWithLink() {
                    if textView.text.split(separator: " ").count > 1 && self.containerLink.isDescendant(of: self.viewTextfield) {
                        
                    } else {
                        if ((beforeCursor!.lowercased().starts(with: "www.") && beforeCursor!.lowercased().split(separator: ".").count >= 3) || (!beforeCursor!.lowercased().starts(with: "www.") && beforeCursor!.lowercased().split(separator: ".").count >= 2)) && beforeCursor!.lowercased().split(separator: ".").last!.count >= 2 {
                            checkLink(text: beforeCursor!.lowercased())
                        } else {
                            deleteLinkPreview()
                        }
                    }
                }
            }
            if afterCursor != nil {
                if beforeCursor == nil {
                    lastCount = afterCursor!.count + 2
                } else {
                    lastCount = beforeCursor!.count + afterCursor!.count + 2
                }
                if afterCursor!.lowercased().checkStartWithLink() {
                    if textView.text.split(separator: " ").count > 1 && self.containerLink.isDescendant(of: self.viewTextfield) {
                        
                    } else {
                        if ((afterCursor!.lowercased().starts(with: "www.") && afterCursor!.lowercased().split(separator: ".").count >= 3) || afterCursor!.lowercased().split(separator: ".").count >= 2) && afterCursor!.lowercased().split(separator: ".").last!.count >= 2 {
                            checkLink(text: afterCursor!.lowercased())
                        } else {
                            deleteLinkPreview()
                        }
                    }
                }
            }
            if textView.text.contains("*") || textView.text.contains("_") || textView.text.contains("^") || textView.text.contains("~") {
                textView.preserveCursorPosition(withChanges: { _ in
                    textView.attributedText = textView.text.richText(isEditing: true, first: firstCount, last: lastCount)
                    return .preserveCursor
                })
            }
        }
    }
    
    private func checkLink(text: String) {
        var stringURl = text
        if stringURl.starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        var dataURL = ""
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select data_link from LINK_PREVIEW where link='\(stringURl)'") {
                while cursor.next() {
                    if let data = cursor.string(forColumnIndex: 0) {
                        dataURL = data
                    }
                }
                cursor.close()
            }
        })
        if !dataURL.isEmpty {
            if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                let title = data["title"] as! String
                let description = data["description"] as! String
                let imageUrl = data["imageUrl"] as? String
                self.buildPreviewLink(imageUrl: imageUrl, title: title, description: description, stringURl: text)
            }
        } else {
            let urlData = URL(string: stringURl)!
            Readability.parse(url: urlData, completion: { data in
                self.deleteLinkPreview()
                
                if data != nil {
                    let title = data!.title
                    let description = data!.description
                    let imageUrl = data!.topImage
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            var dataJson: [String: Any] = [:]
                            dataJson["title"] = title
                            dataJson["description"] = description
                            dataJson["imageUrl"] = imageUrl
                            guard let json = String(data: try! JSONSerialization.data(withJSONObject: dataJson, options: []), encoding: String.Encoding.utf8) else {
                                return
                            }
                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "LINK_PREVIEW", cvalues: [
                                "id" : "\(Date().currentTimeMillis().toHex())",
                                "link" : stringURl,
                                "data_link" : json,
                                "retry": 0
                            ], replace: true)
                        } catch {
                            rollback.pointee = true
                            print(error)
                        }
                    })
                    
                    self.buildPreviewLink(imageUrl: imageUrl, title: title, description: description, stringURl: text)
                }
            })
        }
    }
    
    private func buildPreviewLink(imageUrl: String?, title: String, description: String?, stringURl: String) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.constraintTopTextField.constant = self.constraintTopTextField.constant + 80
        }, completion: nil)
        
        self.viewTextfield.addSubview(self.containerLink)
        self.containerLink.translatesAutoresizingMaskIntoConstraints = false
        self.containerLink.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
        self.containerLink.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor).isActive = true
        self.containerLink.trailingAnchor.constraint(equalTo: self.viewTextfield.trailingAnchor).isActive = true
        self.containerLink.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        self.containerLink.backgroundColor = .secondaryColor
        
        if self.reffId != nil {
            self.bottomAnchorPreviewReply.isActive = false
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.containerLink.topAnchor)
            self.bottomAnchorPreviewReply.isActive = true
        }
        
        let imagePreview = UIImageView()
        if imageUrl != nil {
            self.containerLink.addSubview(imagePreview)
            imagePreview.translatesAutoresizingMaskIntoConstraints = false
            imagePreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor).isActive = true
            imagePreview.bottomAnchor.constraint(equalTo: self.containerLink.bottomAnchor).isActive = true
            imagePreview.topAnchor.constraint(equalTo: self.containerLink.topAnchor).isActive = true
            imagePreview.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
            if !imageUrl!.starts(with: "https://") {
                imagePreview.loadImageAsync(with: "https://www.google.be" + imageUrl!)
            } else {
                imagePreview.loadImageAsync(with: imageUrl)
            }
            imagePreview.contentMode = .scaleAspectFit
        }
        
        let titlePreview = UILabel()
        self.containerLink.addSubview(titlePreview)
        titlePreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            titlePreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            titlePreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        titlePreview.topAnchor.constraint(equalTo: self.containerLink.topAnchor, constant: 25.0).isActive = true
        titlePreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        titlePreview.text = title
        titlePreview.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        titlePreview.textColor = .black
        
        let descPreview = UILabel()
        self.containerLink.addSubview(descPreview)
        descPreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            descPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            descPreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        descPreview.topAnchor.constraint(equalTo: titlePreview.bottomAnchor).isActive = true
        descPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        descPreview.text = description
        descPreview.font = UIFont.systemFont(ofSize: 12.0)
        descPreview.textColor = .gray
        descPreview.numberOfLines = 1
        
        let linkPreview = UILabel()
        self.containerLink.addSubview(linkPreview)
        linkPreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            linkPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            linkPreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        linkPreview.topAnchor.constraint(equalTo: descPreview.bottomAnchor, constant: 8.0).isActive = true
        linkPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        linkPreview.text = stringURl
        linkPreview.font = UIFont.systemFont(ofSize: 10.0)
        linkPreview.textColor = .gray
        linkPreview.numberOfLines = 1
        
        let cancelPreview = UIButton(type: .custom)
        self.containerLink.addSubview(cancelPreview)
        cancelPreview.translatesAutoresizingMaskIntoConstraints = false
        cancelPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -10).isActive = true
        cancelPreview.centerYAnchor.constraint(equalTo: self.containerLink.centerYAnchor).isActive = true
        cancelPreview.setImage(UIImage(systemName: "xmark.circle" , withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)), for: .normal)
        cancelPreview.addTarget(nil, action: #selector(self.deleteLinkPreview), for: .touchUpInside)
        cancelPreview.backgroundColor = .clear
        cancelPreview.tintColor = .mainColor
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Send message".localized()
            textView.textColor = UIColor.lightGray
        }
    }
    
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) && (UIPasteboard.general.image != nil) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    public override func paste(_ sender: Any?) {
        if UIPasteboard.general.image != nil {
            let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
            previewImageVC.image = UIPasteboard.general.image
            previewImageVC.fromCopy = true
            previewImageVC.currentTextTextField = textFieldSend.text
            previewImageVC.modalPresentationStyle = .custom
            previewImageVC.delegate = self
            self.present(previewImageVC, animated: true, completion: nil)
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let cursorPosition = textView.caretRect(for: self.textFieldSend.selectedTextRange!.start).origin
        let currentLine = Int(cursorPosition.y / self.textFieldSend.font!.lineHeight)
        UIView.animate(withDuration: 0.3) {
            if currentLine == 0 && text != "\n"{
                self.heightTextFieldSend.constant = 40
            } else if currentLine < 4 {
                DispatchQueue.main.async {
                    if (self.currentIndexpath != nil) {
                        self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                    }
                }
                if (text == "\n" && self.textFieldSend.text.count > 0) {
                    self.heightTextFieldSend.constant = self.textFieldSend.contentSize.height + 18
                }
                else if (self.textFieldSend.text.count > 0) {
                    self.heightTextFieldSend.constant = self.textFieldSend.contentSize.height
                }
                
                let txt = textView.text
                let txtRange = Range(range, in: txt!)
                let subString: Substring = txt![txtRange!]
                if  subString == "\n" {
                    self.heightTextFieldSend.constant = self.textFieldSend.contentSize.height - 18
                    if (self.heightTextFieldSend.constant <= 50 && self.heightTextFieldSend.constant >= 40) {
                        self.heightTextFieldSend.constant = 40
                    }
                }
            }
            let countBreakLine = text.split(separator: "\n").count
            if countBreakLine > 1 && self.heightTextFieldSend.constant != CGFloat(40 + (countBreakLine * 18)) {
                self.heightTextFieldSend.constant = CGFloat(40 + (countBreakLine * 18))
            }
        }
        if (self.textFieldSend.text.count == 0) {
            return text != "\n"
        }
        return true
    }
}

extension EditorGroup: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if textFieldSend.isFirstResponder {
            textFieldSend.resignFirstResponder()
        }
        let indexPath = self.tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: self.tableChatView))
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
        var star: UIAction
        if (dataMessages[indexPath!.row]["is_stared"] as! String == "0") {
            star = UIAction(title: "Star".localized(), image: UIImage(systemName: "star.fill"), handler: {(_) in
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "is_stared" : 1
                        ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"] as! String)'")
                    })
                }
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[indexPath!.row]["message_id"] as! String})
                if idx != nil{
                    self.dataMessages[idx!]["is_stared"] = "1"
                }
                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
            })
        } else {
            star = UIAction(title: "Unstar".localized(), image: UIImage(systemName: "star.fill"), handler: {(_) in
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "is_stared" : 0
                        ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"] as! String)'")
                    })
                }
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[indexPath!.row]["message_id"] as! String})
                if idx != nil{
                    self.dataMessages[idx!]["is_stared"] = "0"
                }
                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
            })
        }
        
        let reply = UIAction(title: "Reply".localized(), image: UIImage(systemName: "arrowshape.turn.up.left.fill"), handler: {(_) in
            self.deleteReplyView()
            self.textFieldSend.becomeFirstResponder()
            self.reffId = dataMessages[indexPath!.row]["message_id"] as? String
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant + 50
            }, completion: nil)
            if (self.currentIndexpath != nil) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                }
            } else {
                self.tableChatView.scrollToBottom()
            }
            
            self.viewTextfield.addSubview(self.containerPreviewReply)
            self.containerPreviewReply.translatesAutoresizingMaskIntoConstraints = false
            self.containerPreviewReply.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
            self.containerPreviewReply.topAnchor.constraint(equalTo: self.viewTextfield.topAnchor).isActive = true
            if !self.containerLink.isDescendant(of: self.viewTextfield) {
                self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor)
            } else {
                self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.containerLink.topAnchor)
            }
            self.bottomAnchorPreviewReply.isActive = true
            self.containerPreviewReply.trailingAnchor.constraint(equalTo: self.viewTextfield.trailingAnchor).isActive = true
            self.containerPreviewReply.backgroundColor = .secondaryColor
            
            let leftReply = UIView()
            self.containerPreviewReply.addSubview(leftReply)
            leftReply.translatesAutoresizingMaskIntoConstraints = false
            leftReply.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
            leftReply.topAnchor.constraint(equalTo: self.containerPreviewReply.topAnchor).isActive = true
            leftReply.bottomAnchor.constraint(equalTo: self.containerPreviewReply.bottomAnchor).isActive = true
            leftReply.widthAnchor.constraint(equalToConstant: 3).isActive = true
            leftReply.backgroundColor = .orangeColor
            
            let titleReply = UILabel()
            self.containerPreviewReply.addSubview(titleReply)
            titleReply.translatesAutoresizingMaskIntoConstraints = false
            titleReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
            titleReply.topAnchor.constraint(equalTo: self.containerPreviewReply.topAnchor, constant: 10).isActive = true
            titleReply.font = UIFont.systemFont(ofSize: 12).bold
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            if (dataMessages[indexPath!.row]["f_pin"] as? String == idMe) {
                titleReply.text = "You".localized()
            } else {
                if dataMessages[indexPath!.row]["f_pin"] as? String != "-999" {
                    let dataPerson = self.getDataProfile(f_pin: dataMessages[indexPath!.row]["f_pin"] as! String, message_id: dataMessages[indexPath!.row]["message_id"] as! String)
                    titleReply.text = dataPerson["name"]
                } else {
                    titleReply.text = "Bot"
                }
            }
            titleReply.textColor = .orangeColor
            
            let contentReply = UILabel()
            self.containerPreviewReply.addSubview(contentReply)
            contentReply.translatesAutoresizingMaskIntoConstraints = false
            contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
            contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor).isActive = true
            contentReply.font = UIFont.systemFont(ofSize: 10)
            let message_text = dataMessages[indexPath!.row]["message_text"] as! String
            let attachment_flag = dataMessages[indexPath!.row]["attachment_flag"] as! String
            let thumb_chat = dataMessages[indexPath!.row]["thumb_id"] as! String
            let image_chat = dataMessages[indexPath!.row]["image_id"] as! String
            let video_chat = dataMessages[indexPath!.row]["video_id"] as! String
            let file_chat = dataMessages[indexPath!.row]["file_id"] as! String
            if (attachment_flag == "0" && thumb_chat == "") {
                contentReply.attributedText = message_text.richText()
            } else if (attachment_flag == "1" || image_chat != "") {
                if (message_text == "") {
                    contentReply.text = "📷 Photo".localized()
                } else {
                    contentReply.attributedText = message_text.richText()
                }
            } else if (attachment_flag == "2" || video_chat != "") {
                if (message_text == "") {
                    contentReply.text = "📹 Video".localized()
                } else {
                    contentReply.attributedText = message_text.richText()
                }
            } else if (attachment_flag == "6" || file_chat != ""){
                contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
            } else if (attachment_flag == "11") {
                contentReply.text = "❤️ Sticker"
            } else if attachment_flag == "27" {
                contentReply.text = "📄 " + "Live Streaming".localized()
            } else if attachment_flag == "26" {
                contentReply.text = "📄 " + "Seminar".localized()
            }
            contentReply.textColor = .gray
            
            let buttonCancelReply = UIButton(type: .custom)
            self.containerPreviewReply.addSubview(buttonCancelReply)
            buttonCancelReply.translatesAutoresizingMaskIntoConstraints = false
            buttonCancelReply.trailingAnchor.constraint(equalTo: self.containerPreviewReply.trailingAnchor, constant: -10).isActive = true
            buttonCancelReply.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
            buttonCancelReply.setImage(UIImage(systemName: "xmark.circle" , withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)), for: .normal)
            buttonCancelReply.addTarget(nil, action: #selector(self.deleteReplyView), for: .touchUpInside)
            buttonCancelReply.backgroundColor = .clear
            buttonCancelReply.tintColor = .mainColor
            
            if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                if let dirPath = paths.first {
                    let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
                    let image    = UIImage(contentsOfFile: thumbURL.path)
                    let imageThumb = UIImageView(image: image)
                    self.containerPreviewReply.addSubview(imageThumb)
                    imageThumb.layer.cornerRadius = 2.0
                    imageThumb.clipsToBounds = true
                    imageThumb.translatesAutoresizingMaskIntoConstraints = false
                    imageThumb.trailingAnchor.constraint(equalTo: buttonCancelReply.leadingAnchor, constant: -10).isActive = true
                    imageThumb.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
                    imageThumb.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    imageThumb.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    
                    if (attachment_flag == "2") {
                        let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                        imageThumb.addSubview(imagePlay)
                        imagePlay.clipsToBounds = true
                        imagePlay.translatesAutoresizingMaskIntoConstraints = false
                        imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                        imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                        imagePlay.widthAnchor.constraint(equalToConstant: 10).isActive = true
                        imagePlay.heightAnchor.constraint(equalToConstant: 10).isActive = true
                        imagePlay.tintColor = .white
                    }
                }
            }
            if (attachment_flag == "11") {
                let imageSticker = UIImageView(image: UIImage(named: (message_text.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
                self.containerPreviewReply.addSubview(imageSticker)
                imageSticker.layer.cornerRadius = 2.0
                imageSticker.clipsToBounds = true
                imageSticker.translatesAutoresizingMaskIntoConstraints = false
                imageSticker.trailingAnchor.constraint(equalTo: buttonCancelReply.leadingAnchor, constant: -10).isActive = true
                imageSticker.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
                imageSticker.widthAnchor.constraint(equalToConstant: 30).isActive = true
                imageSticker.heightAnchor.constraint(equalToConstant: 30).isActive = true
            }
        })
        let forward = UIAction(title: "Forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right.fill"), handler: {(_) in
            self.forwardSession = true
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[indexPath!.row]["message_id"] as! String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let copy = UIAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc.fill"), handler: {(_) in
            self.copySession = true
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[indexPath!.row]["message_id"] as! String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let delete = UIAction(title: "Delete".localized(), image: UIImage(systemName: "trash.fill"), attributes: .destructive, handler: {(_) in
            self.deleteSession = true
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[indexPath!.row]["message_id"] as! String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        
        var children: [UIMenuElement] = [star, reply, forward, copy, delete]
//        let copyOption = self.copyOption(indexPath: indexPath!)
        
        if (dataMessages[indexPath!.row]["lock"] != nil && dataMessages[indexPath!.row]["lock"] as! String == "1") {
            children = [delete]
        }
        else if dataMessages[indexPath!.row]["f_pin"] as! String == "-999" {
            children = [star, reply ,delete]
        }
        else if self.removed {
            children = [star, forward, copy ,delete]
            if !(dataMessages[indexPath!.row]["image_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["video_id"] as! String).isEmpty {
                children = [star, forward ,delete]
            }
        }
        else if !(dataMessages[indexPath!.row]["image_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["video_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["file_id"] as! String).isEmpty || dataMessages[indexPath!.row]["attachment_flag"] as! String == "11" {
            children = [star, reply, forward ,delete]
        }
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: children)
        }
    }
    
    @objc func cancelAction() {
        DispatchQueue.main.async {
            if self.copySession {
                self.copySession = false
            } else if self.forwardSession {
                self.forwardSession = false
            } else if self.deleteSession {
                self.deleteSession = false
            }
            let data = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            for i in 0..<data.count {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == data[i]["message_id"] as! String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = false
                }
            }
            self.tableChatView.reloadData()
            self.setRightButtonItem()
            self.changeAppBar()
            self.containerMultpileSelectSession.removeFromSuperview()
            self.checkNewMessage(tableView: self.tableChatView)
        }
    }
    
    private func addMultipleSelectSession() {
        view.addSubview(containerMultpileSelectSession)
        containerMultpileSelectSession.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerMultpileSelectSession.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerMultpileSelectSession.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            containerMultpileSelectSession.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            containerMultpileSelectSession.heightAnchor.constraint(equalToConstant: 120)
        ])
        containerMultpileSelectSession.backgroundColor = .white
        addSubviewMultipleSession()
    }
    
    private func addSubviewMultipleSession() {
        let container = UIView()
        containerMultpileSelectSession.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: containerMultpileSelectSession.leadingAnchor),
            container.trailingAnchor.constraint(equalTo:containerMultpileSelectSession.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: containerMultpileSelectSession.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 50)
        ])
        container.layer.shadowOpacity = 0.7
        container.layer.shadowOffset = CGSize(width: 3, height: 3)
        container.layer.shadowRadius = 3.0
        container.layer.shadowColor = UIColor.black.cgColor
        container.backgroundColor = .secondaryColor
        
        let title = UILabel()
        container.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            title.centerYAnchor.constraint(equalTo:container.centerYAnchor),
        ])
        let countSelected = dataMessages.filter({ $0["isSelected"] as! Bool == true }).count
        title.text = "\(countSelected) " + "Selected".localized()
        title.textColor = .mainColor
        title.font = UIFont.systemFont(ofSize: 15).bold
        
        let button = UIImageView()
        container.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            button.centerYAnchor.constraint(equalTo:container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30),
        ])
        if copySession {
            button.image = UIImage(systemName: "doc.on.doc")
            if countSelected == 0{
                button.tintColor = .gray
            } else {
                button.tintColor = .mainColor
            }
        } else if forwardSession {
            button.image = UIImage(systemName: "arrowshape.turn.up.right")
            if countSelected == 0{
                button.tintColor = .gray
            } else {
                button.tintColor = .mainColor
            }
        } else if deleteSession {
            button.image = UIImage(systemName: "trash")
            if countSelected == 0{
                button.tintColor = .gray
            } else {
                button.tintColor = .red
            }
        }
        let buttonGesture = UITapGestureRecognizer(target: self, action: #selector(sessionAction))
        button.isUserInteractionEnabled = true
        button.addGestureRecognizer(buttonGesture)
    }
    
    @objc func sessionAction() {
        if copySession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            var nameTopic = "Lounge".localized()
            if !dataTopic.isEmpty {
                nameTopic = dataTopic["title"] as! String
            }
            var text = "*^\(dataGroup["f_name"]!!) (\(nameTopic))^*"
            for i in 0..<countSelected {
                let stringDate = (dataMessages[i]["server_date"] as! String)
                let date = Date(milliseconds: Int64(stringDate)!)
                let formatterDate = DateFormatter()
                let formatterTime = DateFormatter()
                formatterDate.dateFormat = "dd/MM/yy"
                formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                formatterTime.dateFormat = "HH:mm"
                formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                let dataProfile = getDataProfile(f_pin: dataMessages[i]["f_pin"] as! String, message_id: dataMessages[i]["message_id"] as! String)
                text = text + "\n\n*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[i]["message_text"] as! String)"
            }
            text = text + "\n\n\nchat powered by Nexilis"
            DispatchQueue.main.async {
                UIPasteboard.general.string = text
                self.showToast(message: "Text coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
            }
            cancelAction()
        } else if forwardSession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
            navigationController.modalPresentationStyle = .custom
            if let controller = navigationController.viewControllers.first as? ContactChatViewController {
                controller.isChooser = { [weak self] scope, pin in
                    if scope == "3" {
                        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                        editorPersonalVC.unique_l_pin = pin
                        editorPersonalVC.dataMessageForward = dataMessages
                        self?.navigationController?.replaceAllViewController(with: editorPersonalVC, animated: true)
                    } else {
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.unique_l_pin = pin
                        editorGroupVC.dataMessageForward = dataMessages
                        self?.navigationController?.replaceAllViewController(with: editorGroupVC, animated: true)
                    }
                }
            }
            self.present(navigationController, animated: true, completion: nil)
        } else if deleteSession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if let action = self.actionDelete(for: "me", title: "Delete".localized() + " \(countSelected) " + "For Me".localized(), dataMessages: dataMessages) {
                alertController.addAction(action)
            }
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            let dataFilterFpin = dataMessages.filter({ $0["f_pin"] as? String != idMe})
            let dataFilterLock = dataMessages.filter({ $0["lock"] as? String == "1"})
            if dataFilterFpin.count == 0 && dataFilterLock.count == 0 {
                if let action = self.actionDelete(for: "everyone", title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), dataMessages: dataMessages) {
                    alertController.addAction(action)
                }
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
        }
    }
    
    private func deleteMessage(l_pin: String, message_id: String, scope: String, type: String, chat: String) {
        let tmessage = CoreMessage_TMessageBank.deleteMessage(l_pin: l_pin, messageId: message_id, scope: scope, type: type, chat: chat)
        Nexilis.addQueueMessage(message: tmessage)
    }
    
    private func queryMessageReply(message_id: String) -> [String: Any?] {
        var dataQuery: [String: Any] = [:]
        Database().database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, message_text, attachment_flag, thumb_id, image_id, video_id, file_id FROM MESSAGE where message_id='\(message_id)'"), c.next() {
                dataQuery["message_id"] = c.string(forColumnIndex: 0)
                dataQuery["f_pin"] = c.string(forColumnIndex: 1)
                dataQuery["message_text"] = c.string(forColumnIndex: 2)
                dataQuery["attachment_flag"] = c.string(forColumnIndex: 3)
                dataQuery["thumb_id"] = c.string(forColumnIndex: 4)
                dataQuery["image_id"] = c.string(forColumnIndex: 5)
                dataQuery["video_id"] = c.string(forColumnIndex: 6)
                dataQuery["file_id"] = c.string(forColumnIndex: 7)
                c.close()
            }
        })
        return dataQuery
    }
    
    @objc func segmentedControlValueChanged(_ sender: segmentedControllerObject) {
        switch sender.selectedSegmentIndex {
        case 0:
            sender.navigation.viewControllers[0].children[1].view.isHidden = true
            break;
        case 1:
            sender.navigation.viewControllers[0].children[1].view.isHidden = false
            break;
        default:
            break;
        }
    }
    
    private func copyOption(indexPath: IndexPath) -> UIMenu {
        var ratingButtonTitles = ["Text".localized(), "Image".localized()]
        if (dataMessages[indexPath.row]["message_text"] as! String).isEmpty {
            ratingButtonTitles = ["Image".localized()]
        }
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        let copyActions = ratingButtonTitles
            .enumerated()
            .map { index, title in
                return UIAction(
                    title: title,
                    identifier: nil,
                    handler: {(_) in
                        if (dataMessages[indexPath.row]["message_text"] as! String).isEmpty {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        UIPasteboard.general.image = image
                                        self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                    }
                                }
                            }
                            return
                        }
                        if (index == 0) {
                            DispatchQueue.main.async {
                                UIPasteboard.general.string = dataMessages[indexPath.row]["message_text"] as? String
                                self.showToast(message: "Text coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        UIPasteboard.general.image = image
                                        self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                    }
                                }
                            }
                        }
                        self.dismissKeyboard()
                        
                    })
            }
        return UIMenu(
            title: "Copy".localized(),
            image: UIImage(systemName: "doc.on.doc.fill"),
            children: copyActions)
    }
    
    private func actionDelete(for type: String, title: String, dataMessages: [[String: Any?]]) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .destructive) { [unowned self] _ in
            for i in 0..<dataMessages.count {
                if (type == "me") {
                    self.deleteMessage(l_pin: dataGroup["group_id"] as! String, message_id: dataMessages[i]["message_id"] as! String, scope: "4", type: "1", chat: dataTopic["chat_id"] as! String)
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                    if idx != nil {
                        self.dataMessages.remove(at: idx!)
                        if (idx == self.dataMessages.count - 1) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        }
                        for i in 0..<dataDates.count {
                            if self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[i] }).count == 0 {
                                dataDates.remove(at: i)
                            }
                        }
                    }
                } else {
                    self.deleteMessage(l_pin: dataGroup["group_id"] as! String, message_id: dataMessages[i]["message_id"] as! String, scope: "4", type: "2", chat: dataTopic["chat_id"] as! String)
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[i]["message_id"] as! String})
                    if idx != nil {
                        self.dataMessages[idx!]["lock"] = "1"
                        self.dataMessages[idx!]["attachment_flag"] = "0"
                        self.dataMessages[idx!]["reff_id"] = ""
                    }
                }
                cancelAction()
            }
        }
    }
    
    @objc func deleteReplyView() {
        if self.containerPreviewReply.isDescendant(of: self.viewTextfield) {
            self.containerPreviewReply.subviews.forEach { $0.removeFromSuperview() }
            self.containerPreviewReply.removeConstraints(self.containerPreviewReply.constraints)
            self.containerPreviewReply.removeFromSuperview()
            
            self.reffId = nil
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant - 50
            }, completion: nil)
        }
    }
    
    @objc func deleteLinkPreview() {
        if self.containerLink.isDescendant(of: self.viewTextfield) {
            self.containerLink.subviews.forEach { $0.removeFromSuperview() }
            self.containerLink.removeConstraints(self.containerLink.constraints)
            self.containerLink.removeFromSuperview()
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant - 80
            }, completion: nil)
        }
        if self.reffId != nil {
            self.bottomAnchorPreviewReply.isActive = false
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor)
            self.bottomAnchorPreviewReply.isActive = true
        }
    }
}

extension EditorGroup: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 76
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellSticker", for: indexPath)
        if (cell.contentView.subviews.count > 0) {
            cell.contentView.subviews[0].removeFromSuperview()
        }
        let imageSticker = UIImageView()
        cell.contentView.addSubview(imageSticker)
        imageSticker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageSticker.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            imageSticker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            imageSticker.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            imageSticker.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
        ])
        imageSticker.image = UIImage(named: stickers[indexPath.row], in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        sendChat(message_text: "sticker/\(stickers[indexPath.row])", attachment_flag: "11", viewController: self)
        constraintBottomAttachment.constant = 0.0
        self.viewSticker.removeConstraints(self.viewSticker.constraints)
        self.viewSticker.removeFromSuperview()
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem!
    }
}

extension EditorGroup: UITableViewDelegate, UITableViewDataSource {
//    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        checkNewMessage(tableView: tableView)
//    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        checkNewMessage(tableView: self.tableChatView)
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section] }).count
        return count
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let dateView = UIView()
        containerView.addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        var topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor)
        if section == 0 {
            topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10.0)
        }
        NSLayoutConstraint.activate([
            topAnchor,
            dateView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dateView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dateView.heightAnchor.constraint(equalToConstant: 30),
            dateView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        dateView.backgroundColor = .orangeColor
        dateView.layer.cornerRadius = 15.0
        dateView.clipsToBounds = true
        
        let labelDate = UILabel()
        dateView.addSubview(labelDate)
        labelDate.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelDate.centerYAnchor.constraint(equalTo: dateView.centerYAnchor),
            labelDate.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
            labelDate.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: 10),
            labelDate.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -10),
        ])
        labelDate.textAlignment = .center
        labelDate.textColor = .secondaryColor
        labelDate.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        labelDate.text = dataDates[section]
        return containerView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 40
        }
        return 30
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section] })
        if copySession || forwardSession || deleteSession {
            if copySession && dataMessages[indexPath.row]["f_pin"] as! String != "-999" {
                return
            }
            if (dataMessages[indexPath.row]["attachment_flag"] as! String != "0" || dataMessages[indexPath.row]["lock"] as? String == "1") && !forwardSession && !deleteSession {
                return
            }
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[indexPath.row]["message_id"] as! String})
            if idx != nil {
                self.dataMessages[idx!]["isSelected"] = !(self.dataMessages[idx!]["isSelected"] as! Bool)
                self.tableChatView.reloadRows(at: [indexPath], with: .none)
            }
            containerMultpileSelectSession.subviews.forEach({ $0.removeFromSuperview() })
            addSubviewMultipleSession()
            return
        }
        if !(dataMessages[indexPath.row]["image_id"] as! String).isEmpty || !(dataMessages[indexPath.row]["video_id"] as! String).isEmpty || !(dataMessages[indexPath.row]["file_id"] as! String).isEmpty {
            var file = dataMessages[indexPath.row]["image_id"] as! String
            if file.isEmpty {
                file = dataMessages[indexPath.row]["video_id"] as! String
                if file.isEmpty {
                    file = dataMessages[indexPath.row]["file_id"] as! String
                }
            }
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    return
                }
            }
        }
        let message = dataMessages[indexPath.row]
        if let attachmentFlag = message["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" {
                let streamingController = QmeraCreateStreamingViewController()
                streamingController.isJoin = true
                if let messageText = message["message_text"],
                   let messageText = messageText as? String,
                   var json = try! JSONSerialization.jsonObject(with: messageText.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    if json["blog"] == nil {
                        json["blog"] = message["blog_id"] ?? nil
                    }
                    streamingController.data = json
                }
                let streamingNav = UINavigationController(rootViewController: streamingController)
                streamingNav.modalPresentationStyle = .custom
                streamingNav.navigationBar.barTintColor = .mainColor
                streamingNav.navigationBar.tintColor = .white
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                streamingNav.navigationBar.titleTextAttributes = textAttributes
                streamingNav.navigationBar.isTranslucent = false
                navigationController?.present(streamingNav, animated: true, completion: nil)
            }
        }
    }
    
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idMe = UserDefaults.standard.string(forKey: "me") as String?
        let dataMessages = dataMessages.filter({$0["chat_date"] as! String == dataDates[indexPath.section]})
        
        let cellMessage = UITableViewCell()
        cellMessage.backgroundColor = .clear
        cellMessage.selectionStyle = .none
        
        let profileMessage = UIImageView()
        profileMessage.frame.size = CGSize(width: 35, height: 35)
        cellMessage.contentView.addSubview(profileMessage)
        profileMessage.translatesAutoresizingMaskIntoConstraints = false
        let tapGestureRecognizer = ObjectGesture(target: self, action: #selector(profilePersonTapped(_:)))
        tapGestureRecognizer.message_id = dataMessages[indexPath.row]["f_pin"] as! String
        profileMessage.isUserInteractionEnabled = true
        profileMessage.addGestureRecognizer(tapGestureRecognizer)
        
        let containerMessage = UIView()
        if !copySession && !forwardSession && !deleteSession && !isHistoryCC {
            let interaction = UIContextMenuInteraction(delegate: self)
            containerMessage.addInteraction(interaction)
            containerMessage.isUserInteractionEnabled = true
        }
        
        let thumbChat = dataMessages[indexPath.row]["thumb_id"] as! String
        let imageChat = dataMessages[indexPath.row]["image_id"] as! String
        let videoChat = dataMessages[indexPath.row]["video_id"] as! String
        let fileChat = dataMessages[indexPath.row]["file_id"] as! String
        let reffChat = dataMessages[indexPath.row]["reff_id"] as! String
        
        cellMessage.contentView.addSubview(containerMessage)
        containerMessage.translatesAutoresizingMaskIntoConstraints = false
        
        let timeMessage = UILabel()
        cellMessage.contentView.addSubview(timeMessage)
        timeMessage.translatesAutoresizingMaskIntoConstraints = false
        timeMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5).isActive = true
        
        let messageText = UILabel()
        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        let topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32)
        
        let dataProfile = getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"] as! String, message_id: dataMessages[indexPath.row]["message_id"] as! String)
        
        let statusMessage = UIImageView()
        
        if (dataMessages[indexPath.row]["attachment_flag"] as? String == "0" && dataMessages[indexPath.row]["lock"] as? String != "1") || forwardSession || deleteSession {
            var showSelectedImage = true
            if (!imageChat.isEmpty || !videoChat.isEmpty || !fileChat.isEmpty) && forwardSession {
                var file = dataMessages[indexPath.row]["image_id"] as! String
                if file.isEmpty {
                    file = dataMessages[indexPath.row]["video_id"] as! String
                    if file.isEmpty {
                        file = dataMessages[indexPath.row]["file_id"] as! String
                    }
                }
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                if let dirPath = paths.first {
                    let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
                    if !FileManager.default.fileExists(atPath: fileURL.path) {
                        showSelectedImage = false
                    }
                }
            }
            if dataMessages[indexPath.row]["f_pin"] as! String == "-999" && !deleteSession {
                showSelectedImage = false
            }
            if showSelectedImage {
                let selectedImage = UIImageView()
                cellMessage.contentView.addSubview(selectedImage)
                selectedImage.translatesAutoresizingMaskIntoConstraints = false
                selectedImage.frame.size = CGSize(width: 20, height: 20)
                var leading = selectedImage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: -20)
                if copySession || forwardSession || deleteSession {
                    leading = selectedImage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 15)
                }
                NSLayoutConstraint.activate([
                    leading,
                    selectedImage.centerYAnchor.constraint(equalTo: cellMessage.contentView.centerYAnchor),
                    selectedImage.widthAnchor.constraint(equalToConstant: 20),
                    selectedImage.heightAnchor.constraint(equalToConstant: 20)
                ])
                selectedImage.circle()
                selectedImage.layer.borderWidth = 2
                selectedImage.layer.borderColor = UIColor.mainColor.cgColor
                if dataMessages[indexPath.row]["isSelected"] as! Bool {
                    selectedImage.image = UIImage(systemName: "checkmark.circle.fill")
                }
                selectedImage.tintColor = .mainColor
            }
        }
        
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            profileMessage.trailingAnchor.constraint(equalTo: cellMessage.contentView.trailingAnchor, constant: -15).isActive = true
            profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
            profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
            profileMessage.circle()
            profileMessage.clipsToBounds = true
            profileMessage.backgroundColor = .lightGray
            profileMessage.image = UIImage(systemName: "person")
            profileMessage.tintColor = .white
            profileMessage.contentMode = .scaleAspectFit
            
            let pictureImage = dataProfile["image_id"]
            if (pictureImage != "" && pictureImage != nil) {
                profileMessage.setImage(name: pictureImage!)
                profileMessage.contentMode = .scaleAspectFill
            }
            
            containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cellMessage.contentView.leadingAnchor, constant: 60).isActive = true
            containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5).isActive = true
            containerMessage.trailingAnchor.constraint(equalTo: profileMessage.leadingAnchor, constant: -5).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
            if dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String == "0" {
                cellMessage.contentView.addSubview(statusMessage)
                statusMessage.translatesAutoresizingMaskIntoConstraints = false
                statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
                statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
                statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
                if (dataMessages[indexPath.row]["status"]! as! String == "1" || dataMessages[indexPath.row]["status"]! as! String == "2" ) {
                    statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (dataMessages[indexPath.row]["status"]! as! String == "3") {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                }
            }
            
            let nameSender = UILabel()
            containerMessage.addSubview(nameSender)
            nameSender.translatesAutoresizingMaskIntoConstraints = false
            nameSender.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
            nameSender.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            nameSender.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            nameSender.font = UIFont.systemFont(ofSize: 12).bold
            nameSender.text = dataProfile["name"]
            nameSender.textAlignment = .right
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
                nameSender.textColor = .mainColor
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
                nameSender.textColor = .mainColor
            }
            
        } else {
            if copySession || forwardSession || deleteSession {
                profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 50).isActive = true
            } else {
                profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 15).isActive = true
            }
            profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
            profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
            profileMessage.circle()
            profileMessage.clipsToBounds = true
            profileMessage.backgroundColor = .lightGray
            profileMessage.image = UIImage(systemName: "person")
            profileMessage.tintColor = .white
            profileMessage.contentMode = .scaleAspectFit
            
            let pictureImage = dataProfile["image_id"]
            if dataMessages[indexPath.row]["f_pin"] as? String == "-999" {
                profileMessage.image = UIImage(named: "pb_ball", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                profileMessage.contentMode = .scaleAspectFill
            }
            else if (pictureImage != "" && pictureImage != nil) {
                profileMessage.setImage(name: pictureImage!)
                profileMessage.contentMode = .scaleAspectFill
            }
            
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 35).isActive = true
                containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 35).isActive = true
                
                let newMessagesView = UIView()
                cellMessage.contentView.addSubview(newMessagesView)
                newMessagesView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newMessagesView.topAnchor.constraint(equalTo: newMessagesView.topAnchor),
                    newMessagesView.bottomAnchor.constraint(equalTo: containerMessage.topAnchor),
                    newMessagesView.centerXAnchor.constraint(equalTo: cellMessage.contentView.centerXAnchor),
                    newMessagesView.heightAnchor.constraint(equalToConstant: 30),
                    newMessagesView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
                ])
                newMessagesView.backgroundColor = .greenColor
                newMessagesView.layer.cornerRadius = 15.0
                newMessagesView.clipsToBounds = true
                
                let labelNewMessages = UILabel()
                newMessagesView.addSubview(labelNewMessages)
                labelNewMessages.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelNewMessages.centerYAnchor.constraint(equalTo: newMessagesView.centerYAnchor),
                    labelNewMessages.centerXAnchor.constraint(equalTo: newMessagesView.centerXAnchor),
                    labelNewMessages.leadingAnchor.constraint(equalTo: newMessagesView.leadingAnchor, constant: 10),
                    labelNewMessages.trailingAnchor.constraint(equalTo: newMessagesView.trailingAnchor, constant: -10),
                ])
                labelNewMessages.textAlignment = .center
                labelNewMessages.textColor = .secondaryColor
                labelNewMessages.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                labelNewMessages.text = "Unread Messages".localized()
                
            } else {
                profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
                containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            }
            
            containerMessage.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 5).isActive = true
            containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5).isActive = true
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cellMessage.contentView.trailingAnchor, constant: -60).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .grayColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            
            let nameSender = UILabel()
            containerMessage.addSubview(nameSender)
            nameSender.translatesAutoresizingMaskIntoConstraints = false
            nameSender.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
            nameSender.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            nameSender.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            nameSender.font = UIFont.systemFont(ofSize: 12).bold
            if dataMessages[indexPath.row]["f_pin"] as? String == "-999" {
                nameSender.text = "Bot"
            }
            else {
                nameSender.text = dataProfile["name"]
            }
            nameSender.textAlignment = .left
            nameSender.textColor = .mainColor
        }
        
        if dataMessages[indexPath.row]["is_stared"] as? String == "1" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String == "0") {
            let imageStared = UIImageView()
            cellMessage.contentView.addSubview(imageStared)
            imageStared.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageStared.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
                imageStared.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            } else {
                imageStared.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                imageStared.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            }
            imageStared.widthAnchor.constraint(equalToConstant: 15).isActive = true
            imageStared.heightAnchor.constraint(equalToConstant: 15).isActive = true
            imageStared.image = UIImage(systemName: "star.fill")
            imageStared.backgroundColor = .clear
            imageStared.tintColor = .systemYellow
        }
        
        messageText.numberOfLines = 0
        messageText.lineBreakMode = .byWordWrapping
        containerMessage.addSubview(messageText)
        topMarginText.isActive = true
        if dataMessages[indexPath.row]["attachment_flag"] as! String == "27" || dataMessages[indexPath.row]["attachment_flag"] as! String == "26" {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 85).isActive = true
            let imageLS = UIImageView()
            containerMessage.addSubview(imageLS)
            imageLS.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageLS.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15.0),
                imageLS.trailingAnchor.constraint(equalTo: messageText.leadingAnchor, constant: -10.0),
                imageLS.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor),
                imageLS.heightAnchor.constraint(equalToConstant: 60.0)
            ])
            if dataMessages[indexPath.row]["attachment_flag"] as! String == "26" {
                imageLS.image = UIImage(named: "pb_seminar_wpr", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            } else if dataMessages[indexPath.row]["attachment_flag"] as! String == "27" {
                imageLS.image = UIImage(named: "pb_live_tv", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            }
        } else {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
        }
        messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15).isActive = true
        messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
        
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            messageText.textColor = .black
        } else {
            messageText.textColor = .black
        }
        
        var textChat = (dataMessages[indexPath.row]["message_text"])! as? String
        if (dataMessages[indexPath.row]["lock"] != nil && (dataMessages[indexPath.row]["lock"])! as? String == "1") {
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                textChat = "🚫 _You were deleted this message_"
            } else {
                textChat = "🚫 _This message was deleted_"
            }
        }
        
        let imageSticker = UIImageView()
        
        if let attachmentFlag = dataMessages[indexPath.row]["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26", let data = textChat { // live streaming
                if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    Database().database?.inTransaction({ fmdb, rollback in
                        let title = json["title"] as! String
                        let description = json["description"] as! String
                        let start = json["time"] as! Int64
                        let by = json["by"] as! String
                        var type = "*Live Streaming*"
                        if attachmentFlag == "26" {
                            type = "*Seminar*"
                        }
                        if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name from BUDDY where f_pin = '\(by)'"), c.next() {
                            let name = c.string(forColumnIndex: 0)!
                            messageText.attributedText = "\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: \(name)".richText()
                            c.close()
                        } else {
                            messageText.attributedText = ("\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: " + "Unknown".localized()).richText()
                        }
                    })
                }
            }
            else if attachmentFlag == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                messageText.text = ""
                topMarginText.constant = topMarginText.constant + 100
                containerMessage.addSubview(imageSticker)
                imageSticker.translatesAutoresizingMaskIntoConstraints = false
                if (reffChat == "") {
                    imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
                    imageSticker.widthAnchor.constraint(equalToConstant: 80).isActive = true
                } else {
                    imageSticker.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
                }
                imageSticker.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageSticker.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageSticker.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                imageSticker.image = UIImage(named: (textChat?.components(separatedBy: "/")[1])!, in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                imageSticker.contentMode = .scaleAspectFit
            }
            else {
                messageText.attributedText = textChat!.richText()
            }
        } else {
            messageText.attributedText = textChat!.richText()
        }
        
        messageText.isUserInteractionEnabled = true
        if !textChat!.isEmpty {
            let listText = textChat!.split(separator: " ")
            for i in 0...listText.count - 1 {
                if listText[i].lowercased().checkStartWithLink() {
                    if ((listText[i].lowercased().starts(with: "www.") && listText[i].lowercased().split(separator: ".").count >= 3) || (!listText[i].lowercased().starts(with: "www.") && listText[i].lowercased().split(separator: ".").count >= 2)) && listText[i].lowercased().split(separator: ".").last!.count >= 2 {
                        let objectGesture = ObjectGesture(target: self, action: #selector(tapMessageText(_:)))
                        objectGesture.message_id = "\(listText[i])"
                        messageText.addGestureRecognizer(objectGesture)
                    }
                }
            }
        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"] as! String)
        let date = Date(milliseconds: Int64(stringDate)!)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
        timeMessage.text = formatter.string(from: date as Date)
        timeMessage.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        timeMessage.textColor = .lightGray
        
        let imageThumb = UIImageView()
        let containerViewFile = UIView()
        
        if (thumbChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1")) {
            topMarginText.constant = topMarginText.constant + 205
            
            containerMessage.addSubview(imageThumb)
            imageThumb.translatesAutoresizingMaskIntoConstraints = false
            let data = queryMessageReply(message_id: reffChat)
            if (data.count == 0) {
                imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
            }
            imageThumb.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            imageThumb.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
            imageThumb.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            imageThumb.widthAnchor.constraint(equalToConstant: self.view.frame.size.width * 0.6).isActive = true
            imageThumb.layer.cornerRadius = 5.0
            imageThumb.clipsToBounds = true
            imageThumb.contentMode = .scaleAspectFill
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumbChat)
                let image    = UIImage(contentsOfFile: thumbURL.path)
                imageThumb.image = image
                
                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(videoChat)
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageChat)
                if !FileManager.default.fileExists(atPath: imageURL.path) || !FileManager.default.fileExists(atPath: videoURL.path){
                    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
                    blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    imageThumb.addSubview(blurEffectView)
                    if !imageChat.isEmpty {
                        let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                        imageThumb.addSubview(blurEffectView)
                        imageThumb.addSubview(imageDownload)
                        imageDownload.tintColor = .black.withAlphaComponent(0.3)
                        imageDownload.translatesAutoresizingMaskIntoConstraints = false
                        imageDownload.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                        imageDownload.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                    }
                }
                
            }
            
            if (videoChat != "") {
                let imagePlay = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default))?.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))?.withTintColor(.white))
                imagePlay.circle()
                imageThumb.addSubview(imagePlay)
                imagePlay.backgroundColor = .black.withAlphaComponent(0.3)
                imagePlay.translatesAutoresizingMaskIntoConstraints = false
                imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
            }
            
            if (dataMessages[indexPath.row]["progress"] as! Double != 100.0 && dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                let container = UIView()
                imageThumb.addSubview(container)
                container.translatesAutoresizingMaskIntoConstraints = false
                container.bottomAnchor.constraint(equalTo: imageThumb.bottomAnchor, constant: -10).isActive = true
                container.leadingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: 10).isActive = true
                container.widthAnchor.constraint(equalToConstant: 30).isActive = true
                container.heightAnchor.constraint(equalToConstant: 30).isActive = true
                container.backgroundColor = .white.withAlphaComponent(0.1)
                let circlePath = UIBezierPath(arcCenter: CGPoint(x: 10, y: 20), radius: 15, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                let trackShape = CAShapeLayer()
                trackShape.path = circlePath.cgPath
                trackShape.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
                trackShape.lineWidth = 3
                trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                container.backgroundColor = .clear
                container.layer.addSublayer(trackShape)
                let shapeLoading = CAShapeLayer()
                shapeLoading.path = circlePath.cgPath
                shapeLoading.fillColor = UIColor.clear.cgColor
                shapeLoading.lineWidth = 3
                shapeLoading.strokeEnd = 0
                shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                container.layer.addSublayer(shapeLoading)
                let imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                imageupload.tintColor = .white
                container.addSubview(imageupload)
                imageupload.translatesAutoresizingMaskIntoConstraints = false
                imageupload.bottomAnchor.constraint(equalTo: imageThumb.bottomAnchor, constant: -10).isActive = true
                imageupload.leadingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: 10).isActive = true
                imageupload.widthAnchor.constraint(equalToConstant: 20).isActive = true
                imageupload.heightAnchor.constraint(equalToConstant: 20).isActive = true
            }
            
            if !copySession && !forwardSession && !deleteSession {
                let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                imageThumb.isUserInteractionEnabled = true
                imageThumb.addGestureRecognizer(objectTap)
                objectTap.image_id = imageChat
                objectTap.video_id = videoChat
                objectTap.imageView = imageThumb
                objectTap.indexPath = indexPath
            }
        }
        
        if (fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1")) {
            topMarginText.constant = topMarginText.constant + 55
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            let arrExtFile = (textChat?.components(separatedBy: "|")[0])?.split(separator: ".")
            let finalExtFile = arrExtFile![arrExtFile!.count - 1]
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileChat)
                if let dataFile = try? Data(contentsOf: fileURL) {
                    var sizeOfFile = Int(dataFile.count / 1000000)
                    if (sizeOfFile < 1) {
                        sizeOfFile = Int(dataFile.count / 1000)
                        if (finalExtFile.count > 4) {
                            messageText.text = "\(sizeOfFile) kB \u{2022} TXT"
                        }else {
                            messageText.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                        }
                    } else {
                        if (finalExtFile.count > 4) {
                            messageText.text = "\(sizeOfFile) MB \u{2022} TXT"
                        }else {
                            messageText.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                        }
                    }
                } else {
                    messageText.text = ""
                }
            }
            
            containerMessage.addSubview(containerViewFile)
            containerViewFile.translatesAutoresizingMaskIntoConstraints = false
            let data = queryMessageReply(message_id: reffChat)
            if (data.count == 0) {
                containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
            }
            containerViewFile.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            containerViewFile.bottomAnchor.constraint(equalTo:messageText.topAnchor, constant: -5).isActive = true
            containerViewFile.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            containerViewFile.heightAnchor.constraint(equalToConstant: 50).isActive = true
            containerViewFile.backgroundColor = .black.withAlphaComponent(0.2)
            containerViewFile.layer.cornerRadius = 5.0
            containerViewFile.clipsToBounds = true
            
            let imageFile = UIImageView(image: UIImage(systemName: "doc.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold, scale: .default)))
            containerViewFile.addSubview(imageFile)
            let nameFile = UILabel()
            containerViewFile.addSubview(nameFile)
            
            imageFile.translatesAutoresizingMaskIntoConstraints = false
            imageFile.leadingAnchor.constraint(equalTo: containerViewFile.leadingAnchor, constant: 5).isActive = true
            imageFile.trailingAnchor.constraint(equalTo: nameFile.leadingAnchor, constant: -5).isActive = true
            imageFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
            imageFile.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageFile.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageFile.tintColor = .docColor
            
            nameFile.translatesAutoresizingMaskIntoConstraints = false
            nameFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
            nameFile.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
            nameFile.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            nameFile.textColor = .white
            nameFile.text = textChat?.components(separatedBy: "|")[0]
            
            if (dataMessages[indexPath.row]["progress"] as! Double != 100.0) {
                let containerLoading = UIView()
                containerViewFile.addSubview(containerLoading)
                containerLoading.translatesAutoresizingMaskIntoConstraints = false
                containerLoading.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
                containerLoading.leadingAnchor.constraint(equalTo: nameFile.trailingAnchor, constant: 5).isActive = true
                containerLoading.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
                containerLoading.widthAnchor.constraint(equalToConstant: 30).isActive = true
                containerLoading.heightAnchor.constraint(equalToConstant: 30).isActive = true
                let circlePath = UIBezierPath(arcCenter: CGPoint(x: 15, y: 15), radius: 10, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                let trackShape = CAShapeLayer()
                trackShape.path = circlePath.cgPath
                trackShape.fillColor = UIColor.clear.cgColor
                trackShape.lineWidth = 5
                trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                containerLoading.layer.addSublayer(trackShape)
                let shapeLoading = CAShapeLayer()
                shapeLoading.path = circlePath.cgPath
                shapeLoading.fillColor = UIColor.clear.cgColor
                shapeLoading.lineWidth = 3
                shapeLoading.strokeEnd = 0
                shapeLoading.strokeColor = UIColor.secondaryColor.cgColor
                containerLoading.layer.addSublayer(shapeLoading)
                var imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                if dataMessages[indexPath.row]["f_pin"] as? String != idMe {
                    imageupload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                }
                imageupload.tintColor = .white
                containerLoading.addSubview(imageupload)
                imageupload.translatesAutoresizingMaskIntoConstraints = false
                imageupload.centerYAnchor.constraint(equalTo: containerLoading.centerYAnchor).isActive = true
                imageupload.centerXAnchor.constraint(equalTo: containerLoading.centerXAnchor).isActive = true
            } else {
                nameFile.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
            }
            
            if !copySession && !forwardSession && !deleteSession {
                let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                containerViewFile.addGestureRecognizer(objectTap)
                objectTap.containerFile = containerViewFile
                objectTap.labelFile = nameFile
                objectTap.file_id = fileChat
                objectTap.indexPath = indexPath
            }
        }
        
        if (reffChat != "") {
            let data = queryMessageReply(message_id: reffChat)
            if data.count != 0 {
                topMarginText.constant = topMarginText.constant + 55
                
                let containerReply = UIView()
                containerMessage.addSubview(containerReply)
                containerReply.translatesAutoresizingMaskIntoConstraints = false
                containerReply.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                containerReply.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
                if thumbChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: imageThumb.topAnchor, constant: -5).isActive = true
                } else if fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: containerViewFile.topAnchor, constant: -5).isActive = true
                } else if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
                } else {
                    containerReply.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                }
                containerReply.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                containerReply.heightAnchor.constraint(equalToConstant: 50).isActive = true
                containerReply.backgroundColor = .black.withAlphaComponent(0.2)
                containerReply.layer.cornerRadius = 5
                containerReply.clipsToBounds = true
                
                let leftReply = UIView()
                containerReply.addSubview(leftReply)
                leftReply.translatesAutoresizingMaskIntoConstraints = false
                leftReply.leadingAnchor.constraint(equalTo: containerReply.leadingAnchor).isActive = true
                leftReply.topAnchor.constraint(equalTo: containerReply.topAnchor).isActive = true
                leftReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor).isActive = true
                leftReply.widthAnchor.constraint(equalToConstant: 3).isActive = true
                leftReply.layer.cornerRadius = 5
                leftReply.clipsToBounds = true
                leftReply.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
                
                let titleReply = UILabel()
                containerReply.addSubview(titleReply)
                titleReply.translatesAutoresizingMaskIntoConstraints = false
                titleReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                titleReply.topAnchor.constraint(equalTo: containerReply.topAnchor, constant: 10).isActive = true
                titleReply.trailingAnchor.constraint(lessThanOrEqualTo: containerReply.trailingAnchor, constant: -20).isActive = true
                titleReply.font = UIFont.systemFont(ofSize: 12).bold
                if (data["f_pin"] as? String == idMe) {
                    titleReply.text = "You".localized()
                    if dataMessages[indexPath.row]["f_pin"] as? String == idMe {
                        titleReply.textColor = .white
                        leftReply.backgroundColor = .white
                    } else {
                        titleReply.textColor = .mainColor
                        leftReply.backgroundColor = .mainColor
                    }
                } else {
                    if data["f_pin"] as? String != "-999" {
                        let dataProfile = getDataProfile(f_pin: data["f_pin"] as! String, message_id: data["message_id"] as! String)
                        titleReply.text = dataProfile["name"]
                    } else {
                        titleReply.text = "Bot"
                    }
                    if dataMessages[indexPath.row]["f_pin"] as? String == idMe {
                        titleReply.textColor = .white
                        leftReply.backgroundColor = .white
                    } else {
                        titleReply.textColor = .mainColor
                        leftReply.backgroundColor = .mainColor
                    }
                }
                
                let contentReply = UILabel()
                containerReply.addSubview(contentReply)
                contentReply.translatesAutoresizingMaskIntoConstraints = false
                contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                contentReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor, constant: -10).isActive = true
                contentReply.font = UIFont.systemFont(ofSize: 10)
                let message_text = data["message_text"] as! String
                let attachment_flag = data["attachment_flag"] as! String
                let thumb_chat = data["thumb_id"] as! String
                let image_chat = data["image_id"] as! String
                let video_chat = data["video_id"] as! String
                let file_chat = data["file_id"] as! String
                if (attachment_flag == "0" && thumb_chat == "") {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.attributedText = message_text.richText()
                } else if (attachment_flag == "1" || image_chat != "") {
                    if (message_text == "") {
                        contentReply.text = "📷 Photo".localized()
                    } else {
                        contentReply.attributedText = message_text.richText()
                    }
                } else if (attachment_flag == "2" || video_chat != "") {
                    if (message_text == "") {
                        contentReply.text = "📹 Video".localized()
                    } else {
                        contentReply.attributedText = message_text.richText()
                    }
                } else if (attachment_flag == "6" || file_chat != ""){
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
                } else if (attachment_flag == "11") {
                    contentReply.text = "❤️ Sticker"
                } else if attachment_flag == "27" {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 " + "Live Streaming".localized()
                } else if attachment_flag == "26" {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 " + "Seminar".localized()
                }
                contentReply.textColor = .white.withAlphaComponent(0.8)
                
                if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
                        let image    = UIImage(contentsOfFile: thumbURL.path)
                        let imageThumb = UIImageView(image: image)
                        containerReply.addSubview(imageThumb)
                        imageThumb.layer.cornerRadius = 2.0
                        imageThumb.clipsToBounds = true
                        imageThumb.contentMode = .scaleAspectFill
                        imageThumb.translatesAutoresizingMaskIntoConstraints = false
                        imageThumb.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10).isActive = true
                        imageThumb.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor).isActive = true
                        imageThumb.widthAnchor.constraint(equalToConstant: 30).isActive = true
                        imageThumb.heightAnchor.constraint(equalToConstant: 30).isActive = true
                        
                        if (attachment_flag == "2") {
                            let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                            imageThumb.addSubview(imagePlay)
                            imagePlay.clipsToBounds = true
                            imagePlay.translatesAutoresizingMaskIntoConstraints = false
                            imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                            imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                            imagePlay.widthAnchor.constraint(equalToConstant: 10).isActive = true
                            imagePlay.heightAnchor.constraint(equalToConstant: 10).isActive = true
                            imagePlay.tintColor = .white
                        }
                        titleReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -20).isActive = true
                        contentReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -20).isActive = true
                    }
                }
                if (attachment_flag == "11") {
                    let imageSticker = UIImageView(image: UIImage(named: (message_text.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
                    containerReply.addSubview(imageSticker)
                    imageSticker.layer.cornerRadius = 2.0
                    imageSticker.clipsToBounds = true
                    imageSticker.translatesAutoresizingMaskIntoConstraints = false
                    imageSticker.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10).isActive = true
                    imageSticker.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor).isActive = true
                    imageSticker.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    imageSticker.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    titleReply.trailingAnchor.constraint(equalTo: imageSticker.leadingAnchor, constant: -20).isActive = true
                    contentReply.trailingAnchor.constraint(equalTo: imageSticker.leadingAnchor, constant: -20).isActive = true
                }
                
                if !copySession && !forwardSession && !deleteSession {
                    let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                    containerReply.addGestureRecognizer(objectTap)
                    objectTap.indexPath = indexPath
                    objectTap.message_id = data["message_id"] as! String
                }
            }
        }
        
        return cellMessage
    }
    
    @objc func contentMessageTapped(_ sender: ObjectGesture) {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if (sender.image_id != "") {
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.image_id)
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                    previewImageVC.image = image
                    previewImageVC.isHiddenTextField = true
                    previewImageVC.modalPresentationStyle = .custom
                    previewImageVC.modalTransitionStyle  = .crossDissolve
                    self.present(previewImageVC, animated: true, completion: nil)
                } else {
                    for view in sender.imageView.subviews {
                        if view is UIImageView {
                            view.removeFromSuperview()
                        }
                    }
                    let activityIndicator = UIActivityIndicatorView(style: .large)
                    activityIndicator.color = .mainColor
                    activityIndicator.hidesWhenStopped = true
                    activityIndicator.center = CGPoint(x:sender.imageView.frame.width/2,
                                                       y: sender.imageView.frame.height/2)
                    activityIndicator.startAnimating()
                    sender.imageView.addSubview(activityIndicator)
                    Download().start(forKey: sender.image_id) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        
                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.image_id)
                        let image    = UIImage(contentsOfFile: imageURL.path)
                        let save = UserDefaults.standard.bool(forKey: "saveToGallery")
                        if save {
                            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                        }
                        
                        DispatchQueue.main.async {
                            activityIndicator.stopAnimating()
                            self.tableChatView.reloadRows(at: [sender.indexPath], with: .none)
                        }
                    }
                }
            }
        } else if (sender.video_id != "") {
            if let dirPath = paths.first {
                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.video_id)
                if FileManager.default.fileExists(atPath: videoURL.path) {
                    let player = AVPlayer(url: videoURL as URL)
                    let playerVC = AVPlayerViewController()
                    playerVC.modalPresentationStyle = .custom
                    playerVC.player = player
                    self.present(playerVC, animated: true, completion: nil)
                } else {
                    for view in sender.imageView.subviews {
                        if view is UIImageView {
                            view.removeFromSuperview()
                        }
                    }
                    let container = UIView()
                    sender.imageView.addSubview(container)
                    container.translatesAutoresizingMaskIntoConstraints = false
                    container.centerXAnchor.constraint(equalTo: sender.imageView.centerXAnchor).isActive = true
                    container.centerYAnchor.constraint(equalTo: sender.imageView.centerYAnchor).isActive = true
                    container.widthAnchor.constraint(equalToConstant: 50).isActive = true
                    container.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 25, y: 25), radius: 20, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.clear.cgColor
                    trackShape.lineWidth = 10
                    trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                    container.backgroundColor = .clear
                    container.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 10
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                    container.layer.addSublayer(shapeLoading)
                    let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageDownload.tintColor = .white
                    container.addSubview(imageDownload)
                    imageDownload.translatesAutoresizingMaskIntoConstraints = false
                    imageDownload.centerXAnchor.constraint(equalTo: sender.imageView.centerXAnchor).isActive = true
                    imageDownload.centerYAnchor.constraint(equalTo: sender.imageView.centerYAnchor).isActive = true
                    imageDownload.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    imageDownload.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    Download().start(forKey: sender.video_id) { (name, progress) in
                        DispatchQueue.main.async {
                            guard progress == 100 else {
                                shapeLoading.strokeEnd = CGFloat(progress / 100)
                                return
                            }
                            let save = UserDefaults.standard.bool(forKey: "saveToGallery")
                            if save {
                                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.video_id)
                                PHPhotoLibrary.shared().performChanges({
                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                                }) { saved, error in
                                    
                                }
                            }
                            let idx = self.dataMessages.firstIndex(where: { $0["video_id"] as! String == sender.video_id})
                            if idx != nil {
                                self.dataMessages[idx!]["progress"] = progress
                                self.tableChatView.reloadRows(at: [sender.indexPath], with: .none)
                            }
                        }
                    }
                }
            }
        } else if (sender.file_id != "") {
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.file_id)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    self.previewItem = fileURL as NSURL
                    let previewController = QLPreviewController()
                    let rightBarButton = UIBarButtonItem()
                    previewController.navigationItem.rightBarButtonItem = rightBarButton
                    previewController.dataSource = self
                    previewController.modalPresentationStyle = .custom
                    
                    self.show(previewController, sender: nil)
                } else {
                    for view in sender.containerFile.subviews {
                        if !(view is UIImageView) && !(view is UILabel) {
                            view.removeFromSuperview()
                        }
                    }
                    let containerLoading = UIView()
                    sender.containerFile.addSubview(containerLoading)
                    containerLoading.translatesAutoresizingMaskIntoConstraints = false
                    containerLoading.centerYAnchor.constraint(equalTo: sender.containerFile.centerYAnchor).isActive = true
                    containerLoading.leadingAnchor.constraint(equalTo: sender.labelFile.trailingAnchor, constant: 5).isActive = true
                    containerLoading.trailingAnchor.constraint(equalTo: sender.containerFile.trailingAnchor, constant: -5).isActive = true
                    containerLoading.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    containerLoading.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 15, y: 15), radius: 10, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.clear.cgColor
                    trackShape.lineWidth = 5
                    trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                    containerLoading.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 3
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                    containerLoading.layer.addSublayer(shapeLoading)
                    let imageupload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageupload.tintColor = .white
                    containerLoading.addSubview(imageupload)
                    imageupload.translatesAutoresizingMaskIntoConstraints = false
                    imageupload.centerYAnchor.constraint(equalTo: containerLoading.centerYAnchor).isActive = true
                    imageupload.centerXAnchor.constraint(equalTo: containerLoading.centerXAnchor).isActive = true
                    
                    Download().start(forKey: sender.file_id) { (name, progress) in
                        DispatchQueue.main.async {
                            guard progress == 100 else {
                                shapeLoading.strokeEnd = CGFloat(progress / 100)
                                return
                            }
                            let idx = self.dataMessages.firstIndex(where: { $0["file_id"] as! String == sender.file_id})
                            if idx != nil {
                                self.dataMessages[idx!]["progress"] = progress
                                self.tableChatView.reloadRows(at: [sender.indexPath], with: .none)
                            }
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == sender.message_id})
                if idx == nil {
                    return
                }
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[idx!]["message_id"] as! String})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        let containerMessage = cell.contentView.subviews[1]
                        let idMe = UserDefaults.standard.string(forKey: "me") as String?
                        if (self.dataMessages[idx!]["f_pin"] as? String == idMe) {
                            containerMessage.backgroundColor = .blueBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (self.dataMessages[idx!]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .blueBubbleColor
                                }
                            }
                        } else {
                            containerMessage.backgroundColor = .grayColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (self.dataMessages[idx!]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .grayColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    @objc func tapMessageText(_ sender: ObjectGesture) {
        var stringURl = sender.message_id.lowercased()
        if stringURl.starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        guard let url = URL(string: stringURl) else { return }
        UIApplication.shared.open(url)
    }
}
