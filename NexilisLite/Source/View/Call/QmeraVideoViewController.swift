//
//  VideoViewControllerQmera.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 07/10/21.
//

// Rn
// (Kedip whiteboard)
// extension Whiteboard
// wbVC!.close wbTimer wbBlink

import UIKit
import nuSDKService
import AVFoundation
import NotificationBannerSwift

class QmeraVideoViewController: UIViewController {
    var dataPerson: [[String: String?]] = []
    var fPin = ""
    var wbRoomId = ""
    var isInisiator = true
    var isSpeaker = false
    var listRemoteViewFix: [UIImageView] = [
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView()
    ]
    var containerLabelName: [UIView] = [
        UIView(),
        UIView(),
        UIView(),
        UIView(),
        UIView()
    ]
    let myImage = UIImageView()
    let name = UILabel()
    let profileImage = UIImageView()
    let labelIncomingOutgoing = UILabel()
    let buttonDecline = UIButton()
    let buttonAccept = UIButton()
    let zoomView = UIImageView()
    let cameraView = UIImageView()
    var constraintLeadingButtonDecline = NSLayoutConstraint()
    var constraintBottomButtonDecline = NSLayoutConstraint()
    var constraintBottomStackViewToolbar = NSLayoutConstraint()
    var constraintLeftStackViewToolbar2 = NSLayoutConstraint()
    let stackViewToolbar = UIStackView()
    let stackViewToolbar2 = UIStackView()
    var onScreenConstraintWB = [NSLayoutConstraint]()
    let buttonWB = UIButton()
    var wbVC : WhiteboardViewController?
    let buttonAddParticipant = UIButton()
    let buttonSpeaker = UIButton()
    var showStackViewToolbar = true
    let scrollRemoteView = UIScrollView()
    var isAutoAccept = false
    var wbTimer = Timer()
    var wbBlink = false
    var showNotifCCEnd = false
    var transformZoomAfterNewUserMore2 = false
    var isAddCall = ""
    var users: [User] = []
    let poweredByView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 5
        return stackView
    }()
    
    let poweredByLabel: UILabel = {
        let label = UILabel()
        label.text = "Powered by Nexilis"
        return label
    }()
    
    let qmeraLogo: UIButton = {
        let image = UIImage(named: "Q-Button-PNG", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.frame.size.width = 30
        button.frame.size.height = 30
        return button
    }()
    
    let nexilisLogo: UIButton = {
        let image = UIImage(named: "pb_powered", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.frame.size.width = 30
        button.frame.size.height = 30
        return button
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
            navigationController?.navigationBar.shadowImage = nil
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.view.backgroundColor = .mainColor
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController?.navigationBar.titleTextAttributes = textAttributes
            navigationController?.navigationBar.topItem?.backBarButtonItem = nil
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            NotificationCenter.default.removeObserver(self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Nexilis.setWhiteboardReceiver(receiver: self)
        navigationController?.changeAppearance(clear: true)
        
        view.backgroundColor = .clear
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationItem.setHidesBackButton(true, animated: false)
        if fPin != ""{
            getDataProfile(fPin: fPin)
        }
        
        addZoomView()
        addCameraView()
        addListRemoteView()
        addBackgroundIncoming()
        addProfileNameCalling()
        Calling()
        addToolbar()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onStatusCall(_:)), name: NSNotification.Name(rawValue: "onStatusCall"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: "onReceiveChat"), object: nil)
        if isAutoAccept {
            didTapAcceptCallButton()
        }
        
    }
    
    func getDataProfile(fPin: String) {
        let query = "SELECT f_pin, first_name, last_name, official_account, image_id, device_id, offline_mode, user_type FROM BUDDY where f_pin = '\(fPin)'"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                var row: [String: String?] = [:]
                if cursorData.next() {
                    row["f_pin"] = cursorData.string(forColumnIndex: 0)
                    var name = ""
                    if let firstname = cursorData.string(forColumnIndex: 1) {
                        name = firstname
                    }
                    if let lastname = cursorData.string(forColumnIndex: 2) {
                        name = name + " " + lastname
                    }
                    row["name"] = name
                    row["picture"] = cursorData.string(forColumnIndex: 4)
                    row["isOfficial"] = cursorData.string(forColumnIndex: 3)
                    row["deviceId"] = cursorData.string(forColumnIndex: 5)
                    row["isOffline"] = cursorData.string(forColumnIndex: 6)
                    row["user_type"] = cursorData.string(forColumnIndex: 7)
                }
                dataPerson.append(row)
                cursorData.close()
            }
        })
    }
    
    func addZoomView() {
        view.addSubview(zoomView)
        zoomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomView.topAnchor.constraint(equalTo: view.topAnchor),
            zoomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            zoomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            zoomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        zoomView.backgroundColor = .secondaryColor
        zoomView.isUserInteractionEnabled = true
        zoomView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideToolbar)))
    }
    
    func addCameraView() {
        view.addSubview(cameraView)
//        cameraView.frame = CGRect(x: view.frame.width - 130, y: 20, width: 120, height: 160)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20.0),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10.0),
            cameraView.widthAnchor.constraint(equalToConstant: 120.0),
            cameraView.heightAnchor.constraint(equalToConstant: 160.0)
        ])
        cameraView.backgroundColor = .secondaryColor
        cameraView.makeRoundedView(radius: 8)
    }
    
    func addListRemoteView() {
        view.addSubview(scrollRemoteView)
        scrollRemoteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollRemoteView.topAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: 10),
            scrollRemoteView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            scrollRemoteView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollRemoteView.widthAnchor.constraint(equalToConstant: 120.0)
        ])
        
        scrollRemoteView.showsHorizontalScrollIndicator = false
        scrollRemoteView.showsVerticalScrollIndicator = false
        scrollRemoteView.contentSize.width = 120.0
        scrollRemoteView.backgroundColor = .clear
    }
    
    func addBackgroundIncoming() {
        view.addSubview(myImage)
        myImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            myImage.topAnchor.constraint(equalTo: view.topAnchor),
            myImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            myImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        myImage.backgroundColor = .lightGray
        myImage.tintColor = .secondaryColor
        let image = dataPerson[0]["picture"]!!
        if image.isEmpty {
            myImage.image = UIImage(systemName: "person")
            myImage.contentMode = .scaleAspectFit
        } else {
            myImage.setImage(name: image)
            myImage.contentMode = .scaleAspectFill
        }
//        let idMe = UserDefaults.standard.string(forKey: "me") as String?
//        Database().database?.inTransaction({ fmdb, rollback in
//            if let c = Database().getRecords(fmdb: fmdb, query: "select image_id from BUDDY where f_pin = '\(idMe!)'"), c.next() {
//                let image = c.string(forColumnIndex: 0)!
//                if image.isEmpty {
//                    myImage.image = UIImage(systemName: "person")
//                    myImage.contentMode = .scaleAspectFit
//                } else {
//                    myImage.setImage(name: image)
//                    myImage.contentMode = .scaleAspectFill
//                }
//                c.close()
//            }
//        })
    }
    
    func addProfileNameCalling() {
        view.addSubview(profileImage)
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.frame.size = CGSize(width: 60.0, height: 60.0)
        NSLayoutConstraint.activate([
            profileImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 40.0),
            profileImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImage.widthAnchor.constraint(equalToConstant: 60.0),
            profileImage.heightAnchor.constraint(equalToConstant: 63.0)
        ])
        profileImage.backgroundColor = .lightGray
        profileImage.tintColor = .secondaryColor
        profileImage.circle()
        let image = dataPerson[0]["picture"]!!
        if image.isEmpty {
            profileImage.image = UIImage(systemName: "person")
            profileImage.contentMode = .scaleAspectFit
            profileImage.layer.borderWidth = 1
            profileImage.layer.borderColor = UIColor.secondaryColor.cgColor
        } else {
            profileImage.setImage(name: image)
            profileImage.contentMode = .scaleAspectFill
        }
        
        view.addSubview(name)
        name.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 5.0),
            name.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        name.font = UIFont.systemFont(ofSize: 12)
        name.backgroundColor = .black.withAlphaComponent(0.05)
        name.layer.cornerRadius = 5.0
        name.clipsToBounds = true
        name.textColor = .mainColor
        name.text = dataPerson[0]["name"]!?.trimmingCharacters(in: .whitespaces)
    }
    
    func Calling() {
        view.addSubview(labelIncomingOutgoing)
        labelIncomingOutgoing.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelIncomingOutgoing.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 40.0),
            labelIncomingOutgoing.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        if isInisiator {
            labelIncomingOutgoing.text = "Outgoing video call".localized() + "..."
            API.initiateCCall(sParty: dataPerson[0]["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 2, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView)
        } else {
            let systemSoundID: SystemSoundID = 1254
            AudioServicesPlaySystemSound(systemSoundID)
            labelIncomingOutgoing.text = "Incoming video call".localized() + "..."
        }
        labelIncomingOutgoing.font = UIFont.systemFont(ofSize: 12)
        labelIncomingOutgoing.backgroundColor = .black.withAlphaComponent(0.05)
        labelIncomingOutgoing.layer.cornerRadius = 5.0
        labelIncomingOutgoing.clipsToBounds = true
        labelIncomingOutgoing.textColor = .mainColor
    }
    
    func addToolbar() {
        view.addSubview(buttonDecline)
        buttonDecline.translatesAutoresizingMaskIntoConstraints = false
        buttonDecline.frame.size = CGSize(width: 70.0, height: 70.0)
        if isInisiator {
            constraintLeadingButtonDecline = buttonDecline.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        } else {
            constraintLeadingButtonDecline = buttonDecline.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.frame.width * 0.2)
        }
        constraintBottomButtonDecline = buttonDecline.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60.0)
        NSLayoutConstraint.activate([
            constraintBottomButtonDecline,
            constraintLeadingButtonDecline,
            buttonDecline.widthAnchor.constraint(equalToConstant: 70.0),
            buttonDecline.heightAnchor.constraint(equalToConstant: 70.0)
        ])
        buttonDecline.backgroundColor = .red
        buttonDecline.circle()
        buttonDecline.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonDecline.tintColor = .white
        buttonDecline.addTarget(self, action: #selector(didTapDeclineCallButton(sender:)), for: .touchUpInside)
        
        if !isInisiator{
            view.addSubview(buttonAccept)
            buttonAccept.translatesAutoresizingMaskIntoConstraints = false
            buttonAccept.frame.size = CGSize(width: 70.0, height: 70.0)
            NSLayoutConstraint.activate([
                buttonAccept.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60.0),
                buttonAccept.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(view.frame.width * 0.2)),
                buttonAccept.widthAnchor.constraint(equalToConstant: 70.0),
                buttonAccept.heightAnchor.constraint(equalToConstant: 70.0)
            ])
            buttonAccept.backgroundColor = .greenColor
            buttonAccept.circle()
            buttonAccept.setImage(UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            buttonAccept.tintColor = .white
            buttonAccept.addTarget(self, action: #selector(didTapAcceptCallButton), for: .touchUpInside)
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                if (dataMessage.getCode() == CoreMessage_TMessageCode.PUSH_MEMBER_ROOM_CONTACT_CENTER) {
                    let data = dataMessage.getBody(key: CoreMessage_TMessageKey.DATA)
                    if !data.isEmpty {
                        if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                            var members = ""
                            let idMe = UserDefaults.standard.string(forKey: "me")!
                            for json in jsonArray {
                                if "\(json)" != idMe {
                                    if members.isEmpty {
                                        members = "\(json)"
                                    } else {
                                        members += ",\(json)"
                                    }
                                }
                            }
                            UserDefaults.standard.set("\(members)", forKey: "membersCC")
                        }
                    }
                    // Start Calling
                    if !self.isAddCall.isEmpty && self.isAddCall == dataMessage.getPIN(){
                        let user = User.getData(pin: dataMessage.getPIN())!
                        var dataPerson: [String: String?] = [:]
                        dataPerson["f_pin"] = user.pin
                        dataPerson["name"] = user.fullName
                        dataPerson["picture"] = user.thumb
                        dataPerson["isOfficial"] = user.official
                        dataPerson["deviceId"] = ""
                        dataPerson["isOffline"] = ""
                        dataPerson["user_type"] = user.userType
                        self.dataPerson.append(dataPerson)
                        self.users.append(user)
                        API.initiateCCall(sParty: dataMessage.getPIN(), nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: self.listRemoteViewFix, ivLocalView: self.cameraView, ivRemoteZ: self.zoomView)
                    }
                }
            }
        }
    }
    
    @objc func didTapDeclineCallButton(sender: AnyObject){
        let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
            let alert = UIAlertController(title: "Interaction with Call Center is in progress".localized(), message: "Are you sure you want to end the Call Center?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                if(!self.wbRoomId.isEmpty){
                    DispatchQueue.main.async {
                        self.wbTimer.invalidate()
                        _ = Nexilis.getWhiteboardDelegate()?.terminate()
                    }
                }
                self.endAllCall()
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            endAllCall()
            if isInisiator {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc func didTapAcceptCallButton(){
        API.receiveCCall(sParty: dataPerson[0]["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView,ivRemoteZ: zoomView)
        DispatchQueue.main.async {
            self.myImage.removeFromSuperview()
            self.name.removeFromSuperview()
            self.profileImage.removeFromSuperview()
            self.labelIncomingOutgoing.removeFromSuperview()
            self.buttonAccept.removeFromSuperview()
            NSLayoutConstraint.deactivate([
                self.constraintLeadingButtonDecline,
                self.constraintBottomButtonDecline
            ])
            self.addToolbarAfterAccept()
            self.buttonDecline.setImage(UIImage(systemName: "phone.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            UIView.animate(withDuration: 1.0, animations: {
                self.view.layoutIfNeeded()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.buttonAddParticipant.isHidden = false
                self.buttonSpeaker.isHidden = false
                self.buttonWB.isHidden = false
                self.poweredByView.isHidden = false
            }
        }
    }
    
    @objc func didTapWBButton(){
        if(wbVC == nil){
            wbVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "wbVC") as? WhiteboardViewController
            if(wbRoomId.isEmpty){
                let me = UserDefaults.standard.string(forKey: "me")!
                let tid = CoreMessage_TMessageUtil.getTID()
                wbRoomId = "\(me)\(tid)"
                wbVC!.roomId = wbRoomId
                var destinations = [String]()
                for d in dataPerson{
                    destinations.append(d["deviceId"]!!)
                }
                wbVC!.destinations = destinations
                wbVC!.sendInit()
            }
            else {
                wbVC!.roomId = wbRoomId
                wbVC!.sendJoin()
            }
        }
        wbVC!.close = {
            DispatchQueue.main.async {
                if self.wbVC!.view.isDescendant(of: self.view){
                    self.wbVC!.view.removeFromSuperview()
                }
                self.buttonDecline.isHidden = false
                self.buttonSpeaker.isHidden = false
                self.buttonAddParticipant.isHidden = false
                if(!self.wbRoomId.isEmpty){
                    DispatchQueue.main.async {
                        self.wbTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.runTimer), userInfo: nil, repeats: true)
                    }
                }
            }
        }
        self.buttonDecline.isHidden = true
        self.buttonSpeaker.isHidden = true
        self.buttonAddParticipant.isHidden = true
        addChild(wbVC!)
        wbVC!.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wbVC!.view)
        onScreenConstraintWB = [
            wbVC!.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            wbVC!.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            wbVC!.view.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            wbVC!.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
        ]
           NSLayoutConstraint.activate(onScreenConstraintWB)
             
           // Notify the child view controller that the move is complete.
           wbVC!.didMove(toParent: self)
//        self.navigationController?.setNavigationBarHidden(false, animated: true)
//        controller.modalPresentationStyle = .overCurrentContext
//        self.navigationController?.present(controller, animated: true)
    }
    
    func addToolbarAfterAccept() {
        self.view.addSubview(self.stackViewToolbar)
        self.stackViewToolbar.translatesAutoresizingMaskIntoConstraints = false
        constraintBottomStackViewToolbar = self.stackViewToolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -60.0)
        NSLayoutConstraint.activate([
            self.stackViewToolbar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            constraintBottomStackViewToolbar
        ])
        self.stackViewToolbar.axis = .horizontal
        self.stackViewToolbar.distribution = .equalSpacing
        self.stackViewToolbar.alignment = .center
        self.stackViewToolbar.spacing = 30
        
        view.addSubview(buttonAddParticipant)
        buttonAddParticipant.translatesAutoresizingMaskIntoConstraints = false
        buttonAddParticipant.frame.size = CGSize(width: 70.0, height: 70.0)
        NSLayoutConstraint.activate([
            buttonAddParticipant.widthAnchor.constraint(equalToConstant: 70.0),
            buttonAddParticipant.heightAnchor.constraint(equalToConstant: 70.0)
        ])
        buttonAddParticipant.backgroundColor = .secondaryColor
        buttonAddParticipant.setImage(UIImage(systemName: "person.badge.plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonAddParticipant.tintColor = .mainColor
        buttonAddParticipant.circle()
        buttonAddParticipant.isHidden = true
        buttonAddParticipant.addTarget(self, action: #selector(didTapAddParticipantButton(sender:)), for: .touchUpInside)
        
        view.addSubview(buttonSpeaker)
        buttonSpeaker.translatesAutoresizingMaskIntoConstraints = false
        buttonSpeaker.frame.size = CGSize(width: 70.0, height: 70.0)
        NSLayoutConstraint.activate([
            buttonSpeaker.widthAnchor.constraint(equalToConstant: 70.0),
            buttonSpeaker.heightAnchor.constraint(equalToConstant: 70.0)
        ])
        buttonSpeaker.backgroundColor = .secondaryColor
        buttonSpeaker.setImage(UIImage(systemName: "speaker.wave.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonSpeaker.tintColor = .mainColor
        buttonSpeaker.circle()
        buttonSpeaker.isHidden = true
        buttonSpeaker.addTarget(self, action: #selector(didTapSpeakerButton(sender:)), for: .touchUpInside)
        
        self.view.addSubview(self.stackViewToolbar2)
        self.stackViewToolbar2.translatesAutoresizingMaskIntoConstraints = false
        constraintLeftStackViewToolbar2 = self.stackViewToolbar2.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10.0)
        NSLayoutConstraint.activate([
            self.stackViewToolbar2.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            constraintLeftStackViewToolbar2
        ])
        self.stackViewToolbar2.axis = .vertical
        self.stackViewToolbar2.distribution = .equalSpacing
        self.stackViewToolbar2.alignment = .center
        self.stackViewToolbar2.spacing = 10
        
        view.addSubview(buttonWB)
        buttonWB.translatesAutoresizingMaskIntoConstraints = false
        buttonWB.frame.size = CGSize(width: 40.0, height: 40.0)
        NSLayoutConstraint.activate([
            buttonWB.widthAnchor.constraint(equalToConstant: 40.0),
            buttonWB.heightAnchor.constraint(equalToConstant: 40.0)
        ])
        buttonWB.backgroundColor = .lightGray
        buttonWB.setImage(UIImage(systemName: "ipad.landscape", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), for: .normal)
        buttonWB.circle()
        buttonWB.tintColor = .black
        buttonWB.isHidden = true
        buttonWB.addTarget(self, action: #selector(didTapWBButton), for: .touchUpInside)
        
        self.view.addSubview(poweredByView)
        self.poweredByView.translatesAutoresizingMaskIntoConstraints = false
        let constraintRightPowered =  self.poweredByView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10.0)
        let constraintBottomPowered = self.poweredByView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10.0)
        NSLayoutConstraint.activate([
            constraintRightPowered,
            constraintBottomPowered,
            poweredByView.heightAnchor.constraint(equalToConstant: 40.0),
            nexilisLogo.widthAnchor.constraint(equalToConstant: 30.0),
            nexilisLogo.heightAnchor.constraint(equalToConstant: 30.0)
        ])
        
        poweredByView.addArrangedSubview(poweredByLabel)
        poweredByView.addArrangedSubview(nexilisLogo)
        poweredByView.isHidden = true
        
        stackViewToolbar.addArrangedSubview(buttonAddParticipant)
        stackViewToolbar.addArrangedSubview(buttonDecline)
        stackViewToolbar.addArrangedSubview(buttonSpeaker)
        stackViewToolbar2.addArrangedSubview(buttonWB)
//        startFaceTimer()
    }
    
    func endAllCall() {
        let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
            let requester = onGoingCC.components(separatedBy: ",")[0]
            let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
            let complaintId = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2]
            let idMe = UserDefaults.standard.string(forKey: "me")!
            let startTimeCC = UserDefaults.standard.string(forKey: "startTimeCC") ?? ""
            DispatchQueue.global().async {
                let date = "\(Date().currentTimeMillis())"
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                            "type" : "2",
                            "title" : "Contact Center".localized(),
                            "time" : startTimeCC,
                            "f_pin" : officer,
                            "data" : complaintId,
                            "time_end" : date,
                            "complaint_id" : complaintId,
                            "members" : "",
                            "requester": requester
                        ], replace: true)
                    } catch {
                        rollback.pointee = true
                        print(error)
                    }
                })
                if officer == idMe {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: requester))
                } else {
                    if requester == idMe {
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: officer))
                    } else {
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.leaveCCRoomInvite(ticket_id: complaintId))
                    }
                }
                UserDefaults.standard.removeObject(forKey: "onGoingCC")
                UserDefaults.standard.removeObject(forKey: "membersCC")
                UserDefaults.standard.removeObject(forKey: "startTimeCC")
                UserDefaults.standard.removeObject(forKey: "waitingRequestCC")
            }
        }
        API.terminateCall(sParty: nil)
        cameraView.image = nil
        zoomView.image = nil
        listRemoteViewFix.removeAll()
    }
    
    func setSpeaker(isSpeaker: Bool) {
        DispatchQueue.main.async {
            if (isSpeaker) {
                self.buttonSpeaker.backgroundColor = .lightGray
                self.buttonSpeaker.tintColor = .mainColor
                self.buttonSpeaker.setImage(UIImage(systemName: "speaker.wave.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            } else {
                self.buttonSpeaker.backgroundColor = .secondaryColor
                self.buttonSpeaker.tintColor = .mainColor
                self.buttonSpeaker.setImage(UIImage(systemName: "speaker.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            }
            self.isSpeaker = isSpeaker
        }
//        do {
//            try AVAudioSession.sharedInstance().setCategory(isSpeaker ? .playAndRecord : .playAndRecord, options: isSpeaker ? .defaultToSpeaker : .duckOthers)
//            try AVAudioSession.sharedInstance().setMode(isSpeaker ? .videoChat : .videoChat)
//            try AVAudioSession.sharedInstance().overrideOutputAudioPort(isSpeaker ? .speaker : .none)
//        } catch {
//
//        }
    }
    
    @objc func didTapSpeakerButton(sender: AnyObject){
        setSpeaker(isSpeaker: !(self.isSpeaker))
    }
    
    @objc func didTapAddParticipantButton(sender: AnyObject){
        if let contactViewController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID") as? ContactCallViewController {
            contactViewController.isAddParticipantVideo = true
            contactViewController.connectedCall = dataPerson
            contactViewController.isDismiss = { data in
                let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
                if !onGoingCC.isEmpty {
                    DispatchQueue.global().async {
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getCCRoomInvite(l_pin: data["f_pin"]!!, ticket_id: onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2], channel: "2"))
                    }
                    DispatchQueue.main.async {
                        self.isAddCall = data["f_pin"]!!
                    }
                } else {
                    DispatchQueue.main.async {
                        self.dataPerson.append(data)
                        API.initiateCCall(sParty: data["f_pin"] as? String, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: self.listRemoteViewFix, ivLocalView: self.cameraView, ivRemoteZ: self.zoomView)
                    }
                }
            }
            present(UINavigationController(rootViewController: contactViewController), animated: true, completion: nil)
        }
    }
    
    @objc func hideToolbar() {
        DispatchQueue.main.async {
            if self.showStackViewToolbar {
                self.showStackViewToolbar = false
                self.constraintBottomStackViewToolbar.constant = 70
                UIView.animate(withDuration: 0.35, animations: {
                    self.view.layoutIfNeeded()
                })
            } else {
                self.showStackViewToolbar = true
                self.constraintBottomStackViewToolbar.constant = -60
                UIView.animate(withDuration: 0.35, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc func onStatusCall(_ notification: NSNotification) {
        let data = notification.userInfo
        let state = (data?["state"] ?? 0) as! Int
        let message = (data?["message"] ?? "") as! String
        var remoteChannel = [String:String]()
        let arrayMessage = message.split(separator: ",")
        if(state == 35){
            DispatchQueue.main.async {
                if self.dataPerson.count > 1 {
                    if !self.transformZoomAfterNewUserMore2 {
                        self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi * 3)/2)
                        self.transformZoomAfterNewUserMore2 = true
                    }
                }
            }
        }
        else if (state == 34){
            let channel = arrayMessage[arrayMessage.count - 1]
            if(remoteChannel[String(channel)] != "2"){
                DispatchQueue.main.async {
                    if(arrayMessage[arrayMessage.count - 2] == "0"){ // back camera
                        self.zoomView.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi)/2)
                    }
                    else { // front camera
                        self.zoomView.transform = CGAffineTransform.init(scaleX: -1.9, y: 1.9).rotated(by: (CGFloat.pi * 3)/2)
                    }
                }
            }
        }
        else if (state == 32) {
            let channel = arrayMessage[3]
            remoteChannel[String(channel)] = String(arrayMessage[5])
            DispatchQueue.main.async {
                if (self.dataPerson.count == 1 && String(arrayMessage[1]) != self.dataPerson[0]["f_pin"]!!) {
                    self.getDataProfile(fPin: String(arrayMessage[1]))
                    for i in 0...1 {
                        self.scrollRemoteView.addSubview(self.listRemoteViewFix[i])
                        self.listRemoteViewFix[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 160)
                        self.listRemoteViewFix[i].backgroundColor = .clear
                        self.listRemoteViewFix[i].makeRoundedView(radius: 8.0)
                        self.scrollRemoteView.addSubview(self.containerLabelName[i])
                        self.containerLabelName[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 30)
                        self.containerLabelName[i].backgroundColor = .orangeBNI.withAlphaComponent(0.5)
                        self.containerLabelName[i].makeRoundedView(radius: 8.0)
                        if i == 0 {
                            if self.dataPerson[0]["user_type"] == "2" {
                                self.listRemoteViewFix[0].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi)/2)
                            } else {
                                self.listRemoteViewFix[0].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi * 3 )/2)
                            }
                        } else {
                            if arrayMessage[5] == "2" {
                                self.listRemoteViewFix[1].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi)/2)
                            } else {
                                self.listRemoteViewFix[1].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi * 3 )/2)
                            }
                        }
                        let pictureImage = self.dataPerson[i]["picture"]!
                        let namePerson = self.dataPerson[i]["name"]!
                        if (pictureImage != "" && pictureImage != nil) {
                            self.listRemoteViewFix[i].setImage(name: pictureImage!)
                            self.listRemoteViewFix[i].contentMode = .scaleAspectFill
                        } else {
                            self.listRemoteViewFix[i].image = UIImage(systemName: "person")
                            self.listRemoteViewFix[i].backgroundColor = UIColor.systemGray6
                            self.listRemoteViewFix[i].contentMode = .scaleAspectFit
                        }
                        let labelName = UILabel()
                        self.containerLabelName[i].addSubview(labelName)
                        labelName.anchor(left: self.containerLabelName[i].leftAnchor, right: self.containerLabelName[i].rightAnchor, paddingLeft: 5, paddingRight: 5, centerX: self.containerLabelName[i].centerXAnchor, centerY: self.containerLabelName[i].centerYAnchor)
                        labelName.text = namePerson
                        labelName.textAlignment = .center
                        labelName.textColor = .white
                    }
                    self.scrollRemoteView.contentSize.height = CGFloat(170 * 2)
                } else if self.dataPerson.count > 1 {
                    if self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[1]}) != nil {
                        return
                    }
                    self.getDataProfile(fPin: String(arrayMessage[1]))
                    let i = self.dataPerson.count - 1
                    self.scrollRemoteView.addSubview(self.listRemoteViewFix[i])
                    self.listRemoteViewFix[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 160)
                    self.listRemoteViewFix[i].backgroundColor = .clear
                    self.listRemoteViewFix[i].makeRoundedView(radius: 8.0)
                    self.scrollRemoteView.addSubview(self.containerLabelName[i])
                    self.containerLabelName[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 30)
                    self.containerLabelName[i].backgroundColor = .orangeBNI.withAlphaComponent(0.5)
                    self.containerLabelName[i].makeRoundedView(radius: 8.0)
                    if arrayMessage[5] == "2" {
                        self.listRemoteViewFix[i].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi)/2)
                    } else {
                        self.listRemoteViewFix[i].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi * 3 )/2)
                    }
                    let pictureImage = self.dataPerson[self.dataPerson.count - 1]["picture"]!
                    let namePerson = self.dataPerson[self.dataPerson.count - 1]["name"]!
                    if (pictureImage != "" && pictureImage != nil) {
                        self.listRemoteViewFix[i].setImage(name: pictureImage!)
                        self.listRemoteViewFix[i].contentMode = .scaleAspectFill
                    } else {
                        self.listRemoteViewFix[i].image = UIImage(systemName: "person")
                        self.listRemoteViewFix[i].backgroundColor = UIColor.systemGray6
                        self.listRemoteViewFix[i].contentMode = .scaleAspectFit
                    }
                    self.scrollRemoteView.contentSize.height = CGFloat(170 * (i + 1))
                    let labelName = UILabel()
                    self.containerLabelName[i].addSubview(labelName)
                    labelName.anchor(left: self.containerLabelName[i].leftAnchor, right: self.containerLabelName[i].rightAnchor, paddingLeft: 5, paddingRight: 5, centerX: self.containerLabelName[i].centerXAnchor, centerY: self.containerLabelName[i].centerYAnchor)
                    labelName.text = namePerson
                    labelName.textAlignment = .center
                    labelName.textColor = .white
                }
            }
            if arrayMessage[5] == "2" && self.dataPerson.count == 1 {
                DispatchQueue.main.async {
                    self.zoomView.transform   = CGAffineTransform.init(scaleX: -1.9, y: 1.9).rotated(by: (CGFloat.pi)/2)
                    self.zoomView.contentMode = .scaleAspectFit
                }
            }
            else if self.dataPerson.count == 1 {
                DispatchQueue.main.async {
                    self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi * 3)/2)
                    self.zoomView.contentMode = .scaleAspectFit
                }
            } else if self.dataPerson.count > 1 {
                DispatchQueue.main.async {
                    for i in 0..<self.dataPerson.count {
                        if self.dataPerson[i]["user_type"] == "2" || arrayMessage[5] == "2" {
                            self.listRemoteViewFix[i].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi)/2)
                        } else {
                            self.listRemoteViewFix[i].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi * 3 )/2)
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                if self.isInisiator && self.name.isDescendant(of: self.view) {
                    self.didTapAcceptCallButton()
                    self.setSpeaker(isSpeaker: true)
                }
                let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[1]})
                if indexPerson != nil {
                    self.dataPerson[indexPerson!]["user_type"] = String(arrayMessage[5])
                }
            }
        } else if (state == 38 || state == 28) {
            let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                if arrayMessage[0] == requester || arrayMessage[0] == officer {
                    DispatchQueue.main.async {
                        if !self.showNotifCCEnd{
                            let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                            banner.show()
                            self.showNotifCCEnd = true
                        }
                        if self.stackViewToolbar.isDescendant(of: self.view){
                            self.stackViewToolbar.removeFromSuperview()
                        }
                        if self.stackViewToolbar2.isDescendant(of: self.view){
                            self.stackViewToolbar2.removeFromSuperview()
                        }
                        if self.buttonWB.isDescendant(of: self.view){
                            self.buttonWB.removeFromSuperview()
                        }
                        if self.buttonDecline.isDescendant(of: self.view) {
                            self.buttonDecline.removeFromSuperview()
                        }
                        if self.buttonAccept.isDescendant(of: self.view) {
                            self.buttonAccept.removeFromSuperview()
                        }
                        if self.wbVC != nil{
                            self.wbVC!.close?()
                        }
                        self.wbTimer.invalidate()
                        _ = Nexilis.getWhiteboardDelegate()?.terminate()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.endAllCall()
                        self.dismiss(animated: true, completion: nil)
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                if (self.dataPerson.count == 1) {
                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        self.labelIncomingOutgoing.text = "Video call is over".localized()
                    }
                    if self.stackViewToolbar.isDescendant(of: self.view){
                        self.stackViewToolbar.removeFromSuperview()
                    }
                    if self.stackViewToolbar2.isDescendant(of: self.view){
                        self.stackViewToolbar2.removeFromSuperview()
                    }
                    if self.buttonWB.isDescendant(of: self.view){
                        self.buttonWB.removeFromSuperview()
                    }
                    if self.buttonDecline.isDescendant(of: self.view) {
                        self.buttonDecline.removeFromSuperview()
                    }
                    if self.buttonAccept.isDescendant(of: self.view) {
                        self.buttonAccept.removeFromSuperview()
                    }
                    if self.wbVC != nil{
                        self.wbVC!.close?()
                    }
                    self.wbTimer.invalidate()
                    _ = Nexilis.getWhiteboardDelegate()?.terminate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.endAllCall()
                        if self.isInisiator {
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                } else {
                    let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[0]})
                    if indexPerson != nil {
                        if (self.dataPerson.count == 2) {
                            self.scrollRemoteView.subviews.forEach({ $0.removeFromSuperview() })
                        } else {
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            if indexPerson! + 1 <= self.listRemoteViewFix.count {
                                let viewAfterRemote = self.listRemoteViewFix[indexPerson! + 1]
                                let viewAfterName = self.containerLabelName[indexPerson! + 1]
                                viewAfterRemote.frame.origin.y = viewAfterRemote.frame.origin.y - 170
                                viewAfterName.frame.origin.y = viewAfterName.frame.origin.y - 170
                                UIView.animate(withDuration: 0.35, animations: {
                                    self.scrollRemoteView.layoutIfNeeded()
                                })
                            }
                        }
                        self.dataPerson.remove(at: indexPerson!)
                    }
                    if !onGoingCC.isEmpty {
                        if let pin = arrayMessage.first, let index = self.users.firstIndex(of: User(pin: String(pin))) {
                            self.users.remove(at: index)
                        }
                    }
                    
                    if self.dataPerson.count == 1 {
                        self.transformZoomAfterNewUserMore2 = false
                        self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi)/2)
                    }
                }
            }
        } else if (state == -3) {
            let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
            DispatchQueue.main.async {
                if (self.dataPerson.count == 1) {
                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        self.labelIncomingOutgoing.text = "Offline".localized()
                    }
                    if self.buttonDecline.isDescendant(of: self.view) {
                        self.buttonDecline.removeFromSuperview()
                    }
                    if self.buttonAccept.isDescendant(of: self.view) {
                        self.buttonAccept.removeFromSuperview()
                    }
                } else {
                    let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[0]})
                    if indexPerson != nil {
                        if (self.dataPerson.count == 2) {
                            self.scrollRemoteView.subviews.forEach({ $0.removeFromSuperview() })
                        } else {
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            if indexPerson! + 1 <= self.listRemoteViewFix.count {
                                let viewAfterRemote = self.listRemoteViewFix[indexPerson! + 1]
                                let viewAfterName = self.containerLabelName[indexPerson! + 1]
                                viewAfterRemote.frame.origin.y = viewAfterRemote.frame.origin.y - 170
                                viewAfterName.frame.origin.y = viewAfterName.frame.origin.y - 170
                                UIView.animate(withDuration: 0.35, animations: {
                                    self.scrollRemoteView.layoutIfNeeded()
                                })
                            }
                        }
                    }
                    if !onGoingCC.isEmpty {
                        if let pin = arrayMessage.first, let index = self.users.firstIndex(of: User(pin: String(pin))) {
                            self.users.remove(at: index)
                            if !onGoingCC.isEmpty && self.users.count != 0 {
                                DispatchQueue.main.async {
                                    var members = ""
                                    for user in self.users {
                                        if members.isEmpty {
                                            members = "\(user.pin)"
                                        } else {
                                            members = ",\(user.pin)"
                                        }
                                    }
                                    UserDefaults.standard.set("\(members)", forKey: "membersCC")
                                }
                            }
                        }
                    }
                    self.dataPerson.remove(at: indexPerson!)
                }
            }
            if (self.dataPerson.count == 1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.endAllCall()
                    if self.isInisiator && onGoingCC.isEmpty {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else if (state == -4) {
            let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
            DispatchQueue.main.async { [self] in
                if (self.dataPerson.count == 1) {
                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        self.labelIncomingOutgoing.text = "Busy".localized()
                    }
                    if self.buttonDecline.isDescendant(of: self.view) {
                        self.buttonDecline.removeFromSuperview()
                    }
                    if self.buttonAccept.isDescendant(of: self.view) {
                        self.buttonAccept.removeFromSuperview()
                    }
                } else {
                    let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[0]})
                    if indexPerson != nil {
                        if (self.dataPerson.count == 2) {
                            self.scrollRemoteView.subviews.forEach({ $0.removeFromSuperview() })
                        } else {
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            if indexPerson! + 1 <= self.listRemoteViewFix.count {
                                let viewAfterRemote = self.listRemoteViewFix[indexPerson! + 1]
                                let viewAfterName = self.containerLabelName[indexPerson! + 1]
                                viewAfterRemote.frame.origin.y = viewAfterRemote.frame.origin.y - 170
                                viewAfterName.frame.origin.y = viewAfterName.frame.origin.y - 170
                                UIView.animate(withDuration: 0.35, animations: {
                                    self.scrollRemoteView.layoutIfNeeded()
                                })
                            }
                        }
                    }
                    if !onGoingCC.isEmpty {
                        if let pin = arrayMessage.first, let index = self.users.firstIndex(of: User(pin: String(pin))) {
                            self.users.remove(at: index)
                            if !onGoingCC.isEmpty && users.count != 0 {
                                DispatchQueue.main.async {
                                    var members = ""
                                    for user in self.users {
                                        if members.isEmpty {
                                            members = "\(user.pin)"
                                        } else {
                                            members = ",\(user.pin)"
                                        }
                                    }
                                    UserDefaults.standard.set("\(members)", forKey: "membersCC")
                                }
                            }
                        }
                    }
                    self.dataPerson.remove(at: indexPerson!)
                }
            }
            if (self.dataPerson.count == 1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.endAllCall()
                    if self.isInisiator && onGoingCC.isEmpty {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else if (state == 33) {
            DispatchQueue.main.async {
                if (self.dataPerson.count > 1) {
                    if (self.dataPerson.count == 2) {
                        for i in 0...1{
                            self.scrollRemoteView.addSubview(self.listRemoteViewFix[i])
                            self.listRemoteViewFix[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 160)
                            self.listRemoteViewFix[i].backgroundColor = .clear
                            self.listRemoteViewFix[i].makeRoundedView(radius: 8.0)
                            self.scrollRemoteView.addSubview(self.containerLabelName[i])
                            self.containerLabelName[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 30)
                            self.containerLabelName[i].backgroundColor = .orangeBNI.withAlphaComponent(0.5)
                            self.containerLabelName[i].makeRoundedView(radius: 8.0)
                            let pictureImage = self.dataPerson[i]["picture"]!
                            let namePerson = self.dataPerson[i]["name"]!
                            if (pictureImage != "" && pictureImage != nil) {
                                self.listRemoteViewFix[i].setImage(name: pictureImage!)
                                self.listRemoteViewFix[i].contentMode = .scaleAspectFill
                            } else {
                                self.listRemoteViewFix[i].image = UIImage(systemName: "person")
                                self.listRemoteViewFix[i].backgroundColor = UIColor.systemGray6
                                self.listRemoteViewFix[i].contentMode = .scaleAspectFit
                            }
                            let labelName = UILabel()
                            self.containerLabelName[i].addSubview(labelName)
                            labelName.anchor(left: self.containerLabelName[i].leftAnchor, right: self.containerLabelName[i].rightAnchor, paddingLeft: 5, paddingRight: 5, centerX: self.containerLabelName[i].centerXAnchor, centerY: self.containerLabelName[i].centerYAnchor)
                            labelName.text = namePerson
                            labelName.textAlignment = .center
                            labelName.textColor = .white
                        }
                        self.scrollRemoteView.contentSize.height = CGFloat(170 * 2)
                    } else {
                        let i = self.dataPerson.count - 1
                        self.scrollRemoteView.addSubview(self.listRemoteViewFix[i])
                        self.listRemoteViewFix[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 160)
                        self.listRemoteViewFix[i].backgroundColor = .clear
                        self.listRemoteViewFix[i].makeRoundedView(radius: 8.0)
                        self.scrollRemoteView.addSubview(self.containerLabelName[i])
                        self.containerLabelName[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 30)
                        self.containerLabelName[i].backgroundColor = .orangeBNI.withAlphaComponent(0.5)
                        self.containerLabelName[i].makeRoundedView(radius: 8.0)
                        let pictureImage = self.dataPerson[self.dataPerson.count - 1]["picture"]!
                        let namePerson = self.dataPerson[self.dataPerson.count - 1]["name"]!
                        if (pictureImage != "" && pictureImage != nil) {
                            self.listRemoteViewFix[i].setImage(name: pictureImage!)
                            self.listRemoteViewFix[i].contentMode = .scaleAspectFill
                        } else {
                            self.listRemoteViewFix[i].image = UIImage(systemName: "person")
                            self.listRemoteViewFix[i].backgroundColor = UIColor.systemGray6
                            self.listRemoteViewFix[i].contentMode = .scaleAspectFit
                        }
                        self.scrollRemoteView.contentSize.height = CGFloat(170 * (i + 1))
                        let labelName = UILabel()
                        self.containerLabelName[i].addSubview(labelName)
                        labelName.anchor(left: self.containerLabelName[i].leftAnchor, right: self.containerLabelName[i].rightAnchor, paddingLeft: 5, paddingRight: 5, centerX: self.containerLabelName[i].centerXAnchor, centerY: self.containerLabelName[i].centerYAnchor)
                        labelName.text = namePerson
                        labelName.textAlignment = .center
                        labelName.textColor = .white
                    }
                }
            }
        }
    }
}

extension QmeraVideoViewController : WhiteboardReceiver {
    
    func incomingWB(roomId: String) {
        print("incoming wb")
        self.wbTimer.invalidate()
        if(wbRoomId.isEmpty){
            print("wbroom empty")
            DispatchQueue.main.async {
                self.wbTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.runTimer), userInfo: nil, repeats: true)
            }
            wbRoomId = roomId
        }
    }
    
    func cancel(roomId: String) {
        DispatchQueue.main.async {
            self.wbTimer.invalidate()
            self.wbBlink = false
            self.buttonWB.backgroundColor = .lightGray
            self.buttonWB.setNeedsDisplay()
        }
        wbRoomId = ""
    }
    
    @objc func runTimer(){
        DispatchQueue.main.async {
            self.wbBlink = !self.wbBlink
            if(self.wbBlink){
                print("set wb blink on")
                self.buttonWB.backgroundColor = .green
            }
            else {
                print("set wb blink off")
                self.buttonWB.backgroundColor = .lightGray
            }
            self.buttonWB.setNeedsDisplay()
        }
    }
    
}
