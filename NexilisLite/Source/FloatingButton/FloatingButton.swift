//
//  FloatingButton.swift
//  Qmera
//
//  Created by Yayan Dwi on 03/09/21.
//

import UIKit
import nuSDKService
import NotificationBannerSwift


public class FloatingButton: UIView {
    
    var groupView: UIStackView!
    var scrollView: UIScrollView!
    var button_cc: UIButton!
    var button_bni_app: UIButton!
    var button_bni_booking: UIButton!
    var button_history_broadcast: UIButton!
    var button_xpora_app: UIButton!
    var nexilis_button: UIImageView!
    var nexilis_pin: UIImageView!
    var leadingConstraintPin: NSLayoutConstraint!
    var bottomConstraintPin: NSLayoutConstraint!
    var trailingConstraintPin: NSLayoutConstraint!
    var topConstraintPin: NSLayoutConstraint!
    var lastPosY: CGFloat?
    var lastImageButton = ""
    var iconCC = ""
    
    let indicatorCounterFB = UIView()
    let labelCounterFB = UILabel()
    let indicatorCounterFBBig = UIImageView()
    
    var datePull: Date?
    
    var panGesture: UIPanGestureRecognizer?
    
    public var isShow: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        frame = CGRect(x: UIScreen.main.bounds.width - 50, y: (UIScreen.main.bounds.height / 2) - 50, width: 50.0, height: 50.0)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        addGestureRecognizer(panGesture!)
        
        nexilis_button = UIImageView()
        nexilis_button.translatesAutoresizingMaskIntoConstraints = false
        nexilis_button.isUserInteractionEnabled = true
        nexilis_button.image = UIImage(systemName: "person.circle.fill")?.imageWithInsets(insets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))?.withTintColor(.white)
