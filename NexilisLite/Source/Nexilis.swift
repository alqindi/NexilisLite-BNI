//
//  Qmera.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import nuSDKService
import AVFoundation
import AVKit
import UIKit
import FMDB
import QuickLook
import NotificationBannerSwift
import MLKitFaceDetection
import MLKitVision
import MLImage

public class Nexilis: NSObject {
    public static var sAPIKey = ""
    
    static let ADDRESS = ADDRESS_RELEASE
    
    static let ADDRESS_33 = "192.168.0.33"
    
    static let ADDRESS_RELEASE = "202.158.33.26"
    
    //    static let PORT = 45328
    //    static let PORT = 65328 // 33
    static let PORT = PORT_RELEASE
    
    static let PORT_33 = 62328
    
    static let PORT_RELEASE = 42328
    
    static var nSessionMode: Int! = 1
    
    static var dispatch: DispatchGroup?
    
    let callManager = CallManager()
    
    var providerDelegate: CallProviderDelegate?
    
    public static let shared = Nexilis()
    
    public static var broadcastTimer = Timer()
    
    public static var broadcastList = [[String: String]]()
    
    public static var onGoingPushCC: [String: String] = [:]
    
    public static var openBroadcast = false
    
    private func createDelegate() {
        print("createDelegate...")
        callDelegate = self
        messageDelegate = self
        groupDelegate = self
        personInfoDelegate = self
        providerDelegate = CallProviderDelegate(callManager: callManager)
    }
    
