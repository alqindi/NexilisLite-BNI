//
//  BroadcastViewController.swift
//  Qmera
//
//  Created by Kevin Maulana on 27/09/21.
//

import UIKit
import AVKit
import AVFoundation
import FMDB

class BroadcastViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate, ImageVideoPickerDelegate, DocumentPickerDelegate {

    @IBOutlet weak var targetAudienceLabel: UILabel!
    @IBOutlet weak var broadcastTypeLabel: UILabel!
    @IBOutlet weak var broadcastModeLabel: UILabel!
    @IBOutlet weak var broadcastVariantLabel: UILabel!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var endTimeCell: UITableViewCell!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var documentPreview: UIView!
    @IBOutlet weak var clearAttachButton: UIButton!
    @IBOutlet weak var documentLabel: UILabel!
    @IBOutlet weak var addMemberButton: UIButton!
    @IBOutlet weak var memberTable: UITableView!
    @IBOutlet weak var memberSection: UITableViewCell!
    @IBOutlet weak var memberListLabel: UILabel!
    let placeholder = "Message"
    
    static let FLAG_NEW_POST = "0"
    static let FLAG_EDIT_POST = "1"

    static let FILE_TYPE_CHAT = "0"
    static let FILE_TYPE_IMAGE = "1"
    static let FILE_TYPE_VIDEO = "2"
    static let FILE_TYPE_DOCUMENT = "3"
    
    static let DESTINATION_CUSTOMER = "1"
    static let DESTINATION_TEAM_MEMBER = "2"
    static let DESTINATION_ALL = "3"
    static let DESTINATION_GROUP = "4"
    static let DESTINATION_SPESIFIC = "5"
    static let DESTINATION_MEMBER_MERCHANT = "6"
    
    static let TYPE_PUSH_NOTIFICATION = "1"
    static let TYPE_IN_APP = "2"
    
    static let MODE_ONCE = "1"
    static let MODE_DAILY = "2"
    static let MODE_WEEKLY = "3"
    static let MODE_MONTHLY = "4"
    
    static let FORM_NOT_FORM = "-99"
    
    var fileType = FILE_TYPE_CHAT
    var dest = DESTINATION_CUSTOMER
    var type = TYPE_PUSH_NOTIFICATION
    var mode = MODE_ONCE
    var membersInvited = ""
    var thumbId = ""
    var fileId = ""
    var form = FORM_NOT_FORM
    var link = ""
    var messageTitle = ""
    var message = ""
    
    var imageVideoPicker : ImageVideoPicker!
    var documentPicker : DocumentPicker!
    var imageVideoData : [UIImagePickerController.InfoKey: Any]?
    var previewItem : URL?
    
    var contacts: [User] = []
    
    var groups: [Group] = []
    
    var forms: [Form] = []
    