//        var userType = ""
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT image_id, user_type FROM BUDDY where f_pin='\(idMe!)'"), cursorData.next() {
//                userType = cursorData.string(forColumnIndex: 1) ?? ""
                if !cursorData.string(forColumnIndex: 0)!.isEmpty {
                    getImage(name: cursorData.string(forColumnIndex: 0)!, placeholderImage: UIImage(systemName: "person.circle.fill")?.imageWithInsets(insets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)), isCircle: true) { result, isDownloaded, image in
                        self.nexilis_button.image = image?.imageWithInsets(insets: UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80))
                        self.lastImageButton = cursorData.string(forColumnIndex: 0)!
                    }
                }
                cursorData.close()
            }
        })
        nexilis_button.layer.borderWidth = 1.0
        nexilis_button.layer.borderColor = UIColor.white.cgColor
        nexilis_button.layer.cornerRadius = 8.0
        nexilis_button.layer.masksToBounds = true
        nexilis_button.backgroundColor = .black.withAlphaComponent(0.25)
        
        let qmeraTap = UITapGestureRecognizer(target: self, action: #selector(qmeraTap))
        qmeraTap.numberOfTouchesRequired = 1
        nexilis_button.addGestureRecognizer(qmeraTap)
        
        let qmeraLongPress = UILongPressGestureRecognizer(target: self, action: #selector(qmeraLongPress))
        nexilis_button.addGestureRecognizer(qmeraLongPress)
        
        addSubview(nexilis_button)
        
        nexilis_button.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        nexilis_button.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        nexilis_button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        nexilis_button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        nexilis_pin = UIImageView()
        nexilis_pin.translatesAutoresizingMaskIntoConstraints = false
        nexilis_pin.image = UIImage(named: "pb_ball", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        nexilis_button.addSubview(nexilis_pin)
        
        nexilis_pin.widthAnchor.constraint(equalToConstant: 15).isActive = true
        nexilis_pin.heightAnchor.constraint(equalToConstant: 15).isActive = true
        leadingConstraintPin = nexilis_pin.leadingAnchor.constraint(equalTo: nexilis_button.leadingAnchor, constant: 5)
        leadingConstraintPin.isActive = true
        bottomConstraintPin = nexilis_pin.bottomAnchor.constraint(equalTo: nexilis_button.bottomAnchor, constant: -5)
        bottomConstraintPin.isActive = true
        trailingConstraintPin = nexilis_pin.trailingAnchor.constraint(equalTo: nexilis_button.trailingAnchor, constant: -5)
        topConstraintPin = nexilis_pin.topAnchor.constraint(equalTo: nexilis_button.topAnchor, constant: 5)
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.layer.borderWidth = 1.0
        scrollView.layer.borderColor = UIColor.white.cgColor
        scrollView.layer.cornerRadius = 8.0
        scrollView.layer.masksToBounds = true
        scrollView.backgroundColor = .black.withAlphaComponent(0.25)
//        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        scrollView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
//        scrollView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        scrollView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: nexilis_button.topAnchor).isActive = true
        
        groupView = UIStackView()
        groupView.translatesAutoresizingMaskIntoConstraints = false
        groupView.axis = .vertical
        groupView.distribution = .fillEqually

        scrollView.addSubview(groupView)

        groupView.widthAnchor.constraint(equalToConstant: 40).isActive = true
//        groupView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        groupView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 5).isActive = true
        groupView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -5).isActive = true
        groupView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 6).isActive = true
        
        pullButton()
        
//        button_bni_app = UIButton()
//        button_bni_app.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        button_bni_app.translatesAutoresizingMaskIntoConstraints = false
//        button_bni_app.setImage(UIImage(named: "pb_fb_bni2", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
//
//        groupView.addArrangedSubview(button_bni_app)
//
//        button_bni_booking = UIButton()
//        button_bni_booking.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        button_bni_booking.translatesAutoresizingMaskIntoConstraints = false
//        button_bni_booking.setImage(UIImage(named: "pb_button_wb", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
//
//        groupView.addArrangedSubview(button_bni_booking)
//
//        button_history_broadcast = UIButton()
//        button_history_broadcast.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        button_history_broadcast.translatesAutoresizingMaskIntoConstraints = false
//        button_history_broadcast.setImage(UIImage(named: "pb_button_chat-1", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
//
//        groupView.addArrangedSubview(button_history_broadcast)
//
//        button_cc = UIButton()
//        button_cc.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        button_cc.translatesAutoresizingMaskIntoConstraints = false
//        if userType == "23" || userType == "24" {
//            button_cc.setImage(UIImage(named: "pb_button_stream", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
//        } else {
//            button_cc.setImage(UIImage(named: "pb_button_cc-1", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
//        }
//
//        groupView.addArrangedSubview(button_cc)
//
//        button_xpora_app = UIButton()
//        button_xpora_app.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        button_xpora_app.translatesAutoresizingMaskIntoConstraints = false
//        button_xpora_app.setImage(UIImage(named: "pb_fb_expora2", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
//
//        groupView.addArrangedSubview(button_xpora_app)
//
//        button_bni_app.addTarget(self, action: #selector(bniAppTap), for: .touchUpOutside)
//        button_bni_booking.addTarget(self, action: #selector(bniBookingTap), for: .touchUpOutside)
//        button_history_broadcast.addTarget(self, action: #selector(historyBroadcastTap), for: .touchUpOutside)
//        button_cc.addTarget(self, action: #selector(ccTap), for: .touchUpOutside)
//        button_xpora_app.addTarget(self, action: #selector(xporaTap), for: .touchUpOutside)
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(imageFBUpdate(notification:)), name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil)
        center.addObserver(self, selector: #selector(checkCounter), name: NSNotification.Name(rawValue: "onReceiveChat"), object: nil)
        center.addObserver(self, selector: #selector(checkCounter), name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil)
//        checkCounter()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideButton))
        tapGesture.cancelsTouchesInView = false
        UIApplication.shared.windows.first?.rootViewController?.view.addGestureRecognizer(tapGesture)
    }
    
    private func pullButton() {
        if datePull == nil || Int(Date().timeIntervalSince(datePull!)) >= 60 {
            datePull = Date()
        } else if Int(Date().timeIntervalSince(datePull!)) < 60 {
            return
        }
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async { [self] in
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.pullFloatingButton(), timeout: 30 * 1000){
                if response.isOk() {
                    let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                    if !data.isEmpty {
                        if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                            DispatchQueue.main.async { [self] in
                                var userType = ""
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    let idMe = UserDefaults.standard.string(forKey: "me") as String?
                                    if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT image_id, user_type FROM BUDDY where f_pin='\(idMe!)'"), cursorData.next() {
                                        userType = cursorData.string(forColumnIndex: 1) ?? ""
                                        cursorData.close()
                                    }
                                })
                                groupView.subviews.forEach({ $0.removeFromSuperview() })
                                for json in jsonArray {
                                    if json["package_id"] as? String == "fb1" {
                                        button_bni_app = UIButton()
                                        button_bni_app.heightAnchor.constraint(equalToConstant: 40).isActive = true
                                        button_bni_app.translatesAutoresizingMaskIntoConstraints = false
                                        DispatchQueue.global().async {
                                            let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(json["icon"]!!)")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                                            DispatchQueue.main.async { [self] in
                                                if data != nil {
                                                    button_bni_app.setImage(UIImage(data: data!), for: .normal)
                                                }
                                            }
                                        }
                                        groupView.addArrangedSubview(button_bni_app)
                                        button_bni_app.addTarget(self, action: #selector(bniAppTap), for: .touchUpOutside)
                                    } else if json["package_id"] as? String == "fb2" {
                                        button_bni_booking = UIButton()
                                        button_bni_booking.heightAnchor.constraint(equalToConstant: 40).isActive = true
                                        button_bni_booking.translatesAutoresizingMaskIntoConstraints = false
                                        DispatchQueue.global().async {
                                            let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(json["icon"]!!)")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                                            DispatchQueue.main.async { [self] in
                                                if data != nil {
                                                    button_bni_booking.setImage(UIImage(data: data!), for: .normal)
                                                }
                                            }
                                        }
                                        groupView.addArrangedSubview(button_bni_booking)
                                        button_bni_booking.addTarget(self, action: #selector(bniBookingTap), for: .touchUpOutside)
                                    } else if json["package_id"] as? String == "fb3" {
                                        button_history_broadcast = UIButton()
                                        button_history_broadcast.heightAnchor.constraint(equalToConstant: 40).isActive = true
                                        button_history_broadcast.translatesAutoresizingMaskIntoConstraints = false
                                        DispatchQueue.global().async {
                                            let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(json["icon"]!!)")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                                            DispatchQueue.main.async { [self] in
                                                if data != nil {
                                                    button_history_broadcast.setImage(UIImage(data: data!), for: .normal)
                                                }
                                            }
                                        }
                                        groupView.addArrangedSubview(button_history_broadcast)
                                        button_history_broadcast.addTarget(self, action: #selector(historyBroadcastTap), for: .touchUpOutside)
                                        checkCounter()
                                    } else if json["package_id"] as? String == "fb4" {
                                        button_cc = UIButton()
                                        button_cc.heightAnchor.constraint(equalToConstant: 40).isActive = true
                                        button_cc.translatesAutoresizingMaskIntoConstraints = false
                                        iconCC = json["icon"] as! String
                                        if userType == "23" || userType == "24" {
                                            DispatchQueue.global().async {
                                                let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(self.iconCC.components(separatedBy: ",")[1])")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                                                DispatchQueue.main.async { [self] in
                                                    if data != nil {
                                                        button_cc.setImage(UIImage(data: data!), for: .normal)
                                                    }
                                                }
                                            }
                                        } else {
                                            DispatchQueue.global().async {
                                                let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(self.iconCC.components(separatedBy: ",")[0])")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                                                DispatchQueue.main.async { [self] in
                                                    if data != nil {
                                                        button_cc.setImage(UIImage(data: data!), for: .normal)
                                                    }
                                                }
                                            }
                                        }
                                
                                        groupView.addArrangedSubview(button_cc)
                                        button_cc.addTarget(self, action: #selector(ccTap), for: .touchUpOutside)
                                    } else if json["package_id"] as? String == "fb5" {
                                        button_xpora_app = UIButton()
                                        button_xpora_app.heightAnchor.constraint(equalToConstant: 40).isActive = true
                                        button_xpora_app.translatesAutoresizingMaskIntoConstraints = false
                                        DispatchQueue.global().async {
                                            let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(json["icon"]!!)")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                                            DispatchQueue.main.async { [self] in
                                                if data != nil {
                                                    button_xpora_app.setImage(UIImage(data: data!), for: .normal)
                                                }
                                            }
                                        }
                                        groupView.addArrangedSubview(button_xpora_app)
                                        button_xpora_app.addTarget(self, action: #selector(xporaTap), for: .touchUpOutside)
                                    } else {
                                        let newButton = UIButton()
                                        newButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
                                        newButton.translatesAutoresizingMaskIntoConstraints = false
                                        DispatchQueue.global().async {
                                            let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(json["icon"]!!)")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                                            DispatchQueue.main.async {
                                                if data != nil {
                                                    newButton.setImage(UIImage(data: data!), for: .normal)
                                                }
                                            }
                                        }
                                        groupView.addArrangedSubview(newButton)
                                        newButton.restorationIdentifier = json["app_id"] as? String
                                        newButton.addTarget(self, action: #selector(tapMoreApp(_:)), for: .touchUpOutside)
                                    }
                                }
                                let countSubviewsAfter = groupView.subviews.count
                                if countSubviewsAfter <= 5 {
                                    scrollView.isScrollEnabled = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        let size = UIScreen.main.bounds
        let widthScreen = size.width
        let heightScreen = size.height
        let minimumx = (widthScreen + 30) - widthScreen
        let maximumx = widthScreen - 30
        let translation = sender.translation(in: self)
        var xPos = center.x + translation.x
        var yPos = center.y + translation.y
        bringSubviewToFront(self)
        if (xPos < minimumx) {
            xPos = minimumx
        }
        if (xPos > maximumx) {
            xPos = maximumx
        }
        if(isShow) {
            let minimumy = CGFloat(150.5)
            let maximumy = heightScreen - 130
            if(yPos < minimumy) {
                yPos = minimumy
            }
            if(yPos > maximumy) {
                yPos = maximumy
            }
        } else {
            let minimumy = (heightScreen + 50) - heightScreen
            let maximumy = heightScreen - 20
            if(yPos < minimumy) {
                yPos = minimumy
            }
            if(yPos > maximumy) {
                yPos = maximumy
            }
        }
        center = CGPoint(x: xPos, y: yPos)
        sender.setTranslation(CGPoint.zero, in: self)
        if lastPosY != nil {
            lastPosY = nil
        }
        UserDefaults.standard.set(center.x, forKey: "xlastPosFB")
        UserDefaults.standard.set(center.y, forKey: "ylastPosFB")
    }
    
    @objc func imageFBUpdate(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        lastImageButton = data["name"] as! String
        if !lastImageButton.isEmpty {
            getImage(name: lastImageButton, isCircle: true) { result, isDownloaded, image in
                self.nexilis_button.image = image?.imageWithInsets(insets: UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80))
            }
        } else {
            nexilis_button.image = UIImage(systemName: "person.circle.fill")?.imageWithInsets(insets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))?.withTintColor(.white)
        }
        pullButton()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                let idMe = UserDefaults.standard.string(forKey: "me") as String?
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type FROM BUDDY where f_pin='\(idMe!)'"), cursorData.next() {
                    if cursorData.string(forColumnIndex: 0)! == "23" || cursorData.string(forColumnIndex: 0)! == "24" {
                        DispatchQueue.global().async {
                            let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(self.iconCC.components(separatedBy: ",")[1])")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                            DispatchQueue.main.async { [self] in
                                if data != nil {
                                    button_cc.setImage(UIImage(data: data!), for: .normal)
                                }
                            }
                        }
                    } else {
                        DispatchQueue.global().async {
                            let data = try? Data(contentsOf: URL(string: "https://qmera.io/filepalio/image/\(self.iconCC.components(separatedBy: ",")[0])")!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                            DispatchQueue.main.async { [self] in
                                if data != nil {
                                    button_cc.setImage(UIImage(data: data!), for: .normal)
                                }
                            }
                        }
                    }
                    cursorData.close()
                }
            })
        })
    }
    
    @objc func checkCounter() {
        let counter = queryCountCounter()
        if counter > 0 {
            DispatchQueue.main.async { [self] in
                if !indicatorCounterFB.isDescendant(of: button_history_broadcast) {
                    button_history_broadcast.addSubview(indicatorCounterFB)
                    indicatorCounterFB.layer.cornerRadius = 7.5
                    indicatorCounterFB.layer.masksToBounds = true
                    indicatorCounterFB.backgroundColor = .systemRed
                    indicatorCounterFB.anchor(top: button_history_broadcast.topAnchor, left: button_history_broadcast.leftAnchor, height: 15, minWidth: 15, maxWidth: 20)
                    indicatorCounterFB.addSubview(labelCounterFB)
                    labelCounterFB.anchor(left: indicatorCounterFB.leftAnchor, right: indicatorCounterFB.rightAnchor, paddingLeft: 5, paddingRight: 5, centerX: indicatorCounterFB.centerXAnchor, centerY: indicatorCounterFB.centerYAnchor)
                    labelCounterFB.font = .systemFont(ofSize: 10)
                    labelCounterFB.textColor = .white
                }
                if !indicatorCounterFBBig.isDescendant(of: nexilis_button){
                    nexilis_button.addSubview(indicatorCounterFBBig)
                    indicatorCounterFBBig.tintColor = .systemRed
                    indicatorCounterFBBig.image = UIImage(systemName: "staroflife.circle.fill")
                    indicatorCounterFBBig.anchor(top: nexilis_button.topAnchor, left: nexilis_button.leftAnchor, paddingTop: 5, paddingLeft: 5, width: 15, height: 15)
                }
                labelCounterFB.text = "\(counter)"
            }
        } else {
            DispatchQueue.main.async { [self] in
                if indicatorCounterFB.isDescendant(of: button_history_broadcast) {
                    indicatorCounterFB.removeFromSuperview()
                }
                if indicatorCounterFBBig.isDescendant(of: nexilis_button) {
                    indicatorCounterFBBig.removeFromSuperview()
                }
            }
        }
    }
    
    private func queryCountCounter() -> Int32 {
        var counter: Int32?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT SUM(counter) FROM MESSAGE_SUMMARY"), cursor.next() {
                counter = cursor.int(forColumnIndex: 0)
                cursor.close()
            }
        })
        return counter ?? 0
    }