    public static func connect(apiKey: String, delegate: ConnectDelegate, showButton: Bool = true) {
        do {
            Nexilis.shared.createDelegate()
            
            Nexilis.sAPIKey = apiKey
            
            Database.shared.openDatabase()
            
            IncomingThread.default.run()
            
            OutgoingThread.default.run()
            
            if let _ = UserDefaults.standard.stringArray(forKey: "address") {
                
            }
            else {
                //                let address = App.getAddress()
                //                if !address.isEmpty {
                //                    print(address)
                //                    print(address[0])
                //                    UserDefaults.standard.set(address, forKey: "address")
                //                    UserDefaults.standard.set(address[0], forKey: "server")
                //                }
            }
            
            Nexilis.dispatch = DispatchGroup()
            Nexilis.dispatch?.enter()
            //            var server = UserDefaults.standard.string(forKey: "server")
            //            if let s = server, let a = UserDefaults.standard.stringArray(forKey: "address"), s != a[0] {
            //                server = a[0]
            //                UserDefaults.standard.set(server, forKey: "server")
            //            }
            //            var ip = ""
            //            var port = 0
            //            if let s = server {
            //                let data = s.split(separator: ":")
            //                ip = String(data[0])
            //                if let p = Int(data[1]) {
            //                    port = p
            //                }
            //            }
            //            print(API.sGetVersion())
            var id = ""
            if let me = UserDefaults.standard.string(forKey: "me") {
                try API.initConnection(bSwitchIP: false, sAPIK: apiKey, aAppMain: nil, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: me, sStartWH: "09:00")
            } else {
                let uuid = UIDevice.current.identifierForVendor?.uuidString ?? "UNK-DEVICE"
                try API.initConnection(bSwitchIP: false, sAPIK: apiKey, aAppMain: nil, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: uuid, sStartWH: "09:00")
                id = uuid
            }
            
            // wait until connection true
            Nexilis.dispatch?.wait()
            Nexilis.dispatch = nil
            
            if(!id.isEmpty && (UserDefaults.standard.string(forKey: "me") == nil)){
                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignUpApi(api: apiKey, p_pin: id), timeout: 30 * 1000){
                    id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                    if(!id.isEmpty) {
                        Nexilis.changeUser(f_pin: id)
                        UserDefaults.standard.setValue(id, forKey: "me")
                    }
                }
            }
            
            if let me = UserDefaults.standard.string(forKey: "me") {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: me))
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
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.5, execute: {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT image_id FROM GROUPZ where group_type = 1 AND official = 1"), cursorData.next() {
                            do {
                                let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                let file = documentDir.appendingPathComponent(cursorData.string(forColumnIndex: 0)!)
                                if !FileManager().fileExists(atPath: file.path) {
                                    Download().start(forKey: cursorData.string(forColumnIndex: 0)!) { (name, progress) in}
                                }
                            } catch {}
                            cursorData.close()
                        }
                    })
                })
                delegate.onSuccess(userId: me)
                if showButton {
                    DispatchQueue.main.async {
                        var viewController = UIApplication.shared.windows.first?.rootViewController
                        var notNull = false
                        while !notNull {
                            viewController = UIApplication.shared.windows.first?.rootViewController
                            if viewController != nil {
                                notNull = true
                            }
                        }
                        viewController?.view.addSubview(FloatingButton())
                    }
                }
            }
            Nexilis.destroyAll()
        }
        catch {
            print(error)
            delegate.onFailed(error: "99:Something went wrong")
        }
    }
    
    public static func destroyAll() {
        let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
            let requester = onGoingCC.components(separatedBy: ",")[0]
            let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
            let complaintId = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2]
            let idMe = UserDefaults.standard.string(forKey: "me")!
            let startTimeCC = UserDefaults.standard.string(forKey: "startTimeCC") ?? ""
            let date = "\(Date().currentTimeMillis())"
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                        "type" : "0",
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
            if UIApplication.shared.applicationState == .active {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }
        if !Nexilis.onGoingPushCC.isEmpty {
            DispatchQueue.global().async {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: Nexilis.onGoingPushCC["channel"]!, l_pin: Nexilis.onGoingPushCC["l_pin"]!))
            }
        }
        UserDefaults.standard.removeObject(forKey: "inEditorPersonal")
        UserDefaults.standard.removeObject(forKey: "inEditorGroup")
        UserDefaults.standard.removeObject(forKey: "waitingRequestCC")
    }
    
    public static func changeUser(f_pin: String){
        do {
            print("change user to fpin")
            Nexilis.dispatch = DispatchGroup()
            Nexilis.dispatch?.enter()
            
            try API.initConnection(bSwitchIP: true, sAPIK: Nexilis.sAPIKey, aAppMain: nil, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: f_pin, sStartWH: "08:00")
            
            // wait until connection true
            Nexilis.dispatch?.wait()
            Nexilis.dispatch = nil
            print("success change user to fpin")
            _ = Nexilis.writeSync(message: CoreMessage_TMessageBank.getChangeConnectionID(p_pin: f_pin))
        } catch{
            print(error)
        }
    }
    
    public static func addQueueMessage(message: TMessage) {
        OutgoingThread.default.addQueue(message: message)
    }
    
    private static var wbDelegate: WhiteboardDelegate?
    private static var wbReceiver: WhiteboardReceiver?
    
    public static func setWhiteboardDelegate(delegate: WhiteboardDelegate?){
        Nexilis.wbDelegate = delegate
    }
    
    public static func getWhiteboardDelegate() -> WhiteboardDelegate? {
        return Nexilis.wbDelegate
    }
    
    public static func setWhiteboardReceiver(receiver: WhiteboardReceiver?){
        Nexilis.wbReceiver = receiver
    }
    
    public static func getWhiteboardReceiver() -> WhiteboardReceiver? {
        return Nexilis.wbReceiver
    }
    
    public static func getEditorPersonal() -> EditorPersonal {
        return AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
    }

    public static func getEditorGroup() -> EditorGroup {
        return AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
    }
    
    public static func getEditorStarMessage() -> EditorStarMessages {
        return AppStoryBoard.Palio.instance.instantiateViewController(identifier: "staredVC") as! EditorStarMessages
    }
    
    static func getAddress() -> [String] {
        var result = [String]()
        let url = URL(string: "https://newuniverse.io/dipp/NuN1v3rs3/5ch0oL18")!
        let urlConfig = URLSessionConfiguration.default
        urlConfig.requestCachePolicy = .returnCacheDataElseLoad
        urlConfig.timeoutIntervalForRequest = 10.0
        urlConfig.timeoutIntervalForResource = 10.0
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession(configuration: urlConfig).dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                semaphore.signal()
                return
            }
            let html = String(data: data, encoding: .utf8)!
            let base64Address = html.components(separatedBy: "<body>")[1].components(separatedBy: "</body>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if let addressData = Data(base64Encoded: base64Address), let decodeAddress = String(data: addressData, encoding: .utf8) {
                let rows = decodeAddress.trimmingCharacters(in: CharacterSet.newlines).split(separator: ",")
                for r in rows {
                    let _address = r.split(separator: ":")
                    var ip:String = ""
                    let _data = _address[0].split(separator: ".", maxSplits: 4, omittingEmptySubsequences: false)
                    ip.append(String(_data[3]))
                    ip.append(".")
                    ip.append(String(_data[1]))
                    ip.append(".")
                    ip.append(String(_data[0]))
                    ip.append(".")
                    ip.append(String(_data[2]))
                    result.append(ip + ":" + _address[2])
                }
                
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        debugPrint("[App] getAddress:", result)
        return result
    }
    
    static func getCLMUserId() -> String {
        guard let me = UserDefaults.standard.string(forKey: "me") else {
            return ""
        }
        return me
    }
    
    public static func writeSync(message: TMessage, timeout: Int = 15 * 1000) -> TMessage? {
        do {
            print(">> SENDING MESSAGE >> ", message.toLogString())
            if let data = try API.sGetResponse(sRequest: message.pack(), lTimeout: timeout, bKeepTOResp: true) {
                let response = TMessage(data: data)
                print("<< RESPONSE MESSAGE << ", response.toLogString())
                return response
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    public static func write(message: TMessage, timeout: Int = 15 * 1000) -> String? {
        do {
            if API.nGetCLXConnState() == 0 {
                return nil
            }
            print(">> SENDING MESSAGE >> ", message.toLogString())
            if message.getMedia().count == 0 {
                if let data = try API.sSend(sData: message.pack(), nPriority: 1, lTimeout: timeout) {
                    print("<< RESPONSE MESSAGE << ", data)
                    return data
                }
            }
            // media
            if let data = try API.sSend(abData: message.toBytes(), nPriority: 2, lTimeout: timeout) {
                print("<< RESPONSE MESSAGE << ", data)
                return data
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    public static func writeDraw(data: String, timeout: Int = 15 * 1000) -> String? {
        do {
            if !API.bInetConnAvailable() {
                return nil
            }
            print(">> SENDING MESSAGE >> ", data)
            if let data = try API.sSend(sData: data, nPriority: 1, lTimeout: timeout) {
                print("<< RESPONSE MESSAGE << ", data)
                return data
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    public static func response(packetId: String, message: TMessage, timeout: Int = 15 * 1000) -> String? {
        var result: String? = nil
        do {
            if !API.bInetConnAvailable() {
                return nil
            }
            print(">> RESPONSE >> " + packetId + " " + message.toLogString());
            result = try API.sSendResponse(sRequestID: packetId, sResponse: message.pack(), lTimeout: timeout)
        } catch {
            print(error)
        }
        return result
    }
    
    public static func startAudio(nMode: Int!, bSpeakerOn: Bool!) {
        
        let xSessionMode = nMode == 0 ? nSessionMode : nMode
        do {
            if ("iPhone 6" == UIDevice.current.modelName) {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .duckOthers)
                if (xSessionMode == 1) {
                    try AVAudioSession.sharedInstance().setMode(.voiceChat)
                } else if (xSessionMode == 2) {
                    try AVAudioSession.sharedInstance().setMode(.voiceChat)
                    // try avAudioSession.setMode(AVAudioSessionModeVideoChat)
                }
                if (bSpeakerOn) {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                } else {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                }
            } else {
                if (bSpeakerOn) {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
                } else {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .duckOthers)
                }
                if (xSessionMode == 1) {
                    try AVAudioSession.sharedInstance().setMode(.voiceChat)
                } else if (xSessionMode == 2) {
                    try AVAudioSession.sharedInstance().setMode(.voiceChat)
                }
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        nSessionMode = xSessionMode
    }
    
    public static func turnSpeakerOn(bSpeakerOn: Bool!) {
        do{
            if ("iPhone 6" == UIDevice.current.modelName) {
                if (bSpeakerOn) {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                } else {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                }
                return
            }
        }catch{
            print(error)
        }
        
        API.pauseAudio()
        stopAudio()
        startAudio(nMode: 0, bSpeakerOn: bSpeakerOn)
        API.resumeAudio(bSpeakerOn: bSpeakerOn)
    }
    public static func stopAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setMode(.default)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
        }catch{
            print(error)
        }
    }
    
    public static func muteMicrophone(isMute: Bool!){
        do {
            if(isMute){
                try AVAudioSession.sharedInstance().setCategory(.playback)
            }
            else{
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            }
        }catch{
            print(error)
        }
    }
    
    private static var groupWait = DispatchGroup()
    
    private static var waitQueue = [String: TMessage]()
    
    public static func writeAndWait(message: TMessage, timeout: Int = 15 * 1000) -> TMessage? {
        groupWait.enter()
        _ = write(message: message, timeout: timeout)
        waitQueue[message.getStatus()] = message
        if groupWait.wait(timeout: .now() + 15) == .timedOut {
            waitQueue.removeValue(forKey: message.getStatus())
            groupWait.leave()
            return nil
        }
        return waitQueue.removeValue(forKey: message.getStatus())
    }
    
    static func incomingData(packetId: String, data: AnyObject) {
        let message = TMessage()
        if data is String {
            let d = data as! String
            guard message.unpack(data: d) else {
                print("UNKNOWN DATA STRING...", data)
                if(data.hasPrefix("WB")){
                    let dataWB = data.components(separatedBy: "/")
                    if(dataWB[1] == "1"){
                        let x = dataWB[2]
                        let y = dataWB[3]
                        let w = dataWB[4]
                        let h = dataWB[5]
                        let fc = dataWB[6]
                        let sw = dataWB[7]
                        let xo = dataWB[8]
                        let yo = dataWB[9]
                        if(Nexilis.getWhiteboardDelegate() != nil){
                            Nexilis.getWhiteboardDelegate()!.draw(x: x, y: y, w: w, h: h, fc: fc, sw: sw, xo: xo, yo: yo, data: "")
                        }
                    } else if(dataWB[1] == "3") {
                        if(Nexilis.getWhiteboardDelegate() != nil){
                            Nexilis.getWhiteboardDelegate()!.clear()
                        }
                    } else if(dataWB[1] == "2"){
                        if(Nexilis.getWhiteboardReceiver() != nil){
                            Nexilis.getWhiteboardReceiver()!.incomingWB(roomId: dataWB[2])
                        }
                    } else if(dataWB[1] == "22"){
                        
                    } else if(dataWB[1] == "88"){
                        if(Nexilis.getWhiteboardReceiver() != nil){
                            Nexilis.getWhiteboardReceiver()!.cancel(roomId: dataWB[2])
                        }
                    }
                }
                return
            }
        } else if data is [UInt8] {
            let d = data as! [UInt8]
            guard message.unpack(bytes_data: d) else {
                print("UNKNOWN DATA BYTES...", data)
                return
            }
        }
        message.mBodies[CoreMessage_TMessageKey.PACKET_ID] = packetId
        if let _ = waitQueue[message.getStatus()] {
            waitQueue[message.getStatus()] = message
            groupWait.leave()
            return
        }
        IncomingThread.default.addQueue(message: message)
    }
    
    static func saveMessage(message: TMessage, withStatus: Bool = true) {
        guard let me = UserDefaults.standard.string(forKey: "me") else {
            return
        }
        let message_id = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_ID, default_value : "")
        guard !message_id.isEmpty else {
            return
        }
        let f_pin = message.getBody(key : CoreMessage_TMessageKey.F_PIN, default_value : "")
        guard !f_pin.isEmpty else {
            return
        }
        let l_pin = message.getBody(key : CoreMessage_TMessageKey.L_PIN, default_value : "")
        let scope = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_SCOPE_ID, default_value : "3")
        let status = message.getBody(key : CoreMessage_TMessageKey.STATUS, default_value : "")
        let chat_id = message.getBody(key : CoreMessage_TMessageKey.CHAT_ID, default_value : "")
        let broadcast_flag = message.getBody(key: CoreMessage_TMessageKey.BROADCAST_FLAG, default_value: "0")
        let is_call_center = message.getBody(key: CoreMessage_TMessageKey.IS_CALL_CENTER, default_value: "0")
        let call_center_id = message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID, default_value: "")
        print("prepare save db")
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                    "message_id" : message_id,
                    "f_pin" : f_pin,
                    "f_display_name" : message.getBody(key : CoreMessage_TMessageKey.F_DISPLAY_NAME, default_value : ""),
                    "l_pin" : l_pin,
                    "l_user_id" : message.getBody(key : CoreMessage_TMessageKey.L_USER_ID, default_value : ""),
                    "message_scope_id" : scope,
                    "server_date" : message.getBody(key: CoreMessage_TMessageKey.SERVER_DATE, default_value : String(Date().currentTimeMillis())),
                    "status" : status,
                    "message_text" : message.getBody(key : CoreMessage_TMessageKey.MESSAGE_TEXT, default_value : "").toNormalString(),
                    "audio_id" : message.getBody(key : CoreMessage_TMessageKey.AUDIO_ID, default_value : ""),
                    "video_id" : message.getBody(key : CoreMessage_TMessageKey.VIDEO_ID, default_value : ""),
                    "image_id" : message.getBody(key : CoreMessage_TMessageKey.IMAGE_ID, default_value : ""),
                    "file_id" : message.getBody(key : CoreMessage_TMessageKey.FILE_ID, default_value : ""),
                    "thumb_id" : message.getBody(key : CoreMessage_TMessageKey.THUMB_ID, default_value : ""),
                    "opposite_pin" : message.getBody(key : CoreMessage_TMessageKey.OPPOSITE_PIN, default_value : ""),
                    "format" : message.getBody(key : CoreMessage_TMessageKey.FORMAT, default_value : ""),
                    "blog_id" : message.getBody(key : CoreMessage_TMessageKey.BLOG_ID, default_value : ""),
                    "read_receipts" : message.getBody(key: CoreMessage_TMessageKey.READ_RECEIPTS, default_value:  "0"),
                    "chat_id" : chat_id,
                    "account_type" : message.getBody(key : CoreMessage_TMessageKey.BUSINESS_CATEGORY, default_value : "1"),
                    "credential" : message.getBody(key : CoreMessage_TMessageKey.CREDENTIAL, default_value : ""),
                    "reff_id" : message.getBody(key : CoreMessage_TMessageKey.REF_ID, default_value : ""),
                    "message_large_text" : message.getBody(key : CoreMessage_TMessageKey.BODY, default_value : "").toNormalString(),
                    "attachment_flag" : message.getBody(key: CoreMessage_TMessageKey.ATTACHMENT_FLAG, default_value:  "0"),
                    "local_timestamp" : message.getBody(key: CoreMessage_TMessageKey.LOCAL_TIMESTAMP, default_value : String(Date().currentTimeMillis())),
                    "broadcast_flag" : broadcast_flag,
                    "is_call_center" : is_call_center,
                    "call_center_id" : call_center_id
                ], replace: true)
            } catch {
                rollback.pointee = true
                print(error)
            }
        })
        
        if withStatus {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if scope == "4" {
                        for pin in getGroupMembers(fmdb: fmdb, l_pin: l_pin) {
                            if f_pin == pin { continue }
                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                "message_id" : message_id,
                                "status" : status,
                                "f_pin" : pin,
                                "last_update" : Date().currentTimeMillis()
                            ], replace: true)
                        }
                    } else {
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                            "message_id" : message_id,
                            "status" : status,
                            "f_pin" : l_pin,
                            "last_update" : Date().currentTimeMillis()
                        ], replace: true)
                    }
                } catch {
                    rollback.pointee = true
                    print(error)
                }
            })
        }
        var pin = l_pin
        if l_pin == me {
            pin = f_pin
        }
        if !chat_id.isEmpty {
            pin = chat_id
        }
        var counter : Int? = nil
        if l_pin == me || (scope == "4" && f_pin != me) {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select counter from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                    counter = Int(cursor.int(forColumnIndex: 0))
                    counter! += 1
                    cursor.close()
                    print("select db message summary")
                }
            })
            if counter == nil {
                counter = 1
                print("set counter message summary")
            }
        }
        if counter == nil {
            counter = 0
        }
        if is_call_center == "0" {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                        "l_pin" : pin,
                        "message_id" : message_id,
                        "counter" : counter!
                    ], replace: true)
                } catch {
                    rollback.pointee = true
                    print(error)
                }
            })
        }
        print("insert db message summary \(message_id)")
        
    }
    
    public static func saveMessageBot(textMessage: String, blog_id: String, attachment_type:String)->Void{
        guard let me = UserDefaults.standard.string(forKey: "me") else {
            return
        }
        
        var user_id:String? = ""
        let message_id = me + CoreMessage_TMessageUtil.getTID()
        
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select user_id from BUDDY where f_pin = '\(me)'"), cursor.next() {
                user_id = cursor.string(forColumnIndex: 0)
                cursor.close()
            }
        })
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                    "message_id" : message_id ,
                    "f_pin" : "-999",
                    "f_display_name" : "Bot",
                    "l_pin" : me,
                    "l_user_id" : String(user_id!),
                    "message_scope_id" : "3",
                    "server_date" : String(Date().currentTimeMillis()),
                    "status" : "3",
                    "message_text" : textMessage,
                    "audio_id" : "",
                    "video_id" : "",
                    "image_id" : "",
                    "file_id" : "",
                    "thumb_id" : "",
                    "opposite_pin" : "",
                    "format" : "",
                    "blog_id" : blog_id,
                    "read_receipts" : "0",
                    "chat_id" : "",
                    "account_type" : "1",
                    "credential" :"",
                    "reff_id" : "",
                    "message_large_text" : "",
                    "attachment_flag" : attachment_type,
                    "local_timestamp" : String(Date().currentTimeMillis())
                ], replace: true)
            } catch {
                rollback.pointee = true
                print(error)
            }
        })
        let pin = "-999"
        var counter : Int? = nil
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select counter from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                counter = Int(cursor.int(forColumnIndex: 0))
                counter! += 1
                cursor.close()
                print("select db message summary")
            }
        })
        if counter == nil {
            counter = 1
            print("set counter message summary")
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "l_pin" : pin,
                    "message_id" : message_id,
                    "counter" : counter!
                ], replace: true)
            } catch {
                rollback.pointee = true
                print(error)
            }
        })
        print("insert db message summary \(message_id)")
    }
    
    static func updateMessageStatus(message: TMessage) -> Void {
        let message_id = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_ID, default_value : "")
        guard !message_id.isEmpty else {
            return
        }
        let status = message.getBody(key : CoreMessage_TMessageKey.STATUS, default_value : "")
        guard !status.isEmpty else {
            return
        }
        let l_pin = message.getBody(key : CoreMessage_TMessageKey.L_PIN, default_value : "")
        guard !l_pin.isEmpty else {
            return
        }
        Database.shared.database?.inTransaction({ (fmdb, rollbac) in
            if message_id.starts(with: "-1") || message_id.starts(with: "-2") {
                for s in message_id.split(separator: ",") {
                    let t = s.trimmingCharacters(in: .whitespaces)
                    if t == "-1" || t == "-2" {
                        continue
                    }
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                                        "status" : status,
                                                        "last_update" : String(Date().currentTimeMillis())], _where: "message_id = '\(t)' and f_pin = '\(l_pin)'")
                }
            } else {
                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                                    "status" : status,
                                                    "last_update" : String(Date().currentTimeMillis())], _where: "message_id = '\(message_id)' and f_pin = '\(l_pin)'")
            }
        })
    }
    
    static func getGroupMembers(fmdb: FMDatabase, l_pin: String) -> [String] {
        var result = [String]()
        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin from GROUPZ_MEMBER where group_id = '\(l_pin)'") {
            while cursor.next() {
                if let value = cursor.string(forColumnIndex: 0) {
                    result.append(value)
                }
            }
            cursor.close()
        }
        return result
    }
    
    static func getVideoThumbnail(name: String, completion: @escaping (Bool)->()) {
        DispatchQueue.global().async {
            do {
                let fileManager = FileManager.default
                let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileDir = documentDir.appendingPathComponent(name)
                let path = fileDir.path
                if FileManager.default.fileExists(atPath: path) {
                    let asset = AVAsset(url: URL(fileURLWithPath: path))
                    let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                    avAssetImageGenerator.appliesPreferredTrackTransform = true
                    let thumnailTime = CMTimeMake(value: 2, timescale: 1)
                    let thumbImage = UIImage(cgImage: try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil))
                    guard let data = thumbImage.jpegData(compressionQuality: 1.0) else {
                        completion(false)
                        return
                    }
                    let thumbFileDir = documentDir.appendingPathComponent("THUMB_" + name)
                    try data.write(to: thumbFileDir)
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print(error)
            }
        }
    }
    
    static func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    static func initFollowing() -> Void {
        if let me = UserDefaults.standard.string(forKey: "me") {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getListFollowing(l_pin: me)) {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                if !data.isEmpty {
                    if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                for json in jsonArray {
                                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "FOLLOW", cvalues: [
                                        "f_pin" : CoreMessage_TMessageUtil.getString(json: json, key: "pin")
                                    ], replace: true)
                                }
                            } catch {
                                rollback.pointee = true
                                print(error)
                            }
                        })
                    }
                }
            }
        }
    }
    