    var loadingView = UIViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global().async {
            let me = UserDefaults.standard.string(forKey: "me")!
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getFormList(p_pin: me, p_last_id: "0"))
        }
        
        titleTextField.delegate = self
        messageTextView.delegate = self
        linkTextField.delegate = self
        messageTextView.delegate = self
        messageTextView.text = placeholder
        messageTextView.textColor = .opaqueSeparator
        targetAudienceLabel.text = "Customer".localized()
        broadcastTypeLabel.text = "Notification".localized()
        broadcastModeLabel.text = "One Time".localized()
        broadcastVariantLabel.text = "Message".localized()
        endTimeCell.isHidden = true
        imageVideoPicker = ImageVideoPicker(presentationController: self, delegate: self)
        documentPicker = DocumentPicker(presentationController: self, delegate: self)
        memberTable.dataSource = self
        memberTable.delegate = self
        
        let query = "select f.id, f.form_id, f.name, f.created_date, f.created_by, f.sq_no from FORM f"
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) {
                while cursor.next() {
                    var form = Form()
                    form.id = cursor.long(forColumnIndex: 0)
                    form.formId = cursor.string(forColumnIndex: 1)!
                    form.title = cursor.string(forColumnIndex: 2)!
                    form.createdDate = Int(cursor.string(forColumnIndex: 3)!)!
                    form.createdBy = cursor.string(forColumnIndex: 4)!
                    form.sqNo = Int(cursor.int(forColumnIndex: 5))
                    forms.append(form)
                }
            }
        })
        // Do any additional setup after loading the view.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if(textView.text == placeholder){
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        if (textView.text == "")
        {
            textView.text = placeholder
            textView.textColor = .opaqueSeparator
        }
        textView.resignFirstResponder()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "br_audience" {
            let destination = segue.destination as! AudienceViewController
            destination.isBroadcast = true
            destination.selected = targetAudienceLabel.text
            
        } else if segue.identifier == "br_type" {
            let destination = segue.destination as! TypeViewController
            destination.selected = broadcastTypeLabel.text
        } else if segue.identifier == "br_mode" {
            let destination = segue.destination as! BroadcastModeViewController
            destination.selected = broadcastModeLabel.text
        } else if segue.identifier == "br_variant" {
            let destination = segue.destination as! BroadcastVariantViewController
            destination.selected = broadcastVariantLabel.text
            destination.data = forms
        } else if segue.identifier == "br_member" {
            let destination = segue.destination as! BroadcastMembersTableViewController
            let isGroup = dest == BroadcastViewController.DESTINATION_GROUP
            destination.isGroup = isGroup
            if(isGroup){
                for g in groups{
                    destination.existing.append(g.id)
                }
            }
            else {
                for c in contacts {
                    destination.existing.append(c.pin)
                }
            }
        }
    }
    
    @IBAction func didTapCancel(sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func selectImage(_ sender: Any) {
        imageVideoPicker.present(source: .imageAlbum)
    }
    
    @IBAction func selectVideo(_ sender: Any) {
        imageVideoPicker.present(source: .videoAlbum)
    }
    
    @IBAction func selectDocument(_ sender: Any) {
        documentPicker.present()
    }
    
    func didSelect(imagevideo: Any?) {
        if (imagevideo != nil) {
            imageVideoData = imagevideo as? [UIImagePickerController.InfoKey: Any]
            if (imageVideoData![.mediaType] as! String == "public.movie") {
                do {
                    let url = imageVideoData![.mediaURL] as! URL
                    let asset = AVURLAsset(url: url, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
                    let thumbnail = UIImage(cgImage: cgImage)
                    imagePreview.image = thumbnail
                    self.fileType = BroadcastViewController.FILE_TYPE_VIDEO
                } catch let error {
                    print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            } else {
                let url = imageVideoData![.imageURL] as! URL
                print("url: \(url.lastPathComponent)")
                imagePreview.image = imageVideoData![.originalImage] as? UIImage
                self.fileType = BroadcastViewController.FILE_TYPE_IMAGE
            }
            imagePreview.isHidden = false
            documentPreview.isHidden = true
            clearAttachButton.isHidden = false
            
        }
    }
    
    func didSelectDocument(document: Any?) {
        if (document != nil) {
            previewItem = (document as! [URL])[0] as URL
            fileType = BroadcastViewController.FILE_TYPE_DOCUMENT
            fileId = previewItem?.lastPathComponent ?? ""
            documentLabel.text = fileId
            imagePreview.isHidden = true
            documentPreview.isHidden = false
            clearAttachButton.isHidden = false
        }
    }
    
    func uploadAttachment(){
        
    }
    
    @IBAction func addMembers(_ sender: Any) {
        
    }
    @IBAction func clearAttach(_ sender: Any) {
        clearAttachment()
    }
    
    func clearAttachment(){
        fileType = BroadcastViewController.FILE_TYPE_CHAT
        thumbId = ""
        fileId = ""
        documentLabel.text = ""
        imagePreview.isHidden = true
        documentPreview.isHidden = true
        clearAttachButton.isHidden = true
        imageVideoData = nil
        previewItem = nil
    }
    
    func showActivityIndicatory() {
        loadingView.view.backgroundColor = .black.withAlphaComponent(0.3)
        let activityView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityView.center = self.view.center
        loadingView.view.addSubview(activityView)
        activityView.startAnimating()
        loadingView.modalPresentationStyle = .custom
        loadingView.modalTransitionStyle = .crossDissolve
        self.present(loadingView, animated: true)
    }
    
    @IBAction func submitBroadcast(_ sender: Any) {
        let startTime = startTimePicker.date.millisecondsSince1970
        var endTime = startTime
        if(!endTimeCell.isHidden){
            endTime = endTimePicker.date.millisecondsSince1970
        }
        if(startTime > endTime){
            return
        }
        messageTitle = titleTextField.text!
        message = messageTextView.text
        link = linkTextField.text!
        dest = "\(targetAudienceLabel.tag + 1)"
        type = "\(broadcastTypeLabel.tag + 1)"
        mode = "\(broadcastModeLabel.tag + 1)"
        if(messageTitle.trimmingCharacters(in: .whitespaces).isEmpty || message.trimmingCharacters(in: .whitespaces).isEmpty){
            let alert = UIAlertController(title: "", message: "Title and message must not be empty".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        if(dest == BroadcastViewController.DESTINATION_GROUP){
            if(groups.isEmpty){
                let alert = UIAlertController(title: "", message: "Please select at least one contact".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            var gs = [String]()
            for g in groups {
                gs.append(g.id)
            }
            let jsonData = try! JSONSerialization.data(withJSONObject: gs, options: [])
            membersInvited = String(data: jsonData, encoding: .utf8) ?? ""
        }
        else if(dest == BroadcastViewController.DESTINATION_SPESIFIC){
            if(contacts.isEmpty){
                let alert = UIAlertController(title: "", message: "Please select at least one contact".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            var cs = [String]()
            for c in contacts {
                cs.append(c.pin)
            }
            let jsonData = try! JSONSerialization.data(withJSONObject: cs, options: [])
            membersInvited = String(data: jsonData, encoding: .utf8) ?? ""
        }
        print("dest: \(dest)")
        print("type: \(type)")
        print("mode: \(mode)")
        print("fileType: \(fileType)")
        print("thumb_id: \(thumbId)")
        print("file_id: \(fileId)")
        print("members: \(membersInvited)")
        showActivityIndicatory()
        if(form == BroadcastViewController.FORM_NOT_FORM){
            if(fileType == BroadcastViewController.FILE_TYPE_IMAGE){
                saveImage()
            }
            else if(fileType == BroadcastViewController.FILE_TYPE_VIDEO){
                saveVideo()
            }
            else if(fileType == BroadcastViewController.FILE_TYPE_DOCUMENT){
                saveDocument()
            }
        }
        else {
            clearAttachment()
        }
        if !thumbId.isEmpty {
            Network().upload(name: String(thumbId)) { (result1, progress) in
                if result1 {
                    if progress == 100 {
                        Network().upload(name: String(self.fileId)) { (result2, progress) in
                            if result2 {
                                if progress == 100 {
                                    self.sendMsg(startTime: startTime, endTime: endTime)
                                }
                            }
                        }
                    }
                }
            }
        } else if !fileId.isEmpty {
            Network().upload(name: String(fileId)) { (result2, progress) in
                if result2 {
                    if progress == 100 {
                        self.sendMsg(startTime: startTime, endTime: endTime)
                    }
                }
            }
        } else {
            sendMsg(startTime: startTime, endTime: endTime)
        }
    }
    
    func saveImage(){
        var originalImageName = ""
        if (imageVideoData![.imageURL] == nil) {
            originalImageName = "\(Date().millisecondsSince1970)_takeImage"
        } else {
            let urlImage = (imageVideoData![.imageURL] as! NSURL).absoluteString
            originalImageName = (urlImage! as NSString).lastPathComponent
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let compressedImageName = "THUMB-Qmera_image_\(originalImageName)"
        let thumbName = "THUMB_Qmera_image_\(originalImageName)"
        let fileURL = documentsDirectory.appendingPathComponent(compressedImageName)
        let compressedImage = (imageVideoData![.originalImage] as! UIImage).jpegData(compressionQuality:  1.0)
        if let data = compressedImage,
           !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try data.write(to: fileURL)
                print("file saved")
            } catch {
                print("error saving file:", error)
            }
        }
        let thumbImage = UIImage(data: compressedImage!)
        let fileURLTHUMB = documentsDirectory.appendingPathComponent(thumbName)
        if let dataThumb = thumbImage!.jpegData(compressionQuality:  0.25),
           !FileManager.default.fileExists(atPath: fileURLTHUMB.path) {
            do {
                try dataThumb.write(to: fileURLTHUMB)
                print("thumb saved")
            } catch {
                print("error saving file:", error)
            }
        }
        fileId = compressedImageName
        thumbId = thumbName
    }
    
    func saveVideo(){
        guard var dataVideo = try? Data(contentsOf: imageVideoData![.mediaURL] as! URL) else {
            return
        }
        let sizeOfVideo = Double(dataVideo.count / 1048576)
        if (sizeOfVideo > 10.0) {
            let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
            compressVideo(inputURL: imageVideoData![.mediaURL] as! URL,
                          outputURL: compressedURL) { exportSession in
                guard let session = exportSession else {
                    return
                }
                
                switch session.status {
                case .unknown:
                    break
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    guard let compressedData = try? Data(contentsOf: compressedURL) else {
                        return
                    }
                    dataVideo = compressedData
                case .failed:
                    break
                case .cancelled:
                    break
                @unknown default:
                    break
                }
            }
        }
        let urlVideo = (imageVideoData![.mediaURL] as! NSURL).absoluteString
        let originalVideoName = (urlVideo! as NSString).lastPathComponent
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let renamedVideoName = "Qmera_video_\(originalVideoName)"
        let thumbName = "THUMB_Qmera_video_\(originalVideoName)"
        let fileURL = documentsDirectory.appendingPathComponent(renamedVideoName)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try dataVideo.write(to: fileURL)
                print("file saved")
            } catch {
                print("error saving file:", error)
            }
        }
        let dataThumbVideo = imagePreview.image!.jpegData(compressionQuality:  1.0)
        let fileURLTHUMB = documentsDirectory.appendingPathComponent(thumbName)
        if !FileManager.default.fileExists(atPath: fileURLTHUMB.path) {
            do {
                try dataThumbVideo!.write(to: fileURLTHUMB)
                print("thumb saved")
            } catch {
                print("error saving file:", error)
            }
        }
        fileId = renamedVideoName
        thumbId = thumbName
    }
    
    func saveDocument(){
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
            fileId = renamedNameFile
        } catch {
            
        }
    }
    
    func compressVideo(inputURL: URL,
                       outputURL: URL,
                       handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously {
            handler(exportSession)
        }
    }
    
    func sendMsg(startTime: Int64, endTime: Int64){
        let message = CoreMessage_TMessageBank.broadcastMessage(title: messageTitle, broadcast_flag: mode, message: message, starting_date: startTime, ending_date: startTime, destination: dest, data: membersInvited, category_flag: fileType, notification_type: type, link: link, thumb_id: thumbId, file_id: fileId)
        if(form != BroadcastViewController.FORM_NOT_FORM){
            message.mBodies[CoreMessage_TMessageKey.FILE_ID] = form
            message.mBodies[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] = "18"
        }
        if let response = Nexilis.writeSync(message: message) {
            if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                DispatchQueue.main.async {
                    self.navigationController?.presentingViewController?.dismiss(animated: true)
                }
            } else {
                self.loadingView.dismiss(animated: true)
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func result(unwind segue: UIStoryboardSegue) {
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == memberTable){
            let mcell = tableView.dequeueReusableCell(withIdentifier: "memberCell", for: indexPath) as! BroadcastMembersTableViewCell
            if(dest == BroadcastViewController.DESTINATION_SPESIFIC){
                
                var content = mcell.defaultContentConfiguration()
                let data: User
                data = contacts[indexPath.row]
                content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                getImage(name: data.thumb, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                    content.image = image
                })
                if (data.official == "1") {
                    content.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4)
                }
                else if data.userType == "23" {
                    content.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4)
                } else if data.userType == "24" {
                    content.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4)
                }
                else {
                    content.text = data.fullName
                }
                content.textProperties.font = UIFont.systemFont(ofSize: 14)
                mcell.contentConfiguration = content
                
            }
            else if(dest == BroadcastViewController.DESTINATION_GROUP){
                var content = mcell.defaultContentConfiguration()
                let group: Group
                group = groups[indexPath.row]
                content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                getImage(name: group.profile, placeholderImage: UIImage(named: "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                    content.image = image
//                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                content.text = group.name
                content.textProperties.font = UIFont.systemFont(ofSize: 14)
                mcell.contentConfiguration = content
            }
            return mcell
        }
        else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == memberTable){
            deleteMember(index: indexPath.item)
        }
    }
    
    func deleteMember(index: Int){
        if(dest == BroadcastViewController.DESTINATION_SPESIFIC){
            contacts.remove(at: index)
        }
        else{
            groups.remove(at: index)
        }
        memberTable.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == memberTable){
            if(dest == BroadcastViewController.DESTINATION_SPESIFIC){
                return contacts.count
            }
            else if(dest == BroadcastViewController.DESTINATION_GROUP){
                return groups.count
            }
            else {
                return 0
            }
        }
        else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
            if(tableView == memberTable){
                return 1
            }
            else {
                return super.numberOfSections(in: tableView)
            }
        }
    
    func set(image: UIImage, with text: String, size: CGFloat, y: CGFloat) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: y, width: size, height: size)
        let attachmentStr = NSAttributedString(attachment: attachment)
        
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(attachmentStr)
        
        let textString = NSAttributedString(string: text)
        mutableAttributedString.append(textString)
        
        return mutableAttributedString
    }

}

struct Form {
    var id = 0
    var formId = "0"
    var title = ""
    var createdDate = 0
    var createdBy = ""
    var sqNo = 0
}