//    private func setTopConstraint(constant: CGFloat) {
//        topConstraint.constant = constant
//    }
    
//    private func addIndicatorCounterFB(counter: Int32) {
//        self.addSubview(indicatorCounterFB)
//        indicatorCounterFB.translatesAutoresizingMaskIntoConstraints = false
//        indicatorCounterFB.backgroundColor = .systemRed
//        indicatorCounterFB.layer.cornerRadius = 7.5
//        indicatorCounterFB.clipsToBounds = true
//        indicatorCounterFB.layer.borderWidth = 0.5
//        indicatorCounterFB.layer.borderColor = UIColor.secondaryColor.cgColor
//        if self.isShow {
//            self.topConstraint = indicatorCounterFB.topAnchor.constraint(equalTo: self.topAnchor, constant: 60)
//        } else {
//            self.topConstraint = indicatorCounterFB.topAnchor.constraint(equalTo: self.topAnchor, constant: 10)
//        }
//        NSLayoutConstraint.activate([
//            self.topConstraint,
//            indicatorCounterFB.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 3),
//            indicatorCounterFB.widthAnchor.constraint(greaterThanOrEqualToConstant: 15),
//            indicatorCounterFB.heightAnchor.constraint(equalToConstant: 15)
//        ])
//
//        indicatorCounterFB.addSubview(labelCounter)
//        labelCounter.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            labelCounter.leadingAnchor.constraint(equalTo: indicatorCounterFB.leadingAnchor, constant: 2),
//            labelCounter.trailingAnchor.constraint(equalTo: indicatorCounterFB.trailingAnchor, constant: -2),
//            labelCounter.centerXAnchor.constraint(equalTo: indicatorCounterFB.centerXAnchor),
//        ])
//        labelCounter.font = UIFont.systemFont(ofSize: 11)
//        if counter > 99 {
//            labelCounter.text = "99+"
//        } else {
//            labelCounter.text = "\(counter)"
//        }
//        labelCounter.textColor = .secondaryColor
//        labelCounter.textAlignment = .center
//    }
    
    @objc func qmeraTap() {
        show(isShow: !isShow)
    }
    
    @objc func tapMoreApp(_ sender: UIButton) {
        let id = sender.restorationIdentifier
        let isChangeProfile = UserDefaults.standard.bool(forKey: "is_change_profile")
        if !isChangeProfile {
            let alert = UIAlertController(title: "Change Profile".localized(), message: "You must change your name to use this feature".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNS") as! ChangeNamePassswordViewController
                let navigationController = UINavigationController(rootViewController: controller)
                navigationController.modalPresentationStyle = .custom
                navigationController.navigationBar.tintColor = .white
                navigationController.navigationBar.barTintColor = .mainColor
                navigationController.navigationBar.isTranslucent = false
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navigationController.navigationBar.titleTextAttributes = textAttributes
                navigationController.view.backgroundColor = .mainColor
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            }))
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
            }
            hideButton()
            return
        }
        if id == nil {
            return
        }
        if let url = URL(string: "itms-apps://apple.com/app/\(id!)") {
            UIApplication.shared.open(url)
        }
        hideButton()
    }
    
    @objc func bniAppTap() {
        let isChangeProfile = UserDefaults.standard.bool(forKey: "is_change_profile")
        if !isChangeProfile {
            let alert = UIAlertController(title: "Change Profile".localized(), message: "You must change your name to use this feature".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNS") as! ChangeNamePassswordViewController
                let navigationController = UINavigationController(rootViewController: controller)
                navigationController.modalPresentationStyle = .custom
                navigationController.navigationBar.tintColor = .white
                navigationController.navigationBar.barTintColor = .mainColor
                navigationController.navigationBar.isTranslucent = false
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navigationController.navigationBar.titleTextAttributes = textAttributes
                navigationController.view.backgroundColor = .mainColor
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            }))
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
            }
            hideButton()
            return
        }
        if let url = URL(string: "itms-apps://apple.com/app/id967205539") {
            UIApplication.shared.open(url)
        }
        hideButton()
    }
    
    @objc func bniBookingTap() {
        let isChangeProfile = UserDefaults.standard.bool(forKey: "is_change_profile")
        if !isChangeProfile {
            let alert = UIAlertController(title: "Change Profile".localized(), message: "You must change your name to use this feature".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNS") as! ChangeNamePassswordViewController
                let navigationController = UINavigationController(rootViewController: controller)
                navigationController.modalPresentationStyle = .custom
                navigationController.navigationBar.tintColor = .white
                navigationController.navigationBar.barTintColor = .mainColor
                navigationController.navigationBar.isTranslucent = false
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navigationController.navigationBar.titleTextAttributes = textAttributes
                navigationController.view.backgroundColor = .mainColor
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            }))
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
            }
            hideButton()
            return
        }