//    do {
//        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
//            "type" : "1",
//            "title" : displayName,
//            "time" : timeStart,
//            "f_pin" : f_pin,
//            "data" : dataCC,
//            "time_end" : date,
//            "complaint_id" : complaint_id.isEmpty ? "C\(date)" : complaint_id,
//            "members" : "",
//            "requester": ""
//        ], replace: true)
//        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "PREFS", cvalues: [
//            "key" : "CC:\(f_pin)",
//            "value" : status,
//        ], replace: true)
//        ret = true
//    } catch {
//        rollback.pointee = true
//        print(error)
//    }
    
    private static var uploadQueue = DispatchQueue(label: "UPLOAD_DICT", attributes: .concurrent)
    
    private static var UPLOAD_DICT = [String: Network]()
    
    static func removeUploadFile(forKey: String) -> Network? {
        var _result: Network? = nil
        uploadQueue.sync {
            _result = self.UPLOAD_DICT.removeValue(forKey: forKey)
        }
        return _result
    }
    
    static func putUploadFile(forKey: String, uploader: Network) {
        uploadQueue.async (flags: .barrier) {
            self.UPLOAD_DICT[forKey] = uploader
        }
    }
    
    static func getUploadFile(forKey: String) -> Network? {
        var _result: Network? = nil
        uploadQueue.sync {
            _result = self.UPLOAD_DICT[forKey]
        }
        return _result
    }
    
    private static var downloadQueue = DispatchQueue(label: "DOWNLOAD_DICT", attributes: .concurrent)
    
    private static var DOWNLOAD_DICT = [String:Download]()
    
    static func addDownload(forKey : String, download: Download){
        downloadQueue.async (flags: .barrier) {
            self.DOWNLOAD_DICT[forKey] = download
        }
    }
    
    static func getDownload(forKey: String) -> Download? {
        var _result: Download? = nil
        downloadQueue.sync {
            _result = self.DOWNLOAD_DICT[forKey]
        }
        return _result
    }
    
    static func writeImageToFile(data: Data, fileName: String){
        guard let directory = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).last else {
            return
        }
        let fileURL = directory.appendingPathComponent("\(fileName)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                print("Can't open file to write")
            }
        } else {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Unable to write in new file")
            }
        }
    }
    
    static func writeVideoToFile(data: Data, fileName: String){
        guard let directory = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).last else {
            return
        }
        let fileURL = directory.appendingPathComponent("\(fileName)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                print("Can't open file to write")
            }
        } else {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Unable to write in new file")
            }
        }
    }
    
    static func writeDocumentsToFile(data: Data, fileName: String){
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            return
        }
        let fileURL = directory.appendingPathComponent("\(fileName)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                print("Can't open file to write")
            }
        } else {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Unable to write in new file")
            }
        }
    }
    
    public static func checkMicPermission() -> Bool {
        var permissionCheck: Bool = false

        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            permissionCheck = true
        case .denied:
            permissionCheck = false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    permissionCheck = true
                } else {
                    permissionCheck = false
                }
            })
        default:
            break
        }

        return permissionCheck
    }
    
    public static func checkCameraPermission() -> Int {
        var permissionCheck: Int = -1
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            permissionCheck = 1
        } else if AVCaptureDevice.authorizationStatus(for: .video) ==  .denied {
            permissionCheck = 0
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
               
            })
        }
        return permissionCheck
    }
    
    public static func startTimer(){
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: {_ in
            if(!openBroadcast && !broadcastList.isEmpty){
                openBroadcast = true
                let m = broadcastList.removeFirst()
                print("broadcast show: \(m)")
                DispatchQueue.main.async {
                    Nexilis.shared.showBroadcastMessage(m: m)
                }
            }
        })
    }
    
    /*
     * Delegate
     */
    
    weak open var loginDelegate: LoginDelegate?
    
    weak open var messageDelegate: MessageDelegate?
    
    weak open var groupDelegate: GroupDelegate?
    
    weak open var callDelegate: CallDelegate?
    
    weak open var streamingDelagate: LiveStreamingDelegate?
    
    weak open var personInfoDelegate: PersonInfoDelegate?
    
    weak open var screenSharingDelegate: ScreenSharingDelegate?
    
    weak open var commentDelegate: CommentDelegate?
    
    weak open var uploadDelegate: UploadDelegate?
    
    weak open var timelineDelegate: TimelineDelegate?
    
    weak open var connectionDelegate: ConnectionDelegate?
    
}

public protocol LoginDelegate: NSObjectProtocol {
    func onProgress(code: String, progress: Int)
    func onProcess(message: String, status: String)
}

public protocol MessageDelegate: NSObjectProtocol {
    func onReceive(message: TMessage)
    func onReceiveComment(message: TMessage)
    func onReceive(message: [AnyHashable: Any?])
    func onMessage(message: TMessage)
    func onUpload(name: String, progress: Double)
    func onTyping(message: TMessage)
}

public protocol GroupDelegate: NSObjectProtocol {
    func onGroup(code: String, f_pin: String, groupId: String)
    func onTopic(code: String, f_pin: String, topicId: String)
    func onMember(code: String, f_pin: String, groupId: String, member: String)
}

public protocol DownloadDelegate: NSObjectProtocol {
    func onDownloadProgress(fileName: String, progress: Double)
}

public protocol CallDelegate: NSObjectProtocol {
    func onIncomingCall(state: Int, message: String)
    func onStatusCall(state: Int, message: String)
}

public protocol LiveStreamingDelegate: NSObjectProtocol {
    func onStartLS(state: Int, message: String)
    func onJoinLS(state: Int, message: String)
}

public protocol VideoCallDelegate: NSObjectProtocol {
    func onInitiateVideoCall(destination:String,state: Int, message: String)
    func onAcceptVideoCall(originator:String,state: Int, message: String)
    func onVideoCallReceiverTerminate(originator:String,state: Int, message: String)
    
}

public protocol PersonInfoDelegate: NSObjectProtocol {
    func onUpdatePersonInfo(state: Int, message: String)
}

public protocol ScreenSharingDelegate: NSObjectProtocol {
    func onStartScreenSharing(state:Int,message:String)
    func onJoinScreenSharing(state:Int,message:String)
}

public protocol CommentDelegate: NSObjectProtocol {
    func onReceiveComment(message: TMessage)
    func onDeleteComment(message: TMessage)
}

public protocol UploadDelegate: NSObjectProtocol {
    func onUploadProgress(fileName: String, progress: Double)
}

public protocol TimelineDelegate: NSObjectProtocol {
    func onPostUpdate(status: String, message: String)
}

public protocol ConnectionDelegate: NSObjectProtocol {
    func connectionStateChanged(userId: String!, deviceId: String, state: Bool)
}

public protocol ConnectDelegate: NSObjectProtocol {
    func onSuccess(userId: String)
    func onFailed(error: String)
}

public enum AppStoryBoard: String {
    