//        let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
//        navigationController.modalPresentationStyle = .custom
//        navigationController.navigationBar.tintColor = .white
//        navigationController.navigationBar.barTintColor = .mainColor
//        navigationController.navigationBar.isTranslucent = false
//        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
//        navigationController.navigationBar.titleTextAttributes = textAttributes
//        navigationController.view.backgroundColor = .mainColor
//        UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        let controller = BNIBookingWebView()
        controller.modalPresentationStyle = .custom
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
        }
        hideButton()
    }
    
    @objc func historyBroadcastTap() {
        let isChangeProfile = UserDefaults.standard.bool(forKey: "is_change_profile")
        if !isChangeProfile {
            let alert = UIAlertController(title: "Change Profile".localized(), message: "You must change your name to use this feature".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNS") as! ChangeNamePassswordViewController
                let navigationController = UINavigationController(rootViewController: controller)
                navigationController.modalPresentationStyle = .custom
                navigationController.navigationBar.tintColor = .white
                navigationController.navigationBar.barTintColor = .mainColor
                navigationController.navigationBar.isTranslucent = false
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navigationController.navigationBar.titleTextAttributes = textAttributes
                navigationController.view.backgroundColor = .mainColor
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            }))
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
            }
            hideButton()
            return
        }
        let controller = HistoryBroadcastViewController()
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .custom
        navigationController.navigationBar.tintColor = .white
        navigationController.navigationBar.barTintColor = .mainColor
        navigationController.navigationBar.isTranslucent = false
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController.navigationBar.titleTextAttributes = textAttributes
        navigationController.view.backgroundColor = .mainColor
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
        hideButton()
    }
    
    @objc func ccTap() {
        let isChangeProfile = UserDefaults.standard.bool(forKey: "is_change_profile")
        if !isChangeProfile {
            let alert = UIAlertController(title: "Change Profile".localized(), message: "You must change your name to use this feature".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNS") as! ChangeNamePassswordViewController
                let navigationController = UINavigationController(rootViewController: controller)
                navigationController.modalPresentationStyle = .custom
                navigationController.navigationBar.tintColor = .white
                navigationController.navigationBar.barTintColor = .mainColor
                navigationController.navigationBar.isTranslucent = false
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navigationController.navigationBar.titleTextAttributes = textAttributes
                navigationController.view.backgroundColor = .mainColor
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            }))
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
            }
            hideButton()
            return
        }
        var isOfficer = false
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type FROM BUDDY where f_pin='\(idMe!)'"), cursorData.next() {
                if cursorData.string(forColumnIndex: 0) == "24" || cursorData.string(forColumnIndex: 0) == "23" {
                    isOfficer = true
                }
                cursorData.close()
                return
            }
        })
        if isOfficer {
            let navigationController = UINavigationController(rootViewController: QmeraCreateStreamingViewController())
            navigationController.modalPresentationStyle = .custom
            navigationController.navigationBar.tintColor = .white
            navigationController.navigationBar.barTintColor = .mainColor
            navigationController.navigationBar.isTranslucent = false
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController.navigationBar.titleTextAttributes = textAttributes
            navigationController.view.backgroundColor = .mainColor
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
            }
        } else {
            let isWaitingRequestCC = UserDefaults.standard.bool(forKey: "waitingRequestCC") 
            if isWaitingRequestCC {
                let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "You have requested Call Center, please wait for response.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            controller.isContactCenter = true
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.modalPresentationStyle = .custom
            navigationController.navigationBar.tintColor = .white
            navigationController.navigationBar.barTintColor = .mainColor
            navigationController.navigationBar.isTranslucent = false
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController.navigationBar.titleTextAttributes = textAttributes
            navigationController.view.backgroundColor = .mainColor
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
            }
        }
        hideButton()
    }
    
    @objc func xporaTap() {
        let isChangeProfile = UserDefaults.standard.bool(forKey: "is_change_profile")
        if !isChangeProfile {
            let alert = UIAlertController(title: "Change Profile".localized(), message: "You must change your name to use this feature".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNS") as! ChangeNamePassswordViewController
                let navigationController = UINavigationController(rootViewController: controller)
                navigationController.modalPresentationStyle = .custom
                navigationController.navigationBar.tintColor = .white
                navigationController.navigationBar.barTintColor = .mainColor
                navigationController.navigationBar.isTranslucent = false
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navigationController.navigationBar.titleTextAttributes = textAttributes
                navigationController.view.backgroundColor = .mainColor
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            }))
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
            }
            hideButton()
            return
        }
        if let url = URL(string: "itms-apps://apple.com/app/id15219838781") {
            UIApplication.shared.open(url)
        }
        hideButton()