    case Palio = "Palio"
    
    public var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: Bundle.resourceBundle(for: Nexilis.self))
    }
    
}

extension Nexilis: CallDelegate {
    
    func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((Error?) -> Void)? = nil) {
        providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }
    
    public func onIncomingCall(state: Int, message: String) {
        DispatchQueue.main.async {
            let idMe = UserDefaults.standard.string(forKey: "me")!
            let myData = User.getData(pin: idMe)
            let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
            if myData?.offline_mode == "1" {
                API.terminateCall(sParty: nil)
                return
            }
            let deviceId = message.split(separator: ",")[0]
            var isShowAlert: Double?
            let canShow = UIApplication.shared.visibleViewController
            if canShow != nil && !(canShow is UINavigationController) {
                if !(canShow is EditorPersonal) {
                    isShowAlert = 0
                } else {
                    isShowAlert = 1.5
                }
            } else if canShow != nil {
                if canShow is UINavigationController {
                    let canShowNC = canShow as! UINavigationController
                    if !(canShowNC.visibleViewController is EditorPersonal) {
                        isShowAlert = 0
                    } else {
                        isShowAlert = 1.5
                    }
                } else {
                    isShowAlert = 0
                }
            }
            if (state == 21 && message.split(separator: ",")[1] != "joining Ac.room on channel 0") {
                if onGoingCC.isEmpty {
                    let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                    self.displayIncomingCall(uuid: UUID(), handle: String(deviceId), hasVideo: false) { error in
                        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + isShowAlert!, execute: {
                        do {
                            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                            try AVAudioSession.sharedInstance().setMode(.voiceChat)
                            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                        } catch {
                        }
                        let controller = QmeraAudioViewController()
                        controller.user = User.getData(pin: String(deviceId))
                        controller.isOnGoing = true
                        controller.isOutgoing = false
                        controller.modalPresentationStyle = .overCurrentContext
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
                        }
                        API.receiveCCall(sParty: String(deviceId))
                    })
                }
            } else if (state != -3 && state != 21) {
                let fpin = deviceId
                var data: [String: String?] = [:]
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name, last_name, official_account, image_id, device_id, offline_mode, user_type FROM BUDDY where f_pin = '\(fpin)'") {
                        while cursorData.next() {
                            data["f_pin"] = cursorData.string(forColumnIndex: 0)
                            var name = ""
                            if let firstname = cursorData.string(forColumnIndex: 1) {
                                name = firstname
                            }
                            if let lastname = cursorData.string(forColumnIndex: 2) {
                                name = name + " " + lastname
                            }
                            data["name"] = name
                            data["picture"] = cursorData.string(forColumnIndex: 4)
                            data["isOfficial"] = cursorData.string(forColumnIndex: 3)
                            data["deviceId"] = cursorData.string(forColumnIndex: 5)
                            data["isOffline"] = cursorData.string(forColumnIndex: 6)
                            data["user_type"] = cursorData.string(forColumnIndex: 7)
                        }
                        cursorData.close()
                    }
                })
                let videoController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                videoController.dataPerson.append(data)
                videoController.isInisiator = false
                if !onGoingCC.isEmpty {
                    videoController.users.append(User.getData(pin: data["f_pin"]!!)!)
                }
                let navigationController = UINavigationController(rootViewController: videoController)
                navigationController.modalPresentationStyle = .custom
                if !onGoingCC.isEmpty {
                    videoController.isAutoAccept = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + isShowAlert!, execute: {
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                        }
                    })
                } else {
                    if UIApplication.shared.visibleViewController?.navigationController != nil {
                        UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                    } else {
                        UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    public func onStatusCall(state: Int, message: String) {
        let r = message.split(separator: ",")
        if state == 23 {
            if let call = callManager.call(with: String(r[0])) {
                print("onStatusCall:connectingCall")
                DispatchQueue.main.async {
                    call.connectingCall()
                }
            }
        } else if state == 22 {
            if let call = callManager.call(with: String(r[1])) {
                print("onStatusCall:answerCall")
                DispatchQueue.main.async {
                    call.answerCall()
                }
            }
        }
        var dataCall: [AnyHashable : Any] = [:]
        dataCall["state"] = state
        dataCall["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onStatusCall"), object: nil, userInfo: dataCall)
    }
    
}

var previewItem : NSURL?

extension Nexilis: MessageDelegate {
    public func onReceiveComment(message: TMessage) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onReceiveComment"), object: nil, userInfo: dataMessage)
    }
    
    @objc func tapLinkBroadcast(_ sender: ObjectGesture) {
        var stringURl = sender.message_id.lowercased()
        if stringURl.starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        guard let url = URL(string: stringURl) else { return }
        UIApplication.shared.open(url)
    }
    
    func showBroadcastMessage(m: [String: String]) {
        let fileType = m[CoreMessage_TMessageKey.CATEGORY_FLAG]!
        let broadcastVC = UIViewController()
        if let viewBroadcast = broadcastVC.view {
            broadcastVC.modalPresentationStyle = .custom
            viewBroadcast.backgroundColor = .black.withAlphaComponent(0.3)
            
            let stringLink = m[CoreMessage_TMessageKey.LINK] ?? ""
            
            let containerView = UIView()
            viewBroadcast.addSubview(containerView)
            if stringLink.isEmpty {
                containerView.anchor(centerX: viewBroadcast.centerXAnchor, centerY: viewBroadcast.centerYAnchor, width: viewBroadcast.bounds.width - 40, minHeight: 100, maxHeight: viewBroadcast.bounds.height - 100)
            } else {
                containerView.anchor(centerX: viewBroadcast.centerXAnchor, centerY: viewBroadcast.centerYAnchor, width: viewBroadcast.bounds.width - 40, minHeight: 200, maxHeight: viewBroadcast.bounds.height - 100)
            }
            containerView.backgroundColor = .white.withAlphaComponent(0.9)
            containerView.layer.cornerRadius = 15.0
            containerView.clipsToBounds = true
            
            let subContainerView = UIView()
            subContainerView.backgroundColor = .clear
            containerView.addSubview(subContainerView)
            subContainerView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 20.0, paddingLeft: 10.0, paddingBottom: 20.0, paddingRight: 10.0)
            
            let buttonClose = UIButton(type: .close)
            buttonClose.frame.size = CGSize(width: 30, height: 30)
            buttonClose.layer.cornerRadius = 15.0
            buttonClose.clipsToBounds = true
            buttonClose.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
            buttonClose.actionHandle(controlEvents: .touchUpInside,
             ForAction:{() -> Void in
                broadcastVC.dismiss(animated: true, completion: {
                    Nexilis.broadcastList.remove(at: 0)
                    if Nexilis.broadcastList.count > 0 {
                        Nexilis.shared.showBroadcastMessage(m: Nexilis.broadcastList[0])
                    }
                })
             })
            containerView.addSubview(buttonClose)
            buttonClose.anchor(top: containerView.topAnchor, right: containerView.rightAnchor, width: 30, height: 30)
            
            let title = UILabel()
            title.font = .systemFont(ofSize: 18, weight: .bold)
            title.text = m["MERNAM"]
            title.textAlignment = .center
            subContainerView.addSubview(title)
            title.anchor(top: subContainerView.topAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor)
            
            let titleBroadcast = UILabel()
            subContainerView.addSubview(titleBroadcast)
            titleBroadcast.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleBroadcast.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 20.0),
                titleBroadcast.leadingAnchor.constraint(equalTo: subContainerView.leadingAnchor),
                titleBroadcast.trailingAnchor.constraint(equalTo: subContainerView.trailingAnchor),
            ])
            titleBroadcast.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            titleBroadcast.numberOfLines = 0
            titleBroadcast.attributedText = m[CoreMessage_TMessageKey.TITLE]!.richText()
            titleBroadcast.textColor = .black
            
            let descBroadcast = UILabel()
            subContainerView.addSubview(descBroadcast)
            descBroadcast.translatesAutoresizingMaskIntoConstraints = false
            let constraintDesc = descBroadcast.bottomAnchor.constraint(equalTo: subContainerView.bottomAnchor)
            if !stringLink.isEmpty{
                constraintDesc.constant = constraintDesc.constant - 30
            }
            if fileType != BroadcastViewController.FILE_TYPE_CHAT {
                constraintDesc.constant = constraintDesc.constant - 260
            }
            NSLayoutConstraint.activate([
                descBroadcast.topAnchor.constraint(equalTo: titleBroadcast.bottomAnchor, constant: 10),
                descBroadcast.leadingAnchor.constraint(equalTo: subContainerView.leadingAnchor),
                descBroadcast.trailingAnchor.constraint(equalTo: subContainerView.trailingAnchor),
                constraintDesc,
            ])
            descBroadcast.font = UIFont.systemFont(ofSize: 12)
            descBroadcast.numberOfLines = 0
            descBroadcast.attributedText = m[CoreMessage_TMessageKey.MESSAGE_TEXT_ENG]!.richText()
            descBroadcast.textColor = .black
            
            let linkBroadcast = UILabel()
            if !stringLink.isEmpty {
                subContainerView.addSubview(linkBroadcast)
                linkBroadcast.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    linkBroadcast.topAnchor.constraint(equalTo: descBroadcast.bottomAnchor, constant: 10),
                    linkBroadcast.leadingAnchor.constraint(equalTo: subContainerView.leadingAnchor),
                    linkBroadcast.trailingAnchor.constraint(equalTo: subContainerView.trailingAnchor),
                ])
                linkBroadcast.font = UIFont.systemFont(ofSize: 12)
                linkBroadcast.isUserInteractionEnabled = true
                linkBroadcast.numberOfLines = 2
                let attributedString = NSMutableAttributedString(string: stringLink, attributes:[NSAttributedString.Key.link: URL(string: stringLink)!])
                linkBroadcast.attributedText = attributedString
                let tap = ObjectGesture(target: self, action: #selector(tapLinkBroadcast))
                tap.message_id = stringLink
                linkBroadcast.addGestureRecognizer(tap)
            }
            
            let thumb = m[CoreMessage_TMessageKey.THUMB_ID] ?? ""
            let image = m[CoreMessage_TMessageKey.IMAGE_ID] ?? ""
            let video = m[CoreMessage_TMessageKey.VIDEO_ID] ?? ""
            let file = m[CoreMessage_TMessageKey.FILE_ID] ?? ""
            if fileType != BroadcastViewController.FILE_TYPE_CHAT {
                let imageBroadcast = UIImageView()
                subContainerView.addSubview(imageBroadcast)
                imageBroadcast.translatesAutoresizingMaskIntoConstraints = false
                var constImage = imageBroadcast.topAnchor.constraint(equalTo: descBroadcast.bottomAnchor, constant: 10)
                if !stringLink.isEmpty {
                    constImage = imageBroadcast.topAnchor.constraint(equalTo: linkBroadcast.bottomAnchor, constant: 10)
                }
                NSLayoutConstraint.activate([
                    constImage,
                    imageBroadcast.leadingAnchor.constraint(equalTo: subContainerView.leadingAnchor),
                    imageBroadcast.trailingAnchor.constraint(equalTo: subContainerView.trailingAnchor),
                    imageBroadcast.heightAnchor.constraint(equalToConstant: 250)
                ])
                imageBroadcast.layer.cornerRadius = 10.0
                imageBroadcast.clipsToBounds = true
                if fileType != BroadcastViewController.FILE_TYPE_DOCUMENT {
                    imageBroadcast.contentMode = .scaleAspectFill
                    imageBroadcast.setImage(name: thumb)
            
                    if fileType == BroadcastViewController.FILE_TYPE_VIDEO {
                        let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                        imageBroadcast.addSubview(imagePlay)
                        imagePlay.clipsToBounds = true
                        imagePlay.translatesAutoresizingMaskIntoConstraints = false
                        imagePlay.centerYAnchor.constraint(equalTo: imageBroadcast.centerYAnchor).isActive = true
                        imagePlay.centerXAnchor.constraint(equalTo: imageBroadcast.centerXAnchor).isActive = true
                        imagePlay.widthAnchor.constraint(equalToConstant: 60).isActive = true
                        imagePlay.heightAnchor.constraint(equalToConstant: 60).isActive = true
                        imagePlay.tintColor = .gray.withAlphaComponent(0.5)
                    }
                } else {
                    imageBroadcast.image = UIImage(systemName: "doc.fill")
                    imageBroadcast.tintColor = .mainColor
                    imageBroadcast.contentMode = .scaleAspectFit
                }
            
                imageBroadcast.actionHandle(controlEvents: .touchUpInside,
                 ForAction:{() -> Void in
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if fileType == BroadcastViewController.FILE_TYPE_IMAGE {
                        if let dirPath = paths.first {
                            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(image)
                            if FileManager.default.fileExists(atPath: imageURL.path) {
                                let image    = UIImage(contentsOfFile: imageURL.path)
                                let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                                previewImageVC.image = image
                                previewImageVC.isHiddenTextField = true
                                previewImageVC.modalPresentationStyle = .overFullScreen
                                previewImageVC.modalTransitionStyle  = .crossDissolve
                                if UIApplication.shared.visibleViewController?.navigationController != nil {
                                    UIApplication.shared.visibleViewController?.navigationController?.present(previewImageVC, animated: true, completion: nil)
                                } else {
                                    UIApplication.shared.visibleViewController?.present(previewImageVC, animated: true, completion: nil)
                                }
                            } else {
                                Download().start(forKey: image) { (name, progress) in
                                    guard progress == 100 else {
                                        return
                                    }
            
                                    DispatchQueue.main.async {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                                        previewImageVC.image = image
                                        previewImageVC.isHiddenTextField = true
                                        previewImageVC.modalPresentationStyle = .overFullScreen
                                        previewImageVC.modalTransitionStyle  = .crossDissolve
                                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                                            UIApplication.shared.visibleViewController?.navigationController?.present(previewImageVC, animated: true, completion: nil)
                                        } else {
                                            UIApplication.shared.visibleViewController?.present(previewImageVC, animated: true, completion: nil)
                                        }
                                    }
                                }
                            }
                        }
                    } else if fileType == BroadcastViewController.FILE_TYPE_VIDEO {
                        //https://qmera.io/filepalio/image/
                        let player = AVPlayer(url: URL(string: "https://qmera.io/filepalio/image/\(video)")!)
                        let playerVC = AVPlayerViewController()
                        playerVC.player = player
                        playerVC.modalPresentationStyle = .custom
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(playerVC, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(playerVC, animated: true, completion: nil)
                        }
                    } else if fileType == BroadcastViewController.FILE_TYPE_DOCUMENT {
                        if let dirPath = paths.first {
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
                            if FileManager.default.fileExists(atPath: fileURL.path) {
                                previewItem = fileURL as NSURL
                                let previewController = QLPreviewController()
                                let rightBarButton = UIBarButtonItem()
                                previewController.navigationItem.rightBarButtonItem = rightBarButton
                                previewController.dataSource = self
                                previewController.modalPresentationStyle = .overFullScreen
            
                                if UIApplication.shared.visibleViewController?.navigationController != nil {
                                    UIApplication.shared.visibleViewController?.navigationController?.present(previewController, animated: true, completion: nil)
                                } else {
                                    UIApplication.shared.visibleViewController?.present(previewController, animated: true, completion: nil)
                                }
                            } else {
                                Download().start(forKey: file) { (name, progress) in
                                    DispatchQueue.main.async {
                                        guard progress == 100 else {
                                            return
                                        }
                                        previewItem = fileURL as NSURL
                                        let previewController = QLPreviewController()
                                        let rightBarButton = UIBarButtonItem()
                                        previewController.navigationItem.rightBarButtonItem = rightBarButton
                                        previewController.dataSource = self
                                        previewController.modalPresentationStyle = .overFullScreen
            
                                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                                            UIApplication.shared.visibleViewController?.navigationController?.present(previewController, animated: true, completion: nil)
                                        } else {
                                            UIApplication.shared.visibleViewController?.present(previewController, animated: true, completion: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                 })
            }
            broadcastVC.modalTransitionStyle = .crossDissolve
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(broadcastVC, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(broadcastVC, animated: true, completion: nil)
            }
        }
    }
    
    public func onReceive(message: TMessage) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onReceiveChat"), object: nil, userInfo: dataMessage)
        if message.getCode() == CoreMessage_TMessageCode.PUSH_CALL_CENTER {
            DispatchQueue.main.async {
                if Nexilis.onGoingPushCC.isEmpty {
                    var data: [String: String] = [:]
                    data["channel"] = message.getBody(key: CoreMessage_TMessageKey.CHANNEL)
                    data["l_pin"] = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
                    data["f_display_name"] = message.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME)
                    Nexilis.onGoingPushCC = data
                } else if Nexilis.onGoingPushCC["f_display_name"] == message.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME) {
                    return
                }
                let alert = UIAlertController(title: "", message: "\n\n\n\n\n\n\n\n\n\n".localized(), preferredStyle: .alert)
                let newWidth = UIScreen.main.bounds.width * 0.90 - 270
                // update width constraint value for main view
                if let viewWidthConstraint = alert.view.constraints.filter({ return $0.firstAttribute == .width }).first{
                    viewWidthConstraint.constant = newWidth
                }
                // update width constraint value for container view
                if let containerViewWidthConstraint = alert.view.subviews.first?.constraints.filter({ return $0.firstAttribute == .width }).first {
                    containerViewWidthConstraint.constant = newWidth
                }
                let titleFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.black]
                let titleAttrString = NSMutableAttributedString(string: "Call Center".localized(), attributes: titleFont)
                alert.setValue(titleAttrString, forKey: "attributedTitle")
                alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = .lightGray
                alert.view.tintColor = .black
                let rejectAction = UIAlertAction(title: "Pass to other representative".localized(), style: .destructive, handler: {(_) in
                    DispatchQueue.global().async {
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: message.getBody(key: CoreMessage_TMessageKey.CHANNEL), l_pin: message.getBody(key: CoreMessage_TMessageKey.L_PIN)))
                    }
                    Nexilis.onGoingPushCC.removeAll()
                    alert.dismiss(animated: true, completion: nil)
                })
                let acceptAction = UIAlertAction(title: "I'll handle the customer".localized(), style: .default, handler: {(_) in
                    let goAudioCall = Nexilis.checkMicPermission()
                    if !goAudioCall && message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "1" {
                        let alert = UIAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
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
                        DispatchQueue.global().async {
                            DispatchQueue.global().async {
                                _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: message.getBody(key: CoreMessage_TMessageKey.CHANNEL), l_pin: message.getBody(key: CoreMessage_TMessageKey.L_PIN)))
                            }
                        }
                        Nexilis.onGoingPushCC.removeAll()
                        return
                    }
                    if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "2" {
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
                            DispatchQueue.global().async {
                                DispatchQueue.global().async {
                                    _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: message.getBody(key: CoreMessage_TMessageKey.CHANNEL), l_pin: message.getBody(key: CoreMessage_TMessageKey.L_PIN)))
                                }
                            }
                            Nexilis.onGoingPushCC.removeAll()
                            return
                        }
                    }
                    if UIApplication.shared.visibleViewController is UINavigationController {
                        let nc = UIApplication.shared.visibleViewController as! UINavigationController
                        if nc.visibleViewController is QmeraStreamingViewController {
                            let vc = nc.visibleViewController as! QmeraStreamingViewController
                            var alert = UIAlertController(title: "", message: "Are you sure you want to end Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                            if !vc.isLive {
                                alert = UIAlertController(title: "", message: "Are you sure you want to leave Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                            }
                            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: { _ in
                                DispatchQueue.global().async {
                                    _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: message.getBody(key: CoreMessage_TMessageKey.CHANNEL), l_pin: message.getBody(key: CoreMessage_TMessageKey.L_PIN)))
                                }
                                Nexilis.onGoingPushCC.removeAll()
                                alert.dismiss(animated: true, completion: nil)
                            }))
                            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: { _ in
                                DispatchQueue.global().async {
                                    API.terminateBC(sBroadcasterID: vc.isLive ? nil : vc.data)
                                    vc.sendLeft()
                                }
                                vc.dismiss(animated: true, completion: {
                                    acceptCC()
                                })
                            }))
                            nc.present(alert, animated: true, completion: nil)