//        let controller = QmeraAudioConference()
//        controller.roomId = "TEST-12345"
//        controller.isOutgoing = true
//        controller.modalPresentationStyle = .overCurrentContext
//        UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
    }
    
    @objc func qmeraLongPress() {
        let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "settingNav") as! UINavigationController
        navigationController.modalPresentationStyle = .custom
        navigationController.navigationBar.tintColor = .white
        navigationController.navigationBar.barTintColor = .mainColor
        navigationController.navigationBar.isTranslucent = false
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController.navigationBar.titleTextAttributes = textAttributes
        navigationController.view.backgroundColor = .mainColor
        UIApplication.shared.rootViewController?.present(navigationController, animated: true, completion: nil)
        hideButton()
    }
    
    @objc func hideButton() {
        if isShow {
            show(isShow: false)
        }
        if self.frame.origin.x < UIScreen.main.bounds.width / 2 - 30 {
            self.frame.origin.x = 0
        } else {
            self.frame.origin.x = UIScreen.main.bounds.width - 50
        }
    }
    
    public func show(isShow: Bool) {
        self.isShow = isShow
//        if self.isShow {
//            self.setTopConstraint(constant: 60)
//        } else {
//            self.setTopConstraint(constant: 10)
//        }
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateShowButton"), object: nil, userInfo: nil)
        if isShow {
            pullButton()
            if indicatorCounterFBBig.isDescendant(of: nexilis_button) {
                indicatorCounterFBBig.isHidden = true
            }
            let height = CGFloat(257)
            var yPosition = frame.origin.y - height + 50
            if yPosition <= 25 {
                lastPosY = frame.origin.y
                yPosition = 25
            }
            nexilis_button.image = UIImage(named: "pb_ball_b", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            nexilis_button.backgroundColor = .clear
            if !lastImageButton.isEmpty {
                getImage(name: lastImageButton, isCircle: true) { result, isDownloaded, image in
                    self.nexilis_pin.image = image
                }
            } else {
                nexilis_pin.image = UIImage(systemName: "person.circle.fill")?.withTintColor(.white)
                nexilis_pin.tintColor = .white
            }
            nexilis_button.layer.borderColor = UIColor.clear.cgColor
            leadingConstraintPin.isActive = false
            bottomConstraintPin.isActive = false
            trailingConstraintPin.isActive = true
            topConstraintPin.isActive = true
            frame = CGRect(x: frame.origin.x, y: yPosition, width: frame.width, height: height)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [self] in
                if isShow {
                    let countSubviewsAfter = groupView.subviews.count
                    if countSubviewsAfter > 5 {
                        scrollView.flashScrollIndicators()
                    }
                }
            })
        } else {
            if indicatorCounterFBBig.isDescendant(of: nexilis_button) {
                indicatorCounterFBBig.isHidden = false
            }
            let height = CGFloat(257)
            var yPosition = frame.origin.y + height - 50
            if lastPosY != nil {
                yPosition = lastPosY!
            }
            if !lastImageButton.isEmpty {
                getImage(name: lastImageButton, isCircle: true) { result, isDownloaded, image in
                    self.nexilis_button.image = image?.imageWithInsets(insets: UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80))
                }
            } else {
                nexilis_button.image = UIImage(systemName: "person.circle.fill")?.imageWithInsets(insets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))?.withTintColor(.white)
            }
            nexilis_button.layer.borderColor = UIColor.white.cgColor
            nexilis_button.backgroundColor = .black.withAlphaComponent(0.25)
            nexilis_pin.image = UIImage(named: "pb_ball", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            trailingConstraintPin.isActive = false
            topConstraintPin.isActive = false
            leadingConstraintPin.isActive = true
            bottomConstraintPin.isActive = true
            frame = CGRect(x: frame.origin.x, y: yPosition, width: frame.width, height: frame.width)
        }
    }
}