//                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "isRunningStreaming"), object: nil, userInfo: dataMessage)
                        } else {
                            acceptCC()
                        }
                    } else {
                        acceptCC()
                    }
                    func acceptCC() {
                        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptRequestCallCenter(channel: message.getBody(key: CoreMessage_TMessageKey.CHANNEL), l_pin: message.getBody(key: CoreMessage_TMessageKey.L_PIN), complaint_id: message.getBody(key: CoreMessage_TMessageKey.DATA))) {
                            if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                                Nexilis.onGoingPushCC.removeAll()
                                let complaintId = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                                if !complaintId.isEmpty {
                                    alert.dismiss(animated: true, completion: nil)
                                    let idMe = UserDefaults.standard.string(forKey: "me")!
                                    UserDefaults.standard.set("\(message.getBody(key: CoreMessage_TMessageKey.L_PIN)),\(idMe),\(complaintId)", forKey: "onGoingCC")
                                    UserDefaults.standard.set("\(message.getBody(key: CoreMessage_TMessageKey.L_PIN))", forKey: "membersCC")
                                    if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "0" {
                                        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                                        editorPersonalVC.isContactCenter = true
                                        editorPersonalVC.isRequestContactCenter = false
                                        editorPersonalVC.unique_l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
                                        editorPersonalVC.complaintId = complaintId
                                        editorPersonalVC.channelContactCenter = message.getBody(key: CoreMessage_TMessageKey.CHANNEL)
                                        editorPersonalVC.fPinContacCenter = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
                                        let navigationController = UINavigationController(rootViewController: editorPersonalVC)
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
                                        UserDefaults.standard.set("\(Date().currentTimeMillis())", forKey: "startTimeCC")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                            if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "1" {
                                                let pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
                                                let controller = QmeraAudioViewController()
                                                controller.user = User.getData(pin: pin)
                                                controller.isOutgoing = true
                                                controller.modalPresentationStyle = .overCurrentContext
                                                let navigationController = UINavigationController(rootViewController: controller)
                                                navigationController.modalPresentationStyle = .custom
                                                if UIApplication.shared.visibleViewController?.navigationController != nil {
                                                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                                                } else {
                                                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                                                }
                                            } else if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "2" {
                                                let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                                                videoVC.fPin = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
                                                videoVC.users.append(User.getData(pin: message.getBody(key: CoreMessage_TMessageKey.L_PIN))!)
                                                let navigationController = UINavigationController(rootViewController: videoVC)
                                                navigationController.modalPresentationStyle = .custom
                                                if UIApplication.shared.visibleViewController?.navigationController != nil {
                                                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                                                } else {
                                                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                                                }
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    }
                })
                alert.addAction(acceptAction)
                alert.addAction(rejectAction)
                
                let containerView = UIView(frame: CGRect(x: 20, y: 60, width: alert.view.bounds.size.width * 0.9 - 40, height: 150))
                alert.view.addSubview(containerView)
                containerView.layer.cornerRadius = 10.0
                containerView.clipsToBounds = true
                containerView.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
                
                let imageProfile = UIImageView()
                containerView.addSubview(imageProfile)
                imageProfile.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageProfile.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
                    imageProfile.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
                    imageProfile.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
                    imageProfile.widthAnchor.constraint(equalToConstant: 100)
                ])
                imageProfile.layer.cornerRadius = 10.0
                imageProfile.clipsToBounds = true
                imageProfile.backgroundColor = .lightGray.withAlphaComponent(0.3)
                imageProfile.tintColor = .secondaryColor
                imageProfile.image = UIImage(systemName: "person")
                if message.getBody(key: CoreMessage_TMessageKey.THUMB_ID) != "" {
                    imageProfile.setImage(name: message.getBody(key: CoreMessage_TMessageKey.THUMB_ID))
                    imageProfile.contentMode = .scaleAspectFill
                }
                
                let labelName = UILabel()
                containerView.addSubview(labelName)
                labelName.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelName.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
                    labelName.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                labelName.font = UIFont.systemFont(ofSize: 12)
                labelName.text = "Name".localized()
                labelName.textColor = .mainColor
                
                let valueName = UILabel()
                containerView.addSubview(valueName)
                valueName.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    valueName.topAnchor.constraint(equalTo: labelName.bottomAnchor),
                    valueName.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                valueName.font = UIFont.systemFont(ofSize: 12)
                valueName.text = message.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME)
                valueName.textColor = .mainColor
                
                let labelType = UILabel()
                containerView.addSubview(labelType)
                labelType.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelType.topAnchor.constraint(equalTo: valueName.bottomAnchor, constant: 5),
                    labelType.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                labelType.font = UIFont.systemFont(ofSize: 12)
                labelType.text = "Request Type".localized()
                labelType.textColor = .mainColor
                
                let valueType = UILabel()
                containerView.addSubview(valueType)
                valueType.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    valueType.topAnchor.constraint(equalTo: labelType.bottomAnchor),
                    valueType.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                valueType.font = UIFont.systemFont(ofSize: 12)
                if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "0" {
                    valueType.text = "Chat".localized()
                } else if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "1" {
                    valueType.text = "Audio Call".localized()
                } else if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "2" {
                    valueType.text = "Video Call".localized()
                } else {
                    valueType.text = "Email".localized()
                }
                valueType.textColor = .mainColor
                
                let labelIdentity = UILabel()
                containerView.addSubview(labelIdentity)
                labelIdentity.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelIdentity.topAnchor.constraint(equalTo: valueType.bottomAnchor, constant: 5),
                    labelIdentity.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                labelIdentity.font = UIFont.systemFont(ofSize: 12)
                labelIdentity.text = "Complaint ID".localized()
                labelIdentity.textColor = .mainColor
                
                let valueIdentity = UILabel()
                containerView.addSubview(valueIdentity)
                valueIdentity.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    valueIdentity.topAnchor.constraint(equalTo: labelIdentity.bottomAnchor),
                    valueIdentity.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5),
                    valueIdentity.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
                ])
                valueIdentity.font = UIFont.systemFont(ofSize: 12)
                valueIdentity.text = message.getBody(key: CoreMessage_TMessageKey.DATA)
                valueIdentity.numberOfLines = 0
                valueIdentity.textColor = .mainColor
                
                var isShowAlert: Int?
                let canShow = UIApplication.shared.visibleViewController
                if canShow != nil && !(canShow is UINavigationController) {
                    if !(canShow is EditorPersonal) && !(canShow is QmeraAudioViewController) && !(canShow is QmeraVideoViewController) {
                        isShowAlert = 0
                    } else {
                        isShowAlert = 3
                    }
                } else if canShow != nil {
                    if canShow is UINavigationController {
                        let canShowNC = canShow as! UINavigationController
                        if !(canShowNC.visibleViewController is EditorPersonal) && !(canShowNC.visibleViewController is QmeraAudioViewController) && !(canShowNC.visibleViewController is QmeraVideoViewController) {
                            isShowAlert = 0
                        } else {
                            isShowAlert = 3
                        }
                    } else {
                        isShowAlert = 0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(isShowAlert!), execute: {
                    if UIApplication.shared.visibleViewController?.navigationController != nil {
                        UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                    } else {
                        UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                    }
                })
            }
        } else if message.getCode() == CoreMessage_TMessageCode.ACCEPT_CALL_CENTER {
            let fPinContacCenter = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
            let requester = message.getBody(key: CoreMessage_TMessageKey.UPLINE_PIN)
            let complaintId = message.getBody(key: CoreMessage_TMessageKey.DATA)
            if !requester.isEmpty {
                UserDefaults.standard.set("\(requester),\(fPinContacCenter),\(complaintId)", forKey: "onGoingCC")
                UserDefaults.standard.set("\(fPinContacCenter)", forKey: "membersCC")
            }
        } else if message.getCode() == CoreMessage_TMessageCode.INVITE_TO_ROOM_CONTACT_CENTER {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "", message: "\n\n\n\n\n\n\n\n\n\n".localized(), preferredStyle: .alert)
                let newWidth = UIScreen.main.bounds.width * 0.90 - 270
                // update width constraint value for main view
                if let viewWidthConstraint = alert.view.constraints.filter({ return $0.firstAttribute == .width }).first{
                    viewWidthConstraint.constant = newWidth
                }
                // update width constraint value for container view
                if let containerViewWidthConstraint = alert.view.subviews.first?.constraints.filter({ return $0.firstAttribute == .width }).first {
                    containerViewWidthConstraint.constant = newWidth
                }
                let titleFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.black]
                let titleAttrString = NSMutableAttributedString(string: "You're invited to\nCall Center".localized(), attributes: titleFont)
                alert.setValue(titleAttrString, forKey: "attributedTitle")
                alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = .lightGray
                alert.view.tintColor = .black
                let rejectAction = UIAlertAction(title: "Reject".localized(), style: .destructive, handler: {(_) in
                    DispatchQueue.global().async {
                        if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: message.getPIN(), type: 0, ticket_id: message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID))) {
                            if result.isOk() {
                                return
                            }
                        }
                    }
                    alert.dismiss(animated: true, completion: nil)
                })
                let acceptAction = UIAlertAction(title: "Accept".localized(), style: .default, handler: {(_) in
                    let goAudioCall = Nexilis.checkMicPermission()
                    if !goAudioCall && message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "1" {
                        let alert = UIAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
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
                        DispatchQueue.global().async {
                            if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: message.getPIN(), type: 0, ticket_id: message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID))) {
                                if result.isOk() {
                                    return
                                }
                            }
                        }
                        return
                    }
                    if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "2" {
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
                            DispatchQueue.global().async {
                                if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: message.getPIN(), type: 0, ticket_id: message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID))) {
                                    if result.isOk() {
                                        return
                                    }
                                }
                            }
                            return
                        }
                    }
                    if UIApplication.shared.visibleViewController is UINavigationController {
                        let nc = UIApplication.shared.visibleViewController as! UINavigationController
                        if nc.visibleViewController is QmeraStreamingViewController {
                            let vc = nc.visibleViewController as! QmeraStreamingViewController
                            var alert = UIAlertController(title: "", message: "Are you sure you want to end Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                            if !vc.isLive {
                                alert = UIAlertController(title: "", message: "Are you sure you want to leave Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                            }
                            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: { _ in
                                DispatchQueue.global().async {
                                    if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: message.getPIN(), type: 0, ticket_id: message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID))) {
                                        if result.isOk() {
                                            return
                                        }
                                    }
                                }
                                alert.dismiss(animated: true, completion: nil)
                            }))
                            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: { _ in
                                DispatchQueue.global().async {
                                    API.terminateBC(sBroadcasterID: vc.isLive ? nil : vc.data)
                                    vc.sendLeft()
                                }
                                vc.dismiss(animated: true, completion: {
                                    acceptCC()
                                })
                            }))
                            nc.present(alert, animated: true, completion: nil)
                        } else {
                            acceptCC()
                        }
                    } else {
                        acceptCC()
                    }
                    func acceptCC() {
                        if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: message.getPIN(), type: 1, ticket_id: message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID))) {
                            if result.isOk() {
                                let requester = result.getBody(key: CoreMessage_TMessageKey.UPLINE_PIN)
                                let officer = result.getBody(key: CoreMessage_TMessageKey.FRIEND_FPIN)
                                let data = result.getBody(key: CoreMessage_TMessageKey.DATA)
                                let complaintId = message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID)
                                UserDefaults.standard.set("\(requester),\(officer),\(complaintId)", forKey: "onGoingCC")
                                UserDefaults.standard.set("\(Date().currentTimeMillis())", forKey: "startTimeCC")
                                if !data.isEmpty {
                                    if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                                        var members = ""
                                        var user : [User] = []
                                        let idMe = UserDefaults.standard.string(forKey: "me")!
                                        for json in jsonArray {
                                            if "\(json)" != idMe {
                                                if members.isEmpty {
                                                    members = "\(json)"
                                                } else {
                                                    members += ",\(json)"
                                                }
                                                if let userData = User.getData(pin: "\(json)") {
                                                    user.append(userData)
                                                } else {
                                                    Nexilis.addFriend (fpin: "\(json)") { result in
                                                        DispatchQueue.main.async {
                                                            if result {
                                                                let userData = User.getData(pin: "\(json)")!
                                                                user.append(userData)
                                                            } else {
                                                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                                                imageView.tintColor = .white
                                                                let banner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                                                banner.show()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        UserDefaults.standard.set("\(members)", forKey: "membersCC")
                                        if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "0" {
                                            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                                            editorPersonalVC.hidesBottomBarWhenPushed = true
                                            editorPersonalVC.unique_l_pin = officer
                                            editorPersonalVC.fromNotification = true
                                            editorPersonalVC.isContactCenter = true
                                            editorPersonalVC.fPinContacCenter = members
                                            editorPersonalVC.complaintId = complaintId
                                            editorPersonalVC.onGoingCC = true
                                            editorPersonalVC.isRequestContactCenter = false
                                            editorPersonalVC.users = user
                                            let navigationController = UINavigationController(rootViewController: editorPersonalVC)
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
                                    }
                                }
                            } else {
                                let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        }
                    }
                })
                alert.addAction(rejectAction)
                alert.addAction(acceptAction)
                
                let containerView = UIView(frame: CGRect(x: 50, y: 80, width: alert.view.bounds.size.width * 0.9 - 100, height: 150))
                alert.view.addSubview(containerView)
                containerView.layer.cornerRadius = 10.0
                containerView.clipsToBounds = true
                containerView.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
                
                let userData = User.getData(pin: message.getPIN())
                
                let imageProfile = UIImageView()
                containerView.addSubview(imageProfile)
                imageProfile.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageProfile.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
                    imageProfile.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
                    imageProfile.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
                    imageProfile.widthAnchor.constraint(equalToConstant: 100)
                ])
                imageProfile.layer.cornerRadius = 10.0
                imageProfile.clipsToBounds = true
                imageProfile.backgroundColor = .lightGray.withAlphaComponent(0.3)
                imageProfile.tintColor = .secondaryColor
                imageProfile.image = UIImage(systemName: "person")
                if userData!.thumb != "" {
                    imageProfile.setImage(name: userData!.thumb)
                    imageProfile.contentMode = .scaleAspectFill
                }
                
                let labelName = UILabel()
                containerView.addSubview(labelName)
                labelName.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelName.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
                    labelName.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                labelName.font = UIFont.systemFont(ofSize: 12)
                labelName.text = "Name".localized()
                labelName.textColor = .mainColor
                
                let valueName = UILabel()
                containerView.addSubview(valueName)
                valueName.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    valueName.topAnchor.constraint(equalTo: labelName.bottomAnchor),
                    valueName.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                valueName.font = UIFont.systemFont(ofSize: 12)
                valueName.text = userData!.fullName
                valueName.textColor = .mainColor
                
                let labelType = UILabel()
                containerView.addSubview(labelType)
                labelType.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelType.topAnchor.constraint(equalTo: valueName.bottomAnchor, constant: 5),
                    labelType.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                labelType.font = UIFont.systemFont(ofSize: 12)
                labelType.text = "Request Type".localized()
                labelType.textColor = .mainColor
                
                let valueType = UILabel()
                containerView.addSubview(valueType)
                valueType.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    valueType.topAnchor.constraint(equalTo: labelType.bottomAnchor),
                    valueType.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                valueType.font = UIFont.systemFont(ofSize: 12)
                if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "0" {
                    valueType.text = "Chat".localized()
                } else if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "1" {
                    valueType.text = "Audio Call".localized()
                } else if message.getBody(key: CoreMessage_TMessageKey.CHANNEL) == "2" {
                    valueType.text = "Video Call".localized()
                } else {
                    valueType.text = "Email".localized()
                }
                valueType.textColor = .mainColor
                
                let labelIdentity = UILabel()
                containerView.addSubview(labelIdentity)
                labelIdentity.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelIdentity.topAnchor.constraint(equalTo: valueType.bottomAnchor, constant: 5),
                    labelIdentity.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
                ])
                labelIdentity.font = UIFont.systemFont(ofSize: 12)
                labelIdentity.text = "Complaint ID".localized()
                labelIdentity.textColor = .mainColor
                
                let valueIdentity = UILabel()
                containerView.addSubview(valueIdentity)
                valueIdentity.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    valueIdentity.topAnchor.constraint(equalTo: labelIdentity.bottomAnchor),
                    valueIdentity.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5),
                    valueIdentity.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
                ])
                valueIdentity.font = UIFont.systemFont(ofSize: 12)
                valueIdentity.text = message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID)
                valueIdentity.numberOfLines = 0
                valueIdentity.textColor = .mainColor
                
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                }
            }
        } else if message.getCode() != CoreMessage_TMessageCode.PUSH_CALL_CENTER && message.getCode() != CoreMessage_TMessageCode.ACCEPT_CALL_CENTER && message.getCode() != CoreMessage_TMessageCode.END_CALL_CENTER && message.getCode() != CoreMessage_TMessageCode.TIMEOUT_CONTACT_CENTER && message.getCode() != CoreMessage_TMessageCode.ACCEPT_CONTACT_CENTER && message.getCode() != CoreMessage_TMessageCode.PUSH_MEMBER_ROOM_CONTACT_CENTER && message.getCode() != CoreMessage_TMessageCode.INVITE_END_CONTACT_CENTER && message.getCode() != CoreMessage_TMessageCode.INVITE_EXIT_CONTACT_CENTER || message.mBodies["MERNAM"] != nil {
            let m = message.mBodies
//            if m[CoreMessage_TMessageKey.IS_CALL_CENTER] == "1" {
//                return
//            }
            if message.mBodies["MERNAM"] != nil {
                DispatchQueue.main.async {
                    if !Nexilis.broadcastList.isEmpty {
                        Nexilis.broadcastList.append(m)
                    } else {
                        Nexilis.broadcastList.append(m)
                        Nexilis.shared.showBroadcastMessage(m: m)
                    }
                }
                return
            }
            let sender = m[CoreMessage_TMessageKey.F_PIN]!
            let me = UserDefaults.standard.string(forKey: "me")!
            if(sender != me) {
                let inEditorPersonal = UserDefaults.standard.string(forKey: "inEditorPersonal")
                let inEditorGroup = UserDefaults.standard.stringArray(forKey: "inEditorGroup")
                var text = m["A07"]!
                if (m.keys.contains("A57") && !((m["A57"]!).isEmpty)) {
                    text = "Sent Image 📷"
                } else if (m.keys.contains("A149")) && (m["A149"]!) == "11" {
                    text = "Sent Sticker ❤️"
                } else if (m.keys.contains("A47") && !((m["A47"]!).isEmpty)) {
                    text = "Sent Video 📹"
                } else if (m.keys.contains("BN") && !((m["BN"]!).isEmpty)) {
                    if m["A06"]! == "18" {
                        text = "Sent Form 📄"
                    } else {
                        text = "Sent File 📄"
                    }
                } else if (m.keys.contains("A63") && !((m["A63"]!).isEmpty)) {
                    text = "Sent Audio 🎵"
                } else if ((m["A07"]!).contains("Share%20location%20")) {
                    text = "Sent Location 📌"
                } else if (m.keys.contains("A149")) && (m["A149"]!) == "27" {
                    text = "Sent link Live Streaming"
                } else if (m.keys.contains("A149")) && (m["A149"]!) == "25" {
                    text = "Sent link Video Conference Room"
                } else if (m.keys.contains("A149")) && (m["A149"]!) == "24" {
                    text = "Sent link Quiz"
                }
                var nameUser: String?
                var profile = ""
                var threadIdentifier = sender
                let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
                if !onGoingCC.isEmpty {
                    return
                }
                if(m["A06"]! == "3" || m["A06"]! == "18" || m["A06"]! == "5") {
                    if inEditorPersonal == sender || (inEditorPersonal != nil && inEditorPersonal!.contains(",")) {
                        return
                    }
                    if(nameUser == nil) {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT first_name, last_name, image_id FROM BUDDY WHERE f_pin='\(String(describing: sender))'") {
                                while cursor.next() {
                                    let first_name = cursor.string(forColumnIndex: 0)!
                                    let last_name = cursor.string(forColumnIndex: 1)!
                                    nameUser = "\(first_name) \(last_name)".trimmingCharacters(in: .whitespaces)
                                    profile = cursor.string(forColumnIndex: 2)!
                                }
                                cursor.close()
                            }
                        })
                    }
                } else {
                    let idGroup = m["A01"]!
                    var topicGroup: String?
                    var idTopic: String?
                    if (m.keys.contains("BA")) {
                        idTopic = m["BA"]
                    }
                    if (idTopic == nil) {
                        idTopic = "Lounge"
                        topicGroup = "Lounge"
                    } else {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT title FROM DISCUSSION_FORUM WHERE chat_id='\(idTopic!)'") {
                                while cursor.next() {
                                    let title = cursor.string(forColumnIndex: 0)
                                    topicGroup = title
                                }
                                cursor.close()
                            }
                        })
                    }
                    if (inEditorGroup != nil) {
                        let editorIdGroup = inEditorGroup![0]
                        let editorIdTopic = inEditorGroup![1]
                        var idTempTopic = idTopic
                        if (idTempTopic == "Lounge") {
                            idTempTopic = ""
                        }
                        if (editorIdGroup == idGroup && editorIdTopic == idTempTopic) {
                            return
                        }
                    }
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_name, image_id FROM GROUPZ WHERE group_id='\(idGroup)'") {
                            while cursor.next() {
                                let f_name = cursor.string(forColumnIndex: 0)
                                var senderName = m["BR"]
                                if senderName == nil {
                                    senderName = "Bot"
                                }
                                nameUser =
                                    "\(senderName!) \u{2022} \(f_name!)(\(topicGroup!))"
                                profile = cursor.string(forColumnIndex: 1)!
                            }
                            cursor.close()
                        }
                    })
                    if idTopic == "Lounge" {
                        threadIdentifier = idGroup
                    } else {
                        threadIdentifier = idTopic!
                    }
                }
                if nameUser == nil && threadIdentifier == "-999" {
                    nameUser = "Bot"
                }
                DispatchQueue.main.async {
                    let container = UIView()
                    container.backgroundColor = .gray
                    let profileImage = UIImageView()
                    profileImage.frame.size = CGSize(width: 60, height: 60)
                    container.addSubview(profileImage)
                    profileImage.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        profileImage.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8.0),
                        profileImage.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                        profileImage.widthAnchor.constraint(equalToConstant: 60),
                        profileImage.heightAnchor.constraint(equalToConstant: 60),
                    ])
                    
                    let title = UILabel()
                    container.addSubview(title)
                    title.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        title.leadingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: 8.0),
                        title.topAnchor.constraint(equalTo: container.topAnchor, constant: 20.0),
                    ])
                    title.font = UIFont.systemFont(ofSize: 14)
                    title.text = nameUser ?? "Unknown"
                    title.textColor = .white
                    
                    let subtitle = UILabel()
                    container.addSubview(subtitle)
                    subtitle.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        subtitle.leadingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: 8.0),
                        subtitle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15.0),
                        subtitle.topAnchor.constraint(equalTo: title.bottomAnchor),
                    ])
                    subtitle.font = UIFont.systemFont(ofSize: 12)
                    subtitle.attributedText = text.richText()
                    subtitle.textColor = .white
                    
                    let floating = FloatingNotificationBanner(customView: container)
                    floating.bannerHeight = 100.0
                    floating.transparency = 0.9
                    
                    if threadIdentifier == "-999" {
                        profileImage.image = UIImage(named: "pb_ball", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                    } else if profile != "" {
                        profileImage.circle()
                        do {
                            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                            let file = documentDir.appendingPathComponent(profile)
                            if FileManager().fileExists(atPath: file.path) {
                                profileImage.image = UIImage(contentsOfFile: file.path)
                                profileImage.backgroundColor = .clear
                            } else {
                                Download().start(forKey: profile) { (name, progress) in
                                    guard progress == 100 else {
                                        return
                                    }
                                    
                                    DispatchQueue.main.async {
                                        profileImage.image = UIImage(contentsOfFile: file.path)
                                        profileImage.backgroundColor = .clear
                                        if !onGoingCC.isEmpty {
                                            floating.autoDismiss = false
                                        }
                                        floating.show(queuePosition: .front, bannerPosition: .top, queue: NotificationBannerQueue(maxBannersOnScreenSimultaneously: 1), on: nil, edgeInsets: UIEdgeInsets(top: 8.0, left: 8.0, bottom: 0, right: 8.0), cornerRadius: 8.0, shadowColor: .clear, shadowOpacity: .zero, shadowBlurRadius: .zero, shadowCornerRadius: .zero, shadowOffset: .zero, shadowEdgeInsets: nil)
                                        floating.onTap = {
                                            showNotif()
                                        }
                                    }
                                }
                                return
                            }
                        } catch {}
                        profileImage.contentMode = .scaleAspectFill
                    } else {
                        profileImage.circle()
                        if m["A06"]! == "3" {
                            profileImage.image = UIImage(systemName: "person")
                        } else {
                            profileImage.image = UIImage(systemName: "person.3")
                        }
                        profileImage.contentMode = .scaleAspectFit
                        profileImage.backgroundColor = .lightGray
                        profileImage.tintColor = .white
                    }
                    
                    floating.show(queuePosition: .front, bannerPosition: .top, queue: NotificationBannerQueue(maxBannersOnScreenSimultaneously: 1), on: nil, edgeInsets: UIEdgeInsets(top: 8.0, left: 8.0, bottom: 0, right: 8.0), cornerRadius: 8.0, shadowColor: .clear, shadowOpacity: .zero, shadowBlurRadius: .zero, shadowCornerRadius: .zero, shadowOffset: .zero, shadowEdgeInsets: nil)
                    if !onGoingCC.isEmpty {
                        floating.autoDismiss = false
                    }
                    floating.onTap = {
                        showNotif()
                    }
                    func showNotif() {
                        if !onGoingCC.isEmpty {
                            floating.dismiss()
                        }
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT first_name, last_name FROM BUDDY where f_pin = '\(UserDefaults.standard.string(forKey: "me")!)'"), cursorData.next() {
                                if (cursorData.string(forColumnIndex: 0)! + " " + cursorData.string(forColumnIndex: 1)!).trimmingCharacters(in: .whitespaces) == "USR\(UserDefaults.standard.string(forKey: "me")!)" {
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
                                }
                                cursorData.close()
                                return
                            }
                        })
                        if(m["A06"]! == "3" || m["A06"]! == "5" || m["A06"]! == "18") {
                            func openEditor() {
                                let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                                editorPersonalVC.hidesBottomBarWhenPushed = true
                                editorPersonalVC.unique_l_pin = threadIdentifier
                                editorPersonalVC.fromNotification = true
                                if !onGoingCC.isEmpty {
                                    let compalintId = onGoingCC.components(separatedBy: ",")[2]
                                    let fPinCC = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                                    editorPersonalVC.isContactCenter = true
                                    editorPersonalVC.fPinContacCenter = fPinCC
                                    editorPersonalVC.complaintId = compalintId
                                    editorPersonalVC.onGoingCC = true
                                    editorPersonalVC.isRequestContactCenter = false
                                }
                                let navigationController = UINavigationController(rootViewController: editorPersonalVC)
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
                            if UIApplication.shared.visibleViewController is UINavigationController {
                                let nc = UIApplication.shared.visibleViewController as! UINavigationController
                                if nc.visibleViewController is QmeraStreamingViewController {
                                    let vc = nc.visibleViewController as! QmeraStreamingViewController
                                    var alert = UIAlertController(title: "", message: "Are you sure you want to end Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                                    if !vc.isLive {
                                        alert = UIAlertController(title: "", message: "Are you sure you want to leave Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                                    }
                                    alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
                                    alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: { _ in
                                        DispatchQueue.global().async {
                                            API.terminateBC(sBroadcasterID: vc.isLive ? nil : vc.data)
                                            vc.sendLeft()
                                        }
                                        vc.dismiss(animated: true, completion: {
                                            openEditor()
                                        })
                                    }))
                                    nc.present(alert, animated: true, completion: nil)
//                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "isRunningStreaming"), object: nil, userInfo: dataMessage)
                                } else if nc.visibleViewController is EditorPersonal {
                                    let vc = nc.visibleViewController as! EditorPersonal
                                    if vc.fromNotification {
                                        vc.dismiss(animated: true, completion: {
                                            openEditor()
                                        })
                                    } else {
                                        vc.navigationController?.popViewController(animated: true)
                                        openEditor()
                                    }
                                } else {
                                    openEditor()
                                }
                            } else if UIApplication.shared.visibleViewController is EditorPersonal {
                                let vc = UIApplication.shared.visibleViewController as! EditorPersonal
                                if vc.fromNotification{
                                    vc.dismiss(animated: true, completion: {
                                        openEditor()
                                    })
                                } else {
                                    vc.navigationController?.popViewController(animated: true)
                                    openEditor()
                                }
                            } else {
                                openEditor()
                            }
                        } else {
                            func openEditor() {
                                let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "editorGroupVC") as! EditorGroup
                                editorGroupVC.hidesBottomBarWhenPushed = true
                                editorGroupVC.unique_l_pin = threadIdentifier
                                editorGroupVC.fromNotification = true
                                let navigationController = UINavigationController(rootViewController: editorGroupVC)
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
                            if UIApplication.shared.visibleViewController is UINavigationController {
                                let nc = UIApplication.shared.visibleViewController as! UINavigationController
                                if nc.visibleViewController is QmeraStreamingViewController {
                                    let vc = nc.visibleViewController as! QmeraStreamingViewController
                                    var alert = UIAlertController(title: "", message: "Are you sure you want to end Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                                    if !vc.isLive {
                                        alert = UIAlertController(title: "", message: "Are you sure you want to leave Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                                    }
                                    alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
                                    alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: { _ in
                                        DispatchQueue.global().async {
                                            API.terminateBC(sBroadcasterID: vc.isLive ? nil : vc.data)
                                            vc.sendLeft()
                                        }
                                        vc.dismiss(animated: true, completion: {
                                            openEditor()
                                        })
                                    }))
                                    nc.present(alert, animated: true, completion: nil)
//                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "isRunningStreaming"), object: nil, userInfo: dataMessage)
                                } else if nc.visibleViewController is EditorGroup {
                                    let vc = nc.visibleViewController as! EditorGroup
                                    if vc.fromNotification {
                                        vc.dismiss(animated: true, completion: {
                                            openEditor()
                                        })
                                    } else {
                                        vc.navigationController?.popViewController(animated: true)
                                        openEditor()
                                    }
                                } else {
                                    openEditor()
                                }
                            } else if UIApplication.shared.visibleViewController is EditorGroup {
                                let vc = UIApplication.shared.visibleViewController as! EditorGroup
                                if vc.fromNotification {
                                    vc.dismiss(animated: true, completion: {
                                        openEditor()
                                    })
                                } else {
                                    vc.navigationController?.popViewController(animated: true)
                                    openEditor()
                                }
                            } else {
                                openEditor()
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static func addFriend(fpin: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddFriendQRCode(fpin: fpin)), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    public func onReceive(message: [AnyHashable : Any?]) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onReceiveChat"), object: nil, userInfo: dataMessage)
    }
    
    public func onMessage(message: TMessage) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onMessageChat"), object: nil, userInfo: dataMessage)
    }
    
    public func onUpload(name: String, progress: Double) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["name"] = name
        dataMessage["progress"] = progress
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onUploadChat"), object: nil, userInfo: dataMessage)
    }
    
    public func onTyping(message: TMessage) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onTypingChat"), object: nil, userInfo: dataMessage)
    }
    
    public static func faceDetect(fd: FaceDetector?,image: UIImage, completion: ((Bool) -> ())?){
        print("enter vision")
        let visionImage = VisionImage(image: image)
        print("exit vision")
        var retval = false
        visionImage.orientation = image.imageOrientation
        var fd1 : FaceDetector?
        if(fd == nil){
            fd1 = FaceDetector.faceDetector()
        }
        else {
            fd1 = fd
        }

        // [START detect_faces]
        fd1?.process(visionImage) {faces, error in
            guard error == nil, let faces = faces, !faces.isEmpty else {
              print("faces empty")
                completion?(false)
                return
            }
            if(faces.count > 0){
                print("face count: \(faces.count)")
                retval = true
            }
            completion?(retval)
        }

    }
}

extension Nexilis: GroupDelegate {
    public func onGroup(code: String, f_pin: String, groupId: String) {
        var data: [AnyHashable : Any] = [:]
        data["code"] = code
        data["f_pin"] = f_pin
        data["groupId"] = groupId
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onGroup"), object: nil, userInfo: data)
    }
    
    public func onTopic(code: String, f_pin: String, topicId: String) {
        var data: [AnyHashable : Any] = [:]
        data["code"] = code
        data["f_pin"] = f_pin
        data["topicId"] = topicId
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onTopic"), object: nil, userInfo: data)
    }
    
    public func onMember(code: String, f_pin: String, groupId: String, member: String) {
        var data: [AnyHashable : Any] = [:]
        data["code"] = code
        data["f_pin"] = f_pin
        data["groupId"] = groupId
        data["member"] = member
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onMember"), object: nil, userInfo: data)
    }
    
    
}

extension Nexilis: PersonInfoDelegate {
    public func onUpdatePersonInfo(state: Int, message: String) {
        var data: [AnyHashable : Any] = [:]
        data["state"] = state
        data["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil, userInfo: data)
    }
}

extension Nexilis: QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItem!
    }
}
