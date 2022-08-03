//
//  IncomingThread.swift
//  Runner
//
//  Created by Yayan Dwi on 16/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import UIKit
import NotificationBannerSwift
import nuSDKService

class IncomingThread {
    
    static let `default` = IncomingThread()
    
    private var isRunning = false
    
    private var semaphore = DispatchSemaphore(value: 0)
    
    private var dispatchQueue = DispatchQueue(label: "IncomingThread")
    
    private var queue = [TMessage]()
    
    func addQueue(message: TMessage) {
        queue.append(message)
        semaphore.signal()
    }
    
    func getQueue() -> TMessage {
        while queue.isEmpty || queue.count == 0 {
            semaphore.wait()
        }
        return queue.remove(at: 0)
    }
    
    func run() {
        if (isRunning) {
            return
        }
        isRunning = true
        dispatchQueue.async {
            while self.isRunning {
                self.process(message: self.getQueue())
            }
        }
    }
    
    private func process(message: TMessage) {
        print("incoming process", message.toLogString())
        if message.getCode() == CoreMessage_TMessageCode.LOGIN_FILE {
            loginFile(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_MYSELF || message.getCode() == CoreMessage_TMessageCode.PUSH_MYSELF_ACK || message.getCode() == CoreMessage_TMessageCode.PULL_MYSELF {
            pushMyself(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_BUDDY {
            initBatchBuddy(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.INIT_BATCH_BUDDY {
            initBatchBuddy(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.CHANGE_BATCH_PERSON_INFO {
            initBatchBuddy(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.DELETE_BUDDY {
            deleteBuddy(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.INIT_BATCH_GROUP {
            onInitGroupInfoBatch(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.INIT_BATCH_TOPIC {
            onInitForumInfoBatch(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.UPLOAD_FILE {
            uploadFile(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.SEND_CHAT {
            receiveMessage(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.UPDATE_CTEXT {
            receiveMessageStatus(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_GROUP || message.getCode() == CoreMessage_TMessageCode.PUSH_GROUP_A {
            pushGroup(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_GROUP_MEMBER {
            pushGroupMembers(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_GROUP_MEMBER_BATCH {
            pushGroupMembers(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.CHANGE_GROUP_MEMBER_POSITION {
            changeGroupPosition(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_CHAT {
            onInitForumInfoBatch(message: message, with: true)
        } else if message.getCode() == CoreMessage_TMessageCode.EXIT_GROUP {
            exitGroup(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.CHANGE_GROUP_INFO {
            changeGroupInfo(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.UPDATE_CHAT {
            updateChat(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.DELETE_CHAT {
            deleteChat(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.IMAGE_DOWNLOAD {
            imageDownload(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_LIVE_VIDEO_LIST {
            getLiveVideoList(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.UPDATE_LIVE_VIDEO {
            getLSTitle(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.LIVE_PROFILE_PUSH_LEAVE {
            leftLiveVideo(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.LIVE_PROFILE_PUSH_JOIN {
            joinLivevideo(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.LIVE_PROFILE_EMOTION_GET {
            getLSData(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.DELETE_CTEXT {
            deleteMessage(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.SEND_UPDATE_TYPING {
            sendUpdateTyping(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.LIVE_PROFILE_PUSH_CHAT {
            getLSChat(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.SCREEN_SHARING {
            incomingScreenSharing(message: message, state: 1)
        } else if message.getCode() == CoreMessage_TMessageCode.SCREEN_SHARING_STOP {
            incomingScreenSharing(message: message, state: 88 )
        } else if message.getCode() == CoreMessage_TMessageCode.CHANGE_PERSON_INFO {
            changePersonInfo(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.SEND_COMMENTS {
            receiveComment(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.DELETE_COMMENTS {
            deleteComment(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.BLOCK_BUDDY {
            blockBuddy(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.UNBLOCK_BUDDY {
            blockBuddy(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.SEND_SIGNUP_MSISDN {
            sendMSISDN(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.VERIFY_OTP {
            verifyOTP(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.REMOVE_FRIEND {
            deleteBuddy(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_CALL_CENTER || message.getCode() == CoreMessage_TMessageCode.ACCEPT_CALL_CENTER || message.getCode() == CoreMessage_TMessageCode.END_CALL_CENTER || message.getCode() == CoreMessage_TMessageCode.TIMEOUT_CONTACT_CENTER || message.getCode() == CoreMessage_TMessageCode.INVITE_TO_ROOM_CONTACT_CENTER || message.getCode() == CoreMessage_TMessageCode.ACCEPT_CONTACT_CENTER || message.getCode() == CoreMessage_TMessageCode.PUSH_MEMBER_ROOM_CONTACT_CENTER || message.getCode() == CoreMessage_TMessageCode.INVITE_END_CONTACT_CENTER || message.getCode() == CoreMessage_TMessageCode.INVITE_EXIT_CONTACT_CENTER {
            handleCallCenter(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_DISCUSSION_COMMENT {
            if let delegate = Nexilis.shared.messageDelegate {
                delegate.onReceiveComment(message: message)
            }
            ack(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.APPROVE_FORM {
            onApproveForm(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.END_CALL {
            endCall(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.PUSH_SERVICE_BNI {
            pushServiceBNI(message: message)
        } else {
            print("unprocessed code", message.getCode())
            ack(message: message)
        }
//        case (CoreMessage_TMessageCode.FORM_PUSH_UPDATE):
//                                            onPushForm(msg);
//                                            break;
    }
    
    /**
     *
     */
    
    private func endCall(message: TMessage) {
        if let call = Nexilis.shared.callManager.call(with: message.mPIN) {
            call.isReceiveEnd = true
            DispatchQueue.main.async {
                Nexilis.shared.callManager.end(call: call)
            }
        }
        ack(message: message)
    }
    
    private func onApproveForm(message: TMessage) {
        if let me = UserDefaults.standard.string(forKey: "me") {
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: me))
        }
        ack(message: message)
    }
    
    private func handleCallCenter(message: TMessage) -> Void {
        if let delegate = Nexilis.shared.messageDelegate {
            delegate.onReceive(message: message)
        }
        ack(message: message)
        // TODO: notif call center
    }
    
    private func blockBuddy(message: TMessage) -> Void {
        let l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
        let block = message.getBody(key: CoreMessage_TMessageKey.BLOCK)
        print ("BLOCK INCOMING \(block)")
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                "ex_block" : block
            ], _where: "f_pin = '\(l_pin)'")
        })
        if let delegate = Nexilis.shared.personInfoDelegate {
            var object = [String:String]()
            let encoder = JSONEncoder()
            object["l_pin"] = l_pin
            object["block"] = block
            let data = try! encoder.encode(object)
            delegate.onUpdatePersonInfo(state: 01, message: String(data: data, encoding: .utf8)!)
        }
        ack(message: message)
    }
    
    private func deleteComment(message: TMessage) -> Void {
        if let delegate = Nexilis.shared.commentDelegate {
            delegate.onDeleteComment(message: message)
        }
        ack(message: message)
    }
    
    private func receiveComment(message: TMessage) -> Void {
        if let delegate = Nexilis.shared.commentDelegate {
            delegate.onReceiveComment(message: message)
        }
        ack(message: message)
    }
    
    private func sendUpdateTyping(message: TMessage) -> Void {
        print("update typing \(message)")
        if let delegate = Nexilis.shared.messageDelegate {
            delegate.onTyping(message: message)
        }
        ack(message: message)
    }
    
    private func deleteMessage(message: TMessage) -> Void {
        var messageId = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
        if message.mBodies["message_id"] != nil {
            messageId = message.getBody(key: "message_id")
        }
        let type = message.getBody(key: CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG)
        
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if type == "1" {
                if !messageId.contains("'") {
                    messageId = "'\(messageId)'"
                }
                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                    "message_text" : "🚫 _This message was deleted_",
                    "lock" : "1",
                    "thumb_id" : "",
                    "image_id" : "",
                    "file_id" : "",
                    "audio_id" : "",
                    "video_id" : "",
                    "reff_id" : "",
                    "attachment_flag" : 0,
                    "is_stared" : "0",
                    "credential" : "0",
                    "read_receipts" : "4"
                ], _where: "message_id = \(messageId)")
            }
            if let delegate = Nexilis.shared.messageDelegate {
                delegate.onMessage(message: message)
            }
        })
        ack(message: message)
    }
    
    private func imageDownload(message: TMessage) -> Void {
        let key_filename = message.getBody(key: CoreMessage_TMessageKey.FILE_NAME)
        let key_part_size = message.getBodyAsInteger(key: CoreMessage_TMessageKey.PART_SIZE, default_value: 0)
        let key_part_of = message.getBodyAsInteger(key: CoreMessage_TMessageKey.PART_OF, default_value: 0)
        let key_file_size  = message.getBodyAsInteger(key: CoreMessage_TMessageKey.FILE_SIZE, default_value: 0)
        let media = message.getMedia()
        
        var data = Data(media)
        
        if !key_filename.isEmpty, data.count == 0, let download = Nexilis.getDownload(forKey: key_filename) {
            print("corrupted...", key_filename)
            if let delegate = download.delegate {
                delegate.onDownloadProgress(fileName: key_filename, progress: -1)
            } else if let completion = download.onDownloadProgress {
                completion(key_filename, -1)
            }
            return
        }
        
        if media.count > 0 {
            if key_part_size > 0, let download = Nexilis.getDownload(forKey: key_filename) {
                download.put(part: key_part_of, buffer: Data(media))
                if download.size() == key_file_size {
                    data = download.remove()
                } else {
                    let progress = Double(download.size()) / Double(key_file_size) * 100.0
                    if let delegate = download.delegate {
                        delegate.onDownloadProgress(fileName: key_filename, progress: progress)
                    } else if let completion = download.onDownloadProgress {
                        completion(key_filename, progress)
                    }
                    return
                }
            }
        }
        
        do {
            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let url = documentDir.appendingPathComponent(key_filename)
            print("write file \(url.path)")
            try data.write(to: url, options: .atomic)
            if let download = Nexilis.getDownload(forKey: key_filename) {
                if let delegate = download.delegate {
                    delegate.onDownloadProgress(fileName: key_filename, progress: 100)
                } else if let completion = download.onDownloadProgress {
                    completion(key_filename, 100)
                }
            }
        } catch {
            print(error)
            if let download = Nexilis.getDownload(forKey: key_filename) {
                if let delegate = download.delegate {
                    delegate.onDownloadProgress(fileName: key_filename, progress: -1)
                } else if let completion = download.onDownloadProgress {
                    completion(key_filename, -1)
                }
            }
        }
        ack(message: message)
    }
    
    private func deleteChat(message: TMessage) -> Void {
        let chat_id = message.getBody(key: CoreMessage_TMessageKey.CHAT_ID)
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", _where: "chat_id = '\(chat_id)'")
        })
        if let delegate = Nexilis.shared.groupDelegate {
            delegate.onTopic(code: message.getCode(), f_pin: message.getPIN(), topicId: chat_id)
        }
        ack(message: message)
    }
    
    private func updateChat(message: TMessage) -> Void {
        let chat_id = message.getBody(key: CoreMessage_TMessageKey.CHAT_ID)
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", cvalues: [
                "title" : message.getBody(key: CoreMessage_TMessageKey.TITLE)
            ], _where: "chat_id = '\(chat_id)'")
        })
        if let delegate = Nexilis.shared.groupDelegate {
            delegate.onTopic(code: message.getCode(), f_pin: message.getPIN(), topicId: chat_id)
        }
        ack(message: message)
    }
    
    private func pushServiceBNI(message: TMessage) -> Void {
        let data = message.getBody(key: CoreMessage_TMessageKey.DATA)
        if !data.isEmpty {
            if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        for json in jsonArray {
                            var parent = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PARENT_ID)
                            if parent.isEmpty {
                                parent = "-99"
                            }
                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "SERVICE_BANK", cvalues: [
                                "service_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CATEGORY_ID),
                                "service_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.NAME),
                                "description" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.DESCRIPTION),
                                "parent" : parent,
                                "is_tablet" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PLATFORM)
                            ], replace: true)
                        }
                        ack(message: message)
                    } catch {
                        rollback.pointee = true
                        print(error)
                    }
                })
            }
        }
    }
    
    private func changeGroupInfo(message: TMessage) -> Void {
        let group_id = message.getBody(key: CoreMessage_TMessageKey.GROUP_ID)
        let group_name = message.getBody(key: CoreMessage_TMessageKey.GROUP_NAME)
        let thumb_id = message.getBody(key: CoreMessage_TMessageKey.THUMB_ID)
        let quote = message.getBody(key: CoreMessage_TMessageKey.QUOTE)
        let chat_modifier = message.getBody(key: CoreMessage_TMessageKey.CHAT_MODIFIER)
        let last_update = message.getBody(key: CoreMessage_TMessageKey.LAST_UPDATE)
        let is_open = message.getBody(key: CoreMessage_TMessageKey.IS_OPEN)
        let official = message.getBody(key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT)
        let lvl_edu = message.getBody(key: CoreMessage_TMessageKey.LEVEL_EDU)
        let mtr_edu = message.getBody(key: CoreMessage_TMessageKey.MATERI_EDU)
        let is_edu = message.getBody(key: CoreMessage_TMessageKey.IS_EDUCATION)
        
        var cvalues = [String:String]()
        if (!group_name.isEmpty) { cvalues["f_name"] = group_name }
        if (!thumb_id.isEmpty) { cvalues["image_id"] = thumb_id }
        if (!quote.isEmpty) { cvalues["quote"] = quote }
        if (!chat_modifier.isEmpty) { cvalues["chat_modifier"] = chat_modifier }
        if (!last_update.isEmpty) { cvalues["last_update"] = last_update }
        if (!is_open.isEmpty) { cvalues["is_open"] = is_open }
        if (!official.isEmpty) { cvalues["official"] = official }
        if (!lvl_edu.isEmpty) { cvalues["level_edu"] = official }
        if (!mtr_edu.isEmpty) { cvalues["materi_edu"] = official }
        if (!is_edu.isEmpty) { cvalues["is_education"] = official }
        
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "GROUPZ", cvalues: cvalues, _where: "group_id = '\(group_id)'")
        })
        if let delegate = Nexilis.shared.groupDelegate {
            delegate.onGroup(code: message.getCode(), f_pin: message.getPIN(), groupId: group_id)
        }
        ack(message: message)
    }
    
    private func exitGroup(message: TMessage) -> Void {
        let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        let group_id = message.getBody(key: CoreMessage_TMessageKey.GROUP_ID)
        if let me = UserDefaults.standard.string(forKey: "me"), me == f_pin {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                if let cursorIsEducation = Database.shared.getRecords(fmdb: fmdb, query: "select is_education from GROUPZ where group_id='\(group_id)'"), cursorIsEducation.next() {
                    let is_education = Int(cursorIsEducation.int(forColumnIndex: 0))
                    if (is_education == 3 || is_education == 2 || is_education == 4) {
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", _where: "group_id = '\(group_id)' and f_pin = '\(f_pin)'")
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "l_pin='\(group_id)'")
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(group_id)'")
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select chat_id from DISCUSSION_FORUM where group_id='\(group_id)'") {
                            while cursor.next() {
                                if let chat_id = cursor.string(forColumnIndex: 0) {
                                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(chat_id)'")
                                }
                            }
                            cursor.close()
                        }
                    } else {
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ", _where: "group_id = '\(group_id)'")
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "l_pin='\(group_id)'")
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(group_id)'")
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select chat_id from DISCUSSION_FORUM where group_id='\(group_id)'") {
                            while cursor.next() {
                                if let chat_id = cursor.string(forColumnIndex: 0) {
                                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(chat_id)'")
                                }
                            }
                            cursor.close()
                        }
                        if let cursorSub = Database.shared.getRecords(fmdb: fmdb, query: "select group_id from GROUPZ where parent='\(group_id)'") {
                            while cursorSub.next() {
                                if let subGroup = cursorSub.string(forColumnIndex: 0) {
                                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ", _where: "group_id = '\(subGroup)'")
                                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "l_pin='\(subGroup)'")
                                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(subGroup)'")
                                    if let cursorSubGroupTopic = Database.shared.getRecords(fmdb: fmdb, query: "select chat_id from DISCUSSION_FORUM where group_id='\(subGroup)'") {
                                        while cursorSubGroupTopic.next() {
                                            if let chat_id_sub = cursorSubGroupTopic.string(forColumnIndex: 0) {
                                                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(chat_id_sub)'")
                                            }
                                        }
                                        cursorSubGroupTopic.close()
                                    }
                                }
                            }
                            cursorSub.close()
                        }
                    }
                    cursorIsEducation.close()
                }
            })
        } else {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", _where: "group_id = '\(group_id)' and f_pin = '\(f_pin)'")
            })
        }
        if let delegate = Nexilis.shared.groupDelegate {
            delegate.onMember(code: message.getCode(), f_pin: message.getPIN(), groupId: group_id, member: f_pin)
        }
        ack(message: message)
    }
    
    private func changeGroupPosition(message: TMessage) -> Void {
        let group_id = message.getBody(key: CoreMessage_TMessageKey.GROUP_ID)
        let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        let position = message.getBody(key: CoreMessage_TMessageKey.POSITION)
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", cvalues: [
                "position" : position
            ], _where: "group_id = '\(group_id)' and f_pin = '\(f_pin)'")
        })
        if let delegate = Nexilis.shared.groupDelegate {
            delegate.onMember(code: message.getCode(), f_pin: message.getPIN(), groupId: group_id, member: f_pin)
        }
        ack(message: message)
    }
    
    var listPushGroupMember: [TMessage] = []
    
    private func pushGroupMembers(message: TMessage, isFromIncoming: Bool = true) -> Void {
        let group_id = message.getBody(key: CoreMessage_TMessageKey.GROUP_ID)
        let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        if(f_pin.isEmpty) {
            let data = message.getBody(key: CoreMessage_TMessageKey.DATA)
            if !data.isEmpty {
                if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            for json in jsonArray {
                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", cvalues: [
                                    "group_id" : group_id,
                                    "f_pin" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.F_PIN),
                                    "position" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.POSITION),
                                    "user_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.USER_ID),
                                    "ac" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.AC),
                                    "ac_desc" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.AC_DESC),
                                    "first_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.FIRST_NAME),
                                    "last_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_NAME),
                                    "msisdn" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MSISDN),
                                    "thumb_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.THUMB_ID),
                                    "created_date" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CREATED_DATE)
                                ], replace: true)
                            }
                            if let delegate = Nexilis.shared.groupDelegate {
                                delegate.onMember(code: message.getCode(), f_pin: message.getPIN(), groupId: group_id, member: "")
                            }
                            ack(message: message)
                        } catch {
                            rollback.pointee = true
                            print(error)
                        }
                    })
                }
            }
        } else {
            if isFromIncoming {
                listPushGroupMember.append(message)
            }
            if listPushGroupMember.count == 1 || !isFromIncoming {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        let result = try Database.shared.insertRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", cvalues: [
                            "group_id" : group_id,
                            "f_pin" : f_pin,
                            "position" : message.getBody(key: CoreMessage_TMessageKey.POSITION),
                            "user_id" : message.getBody(key: CoreMessage_TMessageKey.USER_ID),
                            "ac" : message.getBody(key: CoreMessage_TMessageKey.AC),
                            "ac_desc" : message.getBody(key: CoreMessage_TMessageKey.AC_DESC),
                            "first_name" : message.getBody(key: CoreMessage_TMessageKey.FIRST_NAME),
                            "last_name" : message.getBody(key: CoreMessage_TMessageKey.LAST_NAME),
                            "msisdn" : message.getBody(key: CoreMessage_TMessageKey.MSISDN),
                            "thumb_id" : message.getBody(key: CoreMessage_TMessageKey.THUMB_ID),
                            "created_date" : message.getBody(key: CoreMessage_TMessageKey.CREATED_DATE)
                        ], replace: true)
                        if result > 0 {
                            if let delegate = Nexilis.shared.groupDelegate {
                                delegate.onMember(code: message.getCode(), f_pin: message.getPIN(), groupId: group_id, member: f_pin)
                            }
                            self.listPushGroupMember.remove(at: 0)
                            ack(message: message)
                            if listPushGroupMember.count > 0 {
                                dispatchQueue.asyncAfter(deadline: .now() + 1, execute: {
                                    self.pushGroupMembers(message: self.listPushGroupMember[0], isFromIncoming: false)
                                })
                            }
                        }
                    } catch {
                        rollback.pointee = true
                        print(error)
                    }
                })
            }
        }
    }
    
    private func pushGroup(message: TMessage) -> Void {
        let data  = message.getBody(key: CoreMessage_TMessageKey.DATA)
        if !data.isEmpty {
            if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        for json in jsonArray {
                            let group_id = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GROUP_ID)
                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "GROUPZ", cvalues: [
                                "group_id" : group_id,
                                "f_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GROUP_NAME),
                                "scope_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MESSAGE_SCOPE_ID),
                                "image_id": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.THUMB_ID),
                                "quote": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.QUOTE),
                                "last_update" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_UPDATE),
                                "created_by" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CREATED_BY),
                                "created_date" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CREATED_DATE),
                                "ex_block" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.BLOCK),
                                "folder_id" : "",
                                "chat_modifier" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CHAT_MODIFIER),
                                "group_type" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_ORGANIZATION),
                                "parent" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PARENT_ID),
                                "level" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LEVEL),
                                "is_open" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_OPEN),
                                "official" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT),
                                "level_edu" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LEVEL_EDU),
                                "materi_edu" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MATERI_EDU),
                                "is_education" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_EDUCATION)
                            ], replace: true)
                            if let delegate = Nexilis.shared.groupDelegate {
                                delegate.onGroup(code: message.getCode(), f_pin: message.getPIN(), groupId: group_id)
                            }
                        }
                        ack(message: message)
                    } catch {
                        rollback.pointee = true
                        print(error)
                    }
                })
            }
        } else {
            let group_id = message.getBody(key: CoreMessage_TMessageKey.GROUP_ID)
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    let result = try Database.shared.insertRecord(fmdb: fmdb, table: "GROUPZ", cvalues: [
                        "group_id" : group_id,
                        "f_name" : message.getBody(key: CoreMessage_TMessageKey.GROUP_NAME),
                        "scope_id" : message.getBody(key: CoreMessage_TMessageKey.MESSAGE_SCOPE_ID),
                        "image_id": message.getBody(key: CoreMessage_TMessageKey.THUMB_ID),
                        "quote": message.getBody(key: CoreMessage_TMessageKey.QUOTE),
                        "last_update" : message.getBody(key: CoreMessage_TMessageKey.LAST_UPDATE),
                        "created_by" : message.getBody(key: CoreMessage_TMessageKey.CREATED_BY),
                        "created_date" : message.getBody(key: CoreMessage_TMessageKey.CREATED_DATE),
                        "ex_block" : message.getBody(key: CoreMessage_TMessageKey.BLOCK),
                        "folder_id" : "",
                        "chat_modifier" : message.getBody(key: CoreMessage_TMessageKey.CHAT_MODIFIER),
                        "group_type" : message.getBody(key: CoreMessage_TMessageKey.IS_ORGANIZATION),
                        "parent" : message.getBody(key: CoreMessage_TMessageKey.PARENT_ID),
                        "level" : message.getBody(key: CoreMessage_TMessageKey.LEVEL),
                        "is_open" : message.getBody(key: CoreMessage_TMessageKey.IS_OPEN),
                        "official" : message.getBody(key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT),
                        "level_edu" : message.getBody(key: CoreMessage_TMessageKey.LEVEL_EDU),
                        "materi_edu" : message.getBody(key: CoreMessage_TMessageKey.MATERI_EDU),
                        "is_education" : message.getBody(key: CoreMessage_TMessageKey.IS_EDUCATION)
                    ], replace: true)
                    if result > 0 {
                        if let delegate = Nexilis.shared.groupDelegate {
                            delegate.onGroup(code: message.getCode(), f_pin: message.getPIN(), groupId: group_id)
                        }
                        ack(message: message)
                    }
                } catch {
                    rollback.pointee = true
                    print(error)
                }
            })
        }
    }
    
    private func receiveMessage(message: TMessage) -> Void {
        let message_id = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
        guard let _ = UserDefaults.standard.string(forKey: "status") else {
            print("App not ready!!! skip receive message \(message_id)")
            ack(message: message)
            return
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where message_id = '\(message_id)'"), cursor.next() {
                ack(message: message)
                cursor.close()
                return
            }
        })
        let media = message.getMedia()
        print("MEDIA \(media)");
        let thumb_id = message.getBody(key: CoreMessage_TMessageKey.THUMB_ID)
        if media.count > 0 {
            do {
                let data = Data(media)
                let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let url = documentDir.appendingPathComponent(thumb_id)
                print("write thumb \(url.path)")
                try data.write(to: url, options: .atomic)
//                let image = UIImage(data: data)
//                let save = UserDefaults.standard.bool(forKey: "saveToGallery")
//                if save {
//                    UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
//                }
            } catch {
                print(error)
            }
        }
        if (!thumb_id.isEmpty) {
            Download().start(forKey: thumb_id) { (file, progress) in
                print ("masuk download \(progress)")
                if(progress == 100) {
                    Nexilis.saveMessage(message: message, withStatus: false)
                    print("save message incoming")
                    if let delegate = Nexilis.shared.messageDelegate {
                        message.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_TEXT, default_value : "").toNormalString()
                        delegate.onReceive(message: message)
                    }
                }
            }
            ack(message: message)
            return
        }
        Nexilis.saveMessage(message: message, withStatus: false)
        print("save message incoming")
        if let delegate = Nexilis.shared.messageDelegate {
            message.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_TEXT, default_value : "").toNormalString()
            delegate.onReceive(message: message)
        }
        ack(message: message)
    }
    
    private func receiveMessageStatus(message: TMessage) -> Void {
        let message_id = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
        guard let _ = UserDefaults.standard.string(forKey: "status") else {
            print("App not ready!!! skip receive message \(message_id)")
            return
        }
        Nexilis.updateMessageStatus(message: message)
        if let delegate = Nexilis.shared.messageDelegate {
            delegate.onMessage(message: message)
        }
        ack(message: message)
    }
    
    private func uploadFile(message: TMessage) -> Void {
        let fileName = message.getBody(key: "file_id")
        guard !fileName.isEmpty else {
            return
        }
        guard let upload = Nexilis.getUploadFile(forKey: fileName) else {
            return
        }
        upload.uploadGroup.leave()
        ack(message: message)
    }
    
    private func initBatchBuddy(message: TMessage) -> Void {
        let data  = message.getBody(key: CoreMessage_TMessageKey.DATA)
        if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    for json in jsonArray {
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                            "f_pin" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.F_PIN),
                            "upline_pin" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.UPLINE_PIN),
                            "first_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.FIRST_NAME),
                            "last_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_NAME),
                            "image_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.THUMB_ID),
                            "user_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.USER_ID),
                            "quote" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.QUOTE),
                            "connected" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CONNECTED),
                            "last_update" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_UPDATE),
                            "latitude" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LATITUDE),
                            "longitude" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LONGITUDE),
                            "altitude" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.ALTITUDE),
                            "cell" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CELL),
                            "last_loc_update" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_LOC_UPDATE),
                            "type" : "0",
                            "empty_2" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PLACE_NAME),
                            "timezone" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.TIMEZONE),
                            "privacy_flag" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PRIVACY_FLAG),
                            "msisdn" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MSISDN),
                            "email" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.EMAIL),
                            "created_date" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CREATED_DATE),
                            "offline_mode" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.OFFLINE_MODE),
                            "network_type" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.NETWORK_TYPE),
                            "ex_block" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.BLOCK),
                            "ex_follow" : "0",
                            "ex_follower" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.TOTAL_FOLLOWERS),
                            "ex_offmp" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.OFFMP),
                            "ex_status" : "1",
                            "shop_code" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.SHOP_CODE),
                            "shop_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.SHOP_NAME),
                            "extension" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.EXTENSION),
                            "auto_quote" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.AUTO_QUOTE),
                            "auto_quote_type" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.AUTO_QUOTE_TYPE),
                            "android_version" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.ANDROID_VERSION),
                            "device_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IMEI),
                            "be_info" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.BE_INFO),
                            "org_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.ORG_ID),
                            "org_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.ORG_NAME),
                            "org_thumb" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.ORG_THUMB),
                            "gender" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GENDER),
                            "birthdate" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.BIRTHDATE),
                            "type_ads" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.TYPE_ADS),
                            "type_lp" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.TYPE_LP),
                            "type_post" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.TYPE_POST),
                            "address" : message.getBody(key: CoreMessage_TMessageKey.ADDRESS),
                            "bidang_industri" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.BIDANG_INDUSTRI),
                            "visi" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.VISI),
                            "misi" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MISI),
                            "company_lat" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.COMPANY_LAT),
                            "company_lng" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.COMPANY_LNG),
                            "web" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.COMPANY_WEB),
                            "certificate_image" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.COMPANY_CERTIFICATE),
                            "card_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CARD_ID),
                            "user_type" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.USER_TYPE),
                            "real_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.REAL_NAME),
                            "official_account" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT),
                            "is_sub_account" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_SUB_ACCOUNT),
                            "last_sign" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_SIGN),
                            "android_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.ANDROID_ID),
                            "is_change_profile" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_CHANGE_PROFILE),
                            "area" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.WORKING_AREA),
                            "is_second_layer" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_SECOND_LAYER),
                        ], replace: true)
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", cvalues: [
                            "first_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.FIRST_NAME),
                            "last_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_NAME),
                            "thumb_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.THUMB_ID),
                        ], _where: "f_pin = '\(CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.F_PIN))'")
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "f_display_name" : (CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.FIRST_NAME) + " " + CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_NAME)).trimmingCharacters(in: .whitespaces)
                        ], _where: "f_pin = '\(CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.F_PIN))'")
                    }
                    if let delegate = Nexilis.shared.personInfoDelegate {
                        delegate.onUpdatePersonInfo(state: 99, message: "update_buddy")
                    }
                    ack(message: message)
                } catch {
                    rollback.pointee = true
                    print(error)
                }
            })
        }
    }
    
    private func deleteBuddy(message: TMessage) -> Void {
        var l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
        l_pin = (l_pin == UserDefaults.standard.string(forKey: "me")) ? message.mPIN : l_pin
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select * from BUDDY where f_pin = '\(l_pin)'"), cursor.next() {
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "BUDDY", _where: "f_pin = '\(l_pin)'")
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "(f_pin='\(l_pin)' or l_pin='\(l_pin)') and (message_scope_id='3' or message_scope_id='18')")
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(l_pin)'")
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "POST", _where: "author_f_pin='\(l_pin)'")
                    cursor.close()
                    print("Buddy deleted: \(l_pin)")
                    if let delegate = Nexilis.shared.personInfoDelegate {
                        delegate.onUpdatePersonInfo(state: 99, message: "delete_buddy,\(l_pin)")
                    }
                    return
                }
                ack(message: message)
            }
        })
    }
    
    private func pushMyself(message: TMessage) -> Void {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let result = try Database.shared.insertRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                    "f_pin" : message.getBody(key: CoreMessage_TMessageKey.F_PIN),
                    "upline_pin" : message.getBody(key: CoreMessage_TMessageKey.UPLINE_PIN),
                    "first_name" : message.getBody(key: CoreMessage_TMessageKey.FIRST_NAME),
                    "last_name" : message.getBody(key: CoreMessage_TMessageKey.LAST_NAME),
                    "image_id" : message.getBody(key: CoreMessage_TMessageKey.THUMB_ID),
                    "user_id" : message.getBody(key: CoreMessage_TMessageKey.USER_ID),
                    "quote" : message.getBody(key: CoreMessage_TMessageKey.QUOTE),
                    "connected" : message.getBody(key: CoreMessage_TMessageKey.CONNECTED),
                    "last_update" : message.getBody(key: CoreMessage_TMessageKey.LAST_UPDATE),
                    "latitude" : message.getBody(key: CoreMessage_TMessageKey.LATITUDE),
                    "longitude" : message.getBody(key: CoreMessage_TMessageKey.LONGITUDE),
                    "altitude" : message.getBody(key: CoreMessage_TMessageKey.ALTITUDE),
                    "cell" : message.getBody(key: CoreMessage_TMessageKey.CELL),
                    "last_loc_update" : message.getBody(key: CoreMessage_TMessageKey.LAST_LOC_UPDATE),
                    "type" : "1",
                    "empty_2" : message.getBody(key: CoreMessage_TMessageKey.PLACE_NAME),
                    "timezone" : message.getBody(key: CoreMessage_TMessageKey.TIMEZONE),
                    "privacy_flag" : message.getBody(key: CoreMessage_TMessageKey.PRIVACY_FLAG),
                    "msisdn" : message.getBody(key: CoreMessage_TMessageKey.MSISDN),
                    "email" : message.getBody(key: CoreMessage_TMessageKey.EMAIL),
                    "created_date" : message.getBody(key: CoreMessage_TMessageKey.CREATED_DATE),
                    "offline_mode" : message.getBody(key: CoreMessage_TMessageKey.OFFLINE_MODE),
                    "network_type" : message.getBody(key: CoreMessage_TMessageKey.NETWORK_TYPE),
                    "ex_block" : "0",
                    "ex_follow" : "0",
                    "ex_follower" : message.getBody(key: CoreMessage_TMessageKey.TOTAL_FOLLOWERS),
                    "ex_offmp" : message.getBody(key: CoreMessage_TMessageKey.OFFMP),
                    "ex_status" : "0",
                    "shop_code" : message.getBody(key: CoreMessage_TMessageKey.SHOP_CODE),
                    "shop_name" : message.getBody(key: CoreMessage_TMessageKey.SHOP_NAME),
                    "extension" : message.getBody(key: CoreMessage_TMessageKey.EXTENSION),
                    "auto_quote" : message.getBody(key: CoreMessage_TMessageKey.AUTO_QUOTE),
                    "auto_quote_type" : message.getBody(key: CoreMessage_TMessageKey.AUTO_QUOTE_TYPE),
                    "be_info" : message.getBody(key: CoreMessage_TMessageKey.BE_INFO),
                    "org_id" : message.getBody(key: CoreMessage_TMessageKey.ORG_ID),
                    "org_name" : message.getBody(key: CoreMessage_TMessageKey.ORG_NAME),
                    "org_thumb" : message.getBody(key: CoreMessage_TMessageKey.ORG_THUMB),
                    "gender" : message.getBody(key: CoreMessage_TMessageKey.GENDER),
                    "birthdate" : message.getBody(key: CoreMessage_TMessageKey.BIRTHDATE),
                    "type_ads" : message.getBody(key: CoreMessage_TMessageKey.TYPE_ADS),
                    "type_lp" : message.getBody(key: CoreMessage_TMessageKey.TYPE_LP),
                    "type_post" : message.getBody(key: CoreMessage_TMessageKey.TYPE_POST),
                    "address" : message.getBody(key: CoreMessage_TMessageKey.ADDRESS),
                    "bidang_industri" : message.getBody(key: CoreMessage_TMessageKey.BIDANG_INDUSTRI),
                    "visi" : message.getBody(key: CoreMessage_TMessageKey.VISI),
                    "misi" : message.getBody(key: CoreMessage_TMessageKey.MISI),
                    "company_lat" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_LAT),
                    "company_lng" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_LNG),
                    "web" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_WEB),
                    "certificate_image" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_CERTIFICATE),
                    "card_id" : message.getBody(key: CoreMessage_TMessageKey.CARD_ID),
                    "user_type" : message.getBody(key: CoreMessage_TMessageKey.USER_TYPE),
                    "real_name" : message.getBody(key: CoreMessage_TMessageKey.REAL_NAME),
                    "official_account" : message.getBody(key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT),
                    "is_sub_account" : message.getBody(key: CoreMessage_TMessageKey.IS_SUB_ACCOUNT),
                    "last_sign" : message.getBody(key: CoreMessage_TMessageKey.LAST_SIGN),
                    "android_id" : message.getBody(key: CoreMessage_TMessageKey.ANDROID_ID),
                    "is_change_profile" : message.getBody(key: CoreMessage_TMessageKey.IS_CHANGE_PROFILE),
                    "area" : message.getBody(key: CoreMessage_TMessageKey.WORKING_AREA),
                    "is_second_layer" : message.getBody(key: CoreMessage_TMessageKey.IS_SECOND_LAYER),
                ], replace: true)
                ack(message: message)
                let idMe = UserDefaults.standard.string(forKey: "me")!
                if message.getBody(key: CoreMessage_TMessageKey.USER_TYPE) != "24" && message.getBody(key: CoreMessage_TMessageKey.F_PIN) == idMe {
                    let onGoingCC = UserDefaults.standard.string(forKey: "onGoingCC") ?? ""
                    if !onGoingCC.isEmpty {
                        let requester = onGoingCC.components(separatedBy: ",")[0]
                        let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                        let complaintId = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2]
                        let startTimeCC = UserDefaults.standard.string(forKey: "startTimeCC") ?? ""
                        let date = "\(Date().currentTimeMillis())"
                        if officer == idMe {
                            _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: requester))
                        } else {
                            if requester == idMe {
                                _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: officer))
                            } else {
                                _ = Nexilis.write(message: CoreMessage_TMessageBank.leaveCCRoomInvite(ticket_id: complaintId))
                            }
                        }
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
                        UserDefaults.standard.removeObject(forKey: "onGoingCC")
                        UserDefaults.standard.removeObject(forKey: "membersCC")
                        UserDefaults.standard.removeObject(forKey: "startTimeCC")
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                            banner.show()
                            if UIApplication.shared.visibleViewController is UINavigationController {
                                let nc = UIApplication.shared.visibleViewController as! UINavigationController
                                if nc.visibleViewController is QmeraAudioViewController || nc.visibleViewController is QmeraVideoViewController {
                                    API.terminateCall(sParty: nil)
                                }
                                if nc.visibleViewController is EditorPersonal{
                                    let vc = nc.visibleViewController as! EditorPersonal
                                    vc.timeoutCC.invalidate()
                                }
                                nc.visibleViewController?.dismiss(animated: true, completion: nil)
                            } else {
                                if UIApplication.shared.visibleViewController is QmeraAudioViewController || UIApplication.shared.visibleViewController is QmeraVideoViewController {
                                    API.terminateCall(sParty: nil)
                                }
                                if UIApplication.shared.visibleViewController is EditorPersonal{
                                    let vc = UIApplication.shared.visibleViewController as! EditorPersonal
                                    vc.timeoutCC.invalidate()
                                }
                                UIApplication.shared.visibleViewController?.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            } catch {
                rollback.pointee = true
                print(error)
            }
        })
    }
    
    private func onInitGroupInfoBatch(message: TMessage) -> Void {
        let dataGroup  = message.getBody(key: CoreMessage_TMessageKey.DATA)
        if let jsonArray = try! JSONSerialization.jsonObject(with: dataGroup.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    for json in jsonArray {
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "GROUPZ", cvalues: [
                            "group_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GROUP_ID),
                            "f_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GROUP_NAME),
                            "scope_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MESSAGE_SCOPE_ID),
                            "image_id": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.THUMB_ID),
                            "quote": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.QUOTE),
                            "last_update" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_UPDATE),
                            "created_by" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CREATED_BY),
                            "created_date" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CREATED_DATE),
                            "ex_block" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.BLOCK),
                            "folder_id" : "",
                            "chat_modifier" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CHAT_MODIFIER),
                            "group_type" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_ORGANIZATION),
                            "parent" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PARENT_ID),
                            "level" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LEVEL),
                            "is_open" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_OPEN),
                            "official" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT),
                            "level_edu" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LEVEL_EDU),
                            "materi_edu" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MATERI_EDU),
                            "is_education" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_EDUCATION)
                        ], replace: true)
                        let member = CoreMessage_TMessageUtil.getString(json: json, key: "member")
                        if let jsonArrayMember = try! JSONSerialization.jsonObject(with: member.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                            for jsonMember in jsonArrayMember {
                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", cvalues: [
                                    "group_id" :CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GROUP_ID),
                                    "f_pin" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.F_PIN),
                                    "position" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.POSITION),
                                    "user_id" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.USER_ID),
                                    "ac" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.AC),
                                    "ac_desc" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.AC_DESC),
                                    "first_name" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.FIRST_NAME),
                                    "last_name" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.LAST_NAME),
                                    "msisdn" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.MSISDN),
                                    "thumb_id" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.THUMB_ID),
                                    "created_date" : CoreMessage_TMessageUtil.getString(json: jsonMember, key: CoreMessage_TMessageKey.CREATED_DATE),
                                ], replace: true)
                            }
                        }
                    }
                    ack(message: message)
                } catch {
                    rollback.pointee = true
                    print(error)
                }
            })
        }
    }
    
    private func onInitForumInfoBatch(message: TMessage, with isDelegate: Bool = false) -> Void {
        let dataForum  = message.getBody(key: CoreMessage_TMessageKey.DATA)
        if let jsonArray = try! JSONSerialization.jsonObject(with: dataForum.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    for json in jsonArray {
                        let chat_id = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CHAT_ID)
                        let group_id = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.F_PIN)
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", cvalues: [
                            "chat_id": chat_id,
                            "title":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.TITLE),
                            "group_id": group_id,
                            "anonym":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.ANONYMOUS),
                            "scope_id":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.SCOPE_ID),
                            "thumb":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IMAGE),
                            "category":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CATEGORY_ID),
                            "activity":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.ACTVITY),
                            "milis":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.EMAIL),
                            "sharing_flag":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.SHARING_FLAG),
                            "clients":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CLIENTS),
                            "owner":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GROUP_ID),
                            "raci_r":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.RACI_R),
                            "raci_a":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.RACI_A),
                            "raci_c":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.RACI_C),
                            "raci_i":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.RACI_I),
                            "act_thumb":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.THUMBNAIL_ACTIVITY),
                            "client_thumb":CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.THUMBNAIL_CLIENT)
                        ], replace: true)
                        if isDelegate {
                            if let delegate = Nexilis.shared.groupDelegate {
                                delegate.onTopic(code: message.getCode(), f_pin: message.getPIN(), topicId: chat_id)
                            }
                        }
                    }
                    ack(message: message)
                } catch {
                    rollback.pointee = true
                    print(error)
                }
            })
        }
    }
    
    func loginFile(message: TMessage) -> Void {
        let response = TMessage()
        var isSuccess = false
        let media = message.getMedia()
        if media.count != 0 {
            let data = Archive.unzip(bytes: media)
            let lines = data.components(separatedBy: .newlines)
            let line_count = lines.count
            var line_processed = 0
            for line in lines {
                let message = TMessage()
                if message.unpack(data: line) {
                    isSuccess = true
                    line_processed = line_processed + 1
                    process(message: message)
                    let progress = line_processed * 100 / line_count
                    if let delegate = Nexilis.shared.loginDelegate {
                        delegate.onProgress(code: message.getCode(), progress: progress)
                    }
                }
                else {
                    response.mBodies[CoreMessage_TMessageKey.ERRCOD] = "Failed unpack"
                }
            }
            if isSuccess {
                response.mBodies[CoreMessage_TMessageKey.ERRCOD] = "00"
                if let delegate = Nexilis.shared.loginDelegate {
                    delegate.onProgress(code: message.getCode(), progress: 100)
                }
                UserDefaults.standard.set("READY", forKey: "status")
            }
        }
        else {
            response.mBodies[CoreMessage_TMessageKey.ERRCOD] = "Media not found"
        }
        if let packetId = message.mBodies[CoreMessage_TMessageKey.PACKET_ID] {
            _ = Nexilis.response(packetId: packetId, message: response)
            if isSuccess {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.getVersionCheck())
                Nexilis.initFollowing()
            }
        }
        ack(message: message)
    }
    
    private func getLiveVideoList(message: TMessage) -> Void {
        let data  = message.getBody(key: CoreMessage_TMessageKey.DATA)
        print(data)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onStartLS(state: 99, message: data)
        }
        ack(message: message)
    }
    private func getLSTitle(message: TMessage) -> Void {
        let title  = message.getBody(key: CoreMessage_TMessageKey.TITLE)
        print(title)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: 999, message: title)
        }
        ack(message: message)
    }
    private func changePersonInfoPassword(message: TMessage) -> Void {
        ack(message: message)
    }
    
    private func changePersonInfoName(message: TMessage) -> Void {
        let fPin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        let fname  = message.getBody(key: CoreMessage_TMessageKey.FIRST_NAME)
        let lname  = message.getBody(key: CoreMessage_TMessageKey.LAST_NAME)
        let offline_mode = message.getBody(key: CoreMessage_TMessageKey.OFFLINE_MODE)
        let auto_quote = message.getBody(key: CoreMessage_TMessageKey.AUTO_QUOTE)
        let cell = message.getBody(key: CoreMessage_TMessageKey.CELL)
        let connected = message.getBody(key: CoreMessage_TMessageKey.CONNECTED)
        let latitude = message.getBody(key: CoreMessage_TMessageKey.LATITUDE)
        let last_loc_update = message.getBody(key: CoreMessage_TMessageKey.LAST_LOC_UPDATE)
        let user_type = message.getBody(key: CoreMessage_TMessageKey.USER_TYPE)
        if let delegate = Nexilis.shared.personInfoDelegate {
            print("INcoming \(connected)")
            delegate.onUpdatePersonInfo(state: 00, message: connected)
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                "first_name" : fname,
                "last_name" : lname,
                "offline_mode" : offline_mode,
                "auto_quote" : auto_quote,
                "cell" : cell,
                "connected" : connected,
                "latitude" : latitude,
                "last_loc_update" : last_loc_update,
                "user_type" : user_type
            ], _where: "f_pin = '\(fPin)'")
        })
        ack(message: message)
    }
    
    private func ack(message: TMessage) -> Void {
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getAcknowledgment(p_id: message.mStatus))
    }
    
    private func joinLivevideo(message: TMessage) -> Void {
        let broadcaster = message.getBody(key: CoreMessage_TMessageKey.L_PIN,default_value: "")
        let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN,default_value: "")
        let thumb_id = message.getBody(key: CoreMessage_TMessageKey.THUMB_ID,default_value: "")
        let name = message.getBody(key: CoreMessage_TMessageKey.NAME,default_value: "")
        let quantity = message.getBody(key: CoreMessage_TMessageKey.QUANTITY,default_value: "")
        let data = broadcaster+","+f_pin+","+thumb_id+","+name+","+quantity
        print(data)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: 98, message: data)
        }
        ack(message: message)
    }
    
    private func leftLiveVideo(message: TMessage) -> Void {
        let broadcaster = message.getBody(key: CoreMessage_TMessageKey.L_PIN,default_value: "")
        let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN,default_value: "")
        let thumb_id = message.getBody(key: CoreMessage_TMessageKey.THUMB_ID,default_value: "")
        let name = message.getBody(key: CoreMessage_TMessageKey.NAME,default_value: "")
        let quantity = message.getBody(key: CoreMessage_TMessageKey.QUANTITY,default_value: "")
        let data = broadcaster+","+f_pin+","+thumb_id+","+name+","+quantity
        print(data)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: 97, message: data)
        }
        ack(message: message)
    }
    private func getLSEmotion(message: TMessage) -> Void {
        let l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN,default_value: "")
        let likes = message.getBody(key: CoreMessage_TMessageKey.LIKES,default_value: "")
        let quantity = message.getBody(key: CoreMessage_TMessageKey.QUANTITY,default_value: "")
        let data = l_pin+","+likes+","+quantity
        print(data)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: 96, message: data)
        }
        ack(message: message)
    }
    private func getLSChat(message: TMessage) -> Void {

        let l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN,default_value: "")
        let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN,default_value: "")
        let thumb_id = message.getBody(key: CoreMessage_TMessageKey.THUMB_ID,default_value: "")
        let name = message.getBody(key: CoreMessage_TMessageKey.NAME,default_value: "")
        let messages = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT,default_value: "")
        let data = l_pin+","+f_pin+","+thumb_id+","+name+","+messages
        print(data)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: 95, message: data)
        }
        ack(message: message)
    }
    private func getLSData(message: TMessage) -> Void {
        let l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN,default_value: "")
        let likes = message.getBody(key: CoreMessage_TMessageKey.LIKES,default_value: "")
        let quantity = message.getBody(key: CoreMessage_TMessageKey.QUANTITY,default_value: "")
        let data = l_pin+","+likes+","+quantity
        print(data)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: 94, message: data)
        }
        ack(message: message)
    }
    private func incomingScreenSharing(message: TMessage, state: Int) -> Void {
        let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN,default_value: "")
        let l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN,default_value: "")
        let data = f_pin
        print("data ss")
        print(data)
        print(l_pin)
        print(state)
        if let delegate = Nexilis.shared.screenSharingDelegate {
            delegate.onJoinScreenSharing(state: state, message: data)
        }
        ack(message: message)
    }
    
    private func sendMSISDN(message: TMessage) -> Void {
        let errcod = message.getBody(key: CoreMessage_TMessageKey.ERRCOD,default_value: "")
        let data = errcod
        print(data)
        if (errcod == "00"){
            if let delegate = Nexilis.shared.loginDelegate {
                delegate.onProcess(message: "Success", status: "1")
            }
        } else {
            if let delegate = Nexilis.shared.loginDelegate {
                delegate.onProcess(message: "Failed", status: "0")
            }
        }
        
        ack(message: message)
    }
    
    private func verifyOTP(message: TMessage) -> Void {
        let errcod = message.getBody(key: CoreMessage_TMessageKey.ERRCOD,default_value: "00")
        if errcod == "00" {
            let reg_status = message.getBody(key: CoreMessage_TMessageKey.REG_STATUS, default_value: "")
            if reg_status == "1" {
                let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                let f_name = message.getBody(key: CoreMessage_TMessageKey.FIRST_NAME, default_value: "")
                let l_name = message.getBody(key: CoreMessage_TMessageKey.LAST_NAME, default_value: "")
                let thumb_id = message.getBody(key: CoreMessage_TMessageKey.THUMB_ID, default_value: "")
                let data = f_pin+"|"+f_name+"|"+l_name+"|"+thumb_id
                print(data)
                if let delegate = Nexilis.shared.loginDelegate {
                    delegate.onProcess(message: data, status: reg_status)
                }
            } else {
                if let delegate = Nexilis.shared.loginDelegate {
                    delegate.onProcess(message: "Signup", status: reg_status)
                }
            }
        } else {
            if let delegate = Nexilis.shared.loginDelegate {
                delegate.onProcess(message: "Wrong OTP", status: errcod)
            }
        }
        ack(message: message)
    }
    
    private func signInOTP(message: TMessage) -> Void {
        if (message.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "00") == "00") {
            let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "00")
            UserDefaults.standard.set(f_pin, forKey: "me")
            if let delegate = Nexilis.shared.loginDelegate {
                delegate.onProcess(message: f_pin, status: message.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "00"))
            }
        } else {
            if let delegate = Nexilis.shared.loginDelegate {
                delegate.onProcess(message: "Failed", status: message.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "00"))
            }
        }
        ack(message: message)
    }
    
    private func updateTimeline(message:TMessage) -> Void {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let _ = try Database.shared.insertRecord(fmdb: fmdb, table: "POST", cvalues: [
                    "post_id" : message.getBody(key: CoreMessage_TMessageKey.POST_ID,default_value: ""),
                    "author_f_pin" : message.getBody(key: CoreMessage_TMessageKey.F_PIN,default_value: ""),
                    "author_name" : message.getBody(key: CoreMessage_TMessageKey.NAME,default_value: ""),
                    "author_thumbnail" : message.getBody(key: CoreMessage_TMessageKey.THUMB_ID,default_value: ""),
                    "type" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.TYPE,default_value: 2),
                    "created_date" : message.getBodyAsLong(key: CoreMessage_TMessageKey.CREATED_DATE,default_value: CLong(Utils.getCurrentTimeMillis())),
                    "title" : message.getBody(key: CoreMessage_TMessageKey.TITLE,default_value: ""),
                    "description" : message.getBody(key: CoreMessage_TMessageKey.DESCRIPTION,default_value: ""),
                    "privacy" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.PRIVACY_FLAG,default_value: 3),
                    "audition_date" : message.getBodyAsLong(key: CoreMessage_TMessageKey.START_DATE,default_value: CLong(0)),
                    "total_comment" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.COMMENTS,default_value: 0),
                    "total_like" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.LIKES,default_value: 0),
                    "total_dislike" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.DISLIKES,default_value: 0),
                    "last_update" : message.getBodyAsLong(key: CoreMessage_TMessageKey.LAST_UPDATE,default_value: CLong(Utils.getCurrentTimeMillis())),
                    "file_type" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.MEDIA_TYPE,default_value: 3),
                    "thumb_id" : message.getBody(key: CoreMessage_TMessageKey.IMAGE_ID),
                    "file_id" : message.getBody(key: CoreMessage_TMessageKey.FILE_ID),
                    "video_duration" : message.getBodyAsLong(key: CoreMessage_TMessageKey.DURATION,default_value: CLong(0)),
                    "category_id" : message.getBody(key: CoreMessage_TMessageKey.USER_ID),
                    "like_flag" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.FLAG_REACTION,default_value: 0),
                    "report_flag" : message.getBody(key: CoreMessage_TMessageKey.FLAG_REPORT,default_value: "0"),
                    "last_edit" : message.getBodyAsLong(key: CoreMessage_TMessageKey.LAST_EDIT,default_value: CLong(0)),
                    "post_id_participate" : message.getBody(key: CoreMessage_TMessageKey.PARTICIPATE_ID,default_value: ""),
                    "participate_date" : message.getBodyAsLong(key: CoreMessage_TMessageKey.PARTICIPATE_DATE,default_value: CLong(0)),
                    "certificates" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_CERTIFICATE,default_value: ""),
                    "participate_size" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.PARTICIPATE_SIZE, default_value: 0),
                    "total_view" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.N_VIEWS,default_value: 0),
                    "view_flag" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.VIEW_MEDIA_FLAG,default_value: 0),
                    "total_followers" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.FOLLOWER_SIZE,default_value: 0),
                    "score" : message.getBodyAsLong(key: CoreMessage_TMessageKey.SCORE, default_value: CLong(0)),
                    "share_sosmed_type" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.SHARING_FLAG, default_value: 0),
                    "link" : message.getBody(key: CoreMessage_TMessageKey.LINK, default_value: ""),
                    "category_flag" : message.getBody(key: CoreMessage_TMessageKey.CATEGORY_FLAG,default_value: ""),
                    "official_account" : message.getBodyAsInteger(key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT,default_value: 0)
//                    "roc_date" : message.getBody(key: CoreMessage_TMessageKey.LAST_NAME),
//                    "roc_size" : message.getBody(key: CoreMessage_TMessageKey.MSISDN),
//                    "level_edu" : message.getBody(key: CoreMessage_TMessageKey.THUMB_ID),
//                    "materi_edu" : message.getBody(key: CoreMessage_TMessageKey.USER_ID),
//                    "finaltest_edu" : message.getBody(key: CoreMessage_TMessageKey.AC),
//                    "file_summarization" : message.getBody(key: CoreMessage_TMessageKey.AC_DESC),
//                    "target" : message.getBody(key: CoreMessage_TMessageKey.FIRST_NAME),
//                    "pricing" : message.getBody(key: CoreMessage_TMessageKey.LAST_NAME),
//                    "pricing_money" : message.getBody(key: CoreMessage_TMessageKey.MSISDN)
                ], replace: true)
                ack(message: message)
            } catch {
                rollback.pointee = true
                print(error)
            }
        })
    }
    
    private func changePersonInfo(message: TMessage){
        let error_code = message.getBody(key: CoreMessage_TMessageKey.ERRCOD)
        let first_name = message.getBody(key: CoreMessage_TMessageKey.FIRST_NAME,default_value: "")
        let last_name = message.getBody(key: CoreMessage_TMessageKey.LAST_NAME,default_value: "")
        let thumb_id = message.getBody(key: CoreMessage_TMessageKey.THUMB_ID,default_value: "")
        let quote = message.getBody(key: CoreMessage_TMessageKey.QUOTE,default_value: "")
        let email = message.getBody(key: CoreMessage_TMessageKey.EMAIL)
        let last_update = message.getBody(key: CoreMessage_TMessageKey.LAST_UPDATE)
        let connected = message.getBody(key: CoreMessage_TMessageKey.CONNECTED)
        let msisdn = message.getBody(key: CoreMessage_TMessageKey.MSISDN)
        let ext_text_1 = message.getBody(key: CoreMessage_TMessageKey.EXT_TEXT_1)
        let auto_quote = message.getBody(key: CoreMessage_TMessageKey.AUTO_QUOTE,default_value: "")
        let auto_quote_type = message.getBody(key: CoreMessage_TMessageKey.AUTO_QUOTE_TYPE,default_value: "")
        let _extension = message.getBody(key: CoreMessage_TMessageKey.EXTENSION)
        let be_info = message.getBody(key: CoreMessage_TMessageKey.BE_INFO)
        let imei = message.getBody(key: CoreMessage_TMessageKey.IMEI)
        let offline_mode = message.getBody(key: CoreMessage_TMessageKey.OFFLINE_MODE)
        let card_id = message.getBody(key: CoreMessage_TMessageKey.CARD_ID,default_value: "")
        let card_type = message.getBody(key: CoreMessage_TMessageKey.CARD_TYPE,default_value: "0")
        let gender = message.getBody(key: CoreMessage_TMessageKey.GENDER,default_value: "0")
        let birthdate = message.getBody(key: CoreMessage_TMessageKey.BIRTHDATE,default_value: "0")
        let type_ads = message.getBody(key: CoreMessage_TMessageKey.TYPE_ADS,default_value: "")
        let type_lp = message.getBody(key: CoreMessage_TMessageKey.TYPE_LP,default_value: "")
        let type_post = message.getBody(key: CoreMessage_TMessageKey.TYPE_POST,default_value: "")
        let address = message.getBody(key: CoreMessage_TMessageKey.ADDRESS,default_value: "")
        let bidang_industri = message.getBody(key: CoreMessage_TMessageKey.BIDANG_INDUSTRI,default_value: "")
        let visi = message.getBody(key: CoreMessage_TMessageKey.VISI, default_value: "")
        let misi = message.getBody(key: CoreMessage_TMessageKey.MISI, default_value: "")
        let company_lat = message.getBody(key: CoreMessage_TMessageKey.COMPANY_LAT, default_value: "")
        let company_lng = message.getBody(key: CoreMessage_TMessageKey.COMPANY_LNG, default_value: "")
        let web = message.getBody(key: CoreMessage_TMessageKey.COMPANY_WEB, default_value: "")
        let certificate_image = message.getBody(key: CoreMessage_TMessageKey.COMPANY_CERTIFICATE, default_value: "")
        let official_account = message.getBody(key: CoreMessage_TMessageKey.COMPANY_CERTIFICATE, default_value: "")
        let user_type = message.getBody(key: CoreMessage_TMessageKey.USER_TYPE,default_value: "")
        let real_name = message.getBody(key: CoreMessage_TMessageKey.REAL_NAME, default_value: "")
        let is_sub_account = message.getBody(key: CoreMessage_TMessageKey.IS_SUB_ACCOUNT, default_value: "")
        let last_sign = message.getBody(key: CoreMessage_TMessageKey.LAST_SIGN)
        let android_id = message.getBody(key: CoreMessage_TMessageKey.ANDROID_ID)
        
        let is_pull = message.getBody(key: CoreMessage_TMessageKey.IS_PULL, default_value: "0")
        if(is_pull != "0"){
            
        }
        
        if(error_code == "00"){
            var msisdnChanged = false
            var emailChanged = false
            var cvalues = [String:Any]()
            
            if(!first_name.isEmpty){ cvalues["first_name"] = first_name}
            if(!last_name.isEmpty){ cvalues["last_name"] = last_name}
            if(!thumb_id.isEmpty){ cvalues["image_id"] = thumb_id}
            if(!quote.isEmpty){cvalues["quote"] = quote}
            if(!last_update.isEmpty){cvalues["last_update"] = last_update}
            if(!auto_quote.isEmpty){cvalues["auto_quote"] = auto_quote}
            if(!auto_quote_type.isEmpty){cvalues["auto_quote_type"] = auto_quote_type}
            if(!email.isEmpty){cvalues["email"] = email; emailChanged = true}
            if(!last_update.isEmpty){cvalues["last_update"] = last_update}
            if(!msisdn.isEmpty){cvalues["msisdn"] = msisdn; msisdnChanged = true}
            if(!_extension.isEmpty){cvalues["extension"] = _extension}
            if(!be_info.isEmpty){cvalues["be_info"] = be_info}
            if(!card_id.isEmpty){cvalues["card_id"] = card_id}
            if(gender != "0"){cvalues["gender"] = gender}
            if(birthdate != "0"){cvalues["birthdate"] = birthdate}
            if(!offline_mode.isEmpty){cvalues["offline_mode"] = offline_mode}
            if(!official_account.isEmpty){cvalues["official_account"] = official_account}
            if(!connected.isEmpty){cvalues["connected"] = connected}
            //                        "first_name" : message.getBody(key: CoreMessage_TMessageKey.FIRST_NAME),
            //                        "last_name" : message.getBody(key: CoreMessage_TMessageKey.LAST_NAME),
            //                        "image_id" : message.getBody(key: CoreMessage_TMessageKey.THUMB_ID),
            //                        "quote" : message.getBody(key: CoreMessage_TMessageKey.QUOTE),
            //                        "last_update" : message.getBody(key: CoreMessage_TMessageKey.LAST_UPDATE),
            //                        "latitude" : message.getBody(key: CoreMessage_TMessageKey.LATITUDE),
            //                        "longitude" : message.getBody(key: CoreMessage_TMessageKey.LONGITUDE),
            //                        "altitude" : message.getBody(key: CoreMessage_TMessageKey.ALTITUDE),
            //                        "cell" : message.getBody(key: CoreMessage_TMessageKey.CELL),
            //                        "last_loc_update" : message.getBody(key: CoreMessage_TMessageKey.LAST_LOC_UPDATE),
            //                        "type" : "1",
            //                        "empty_2" : message.getBody(key: CoreMessage_TMessageKey.PLACE_NAME),
            //                        "timezone" : message.getBody(key: CoreMessage_TMessageKey.TIMEZONE),
            //                        "privacy_flag" : message.getBody(key: CoreMessage_TMessageKey.PRIVACY_FLAG),
            //                        "msisdn" : message.getBody(key: CoreMessage_TMessageKey.MSISDN),
            //                        "email" : message.getBody(key: CoreMessage_TMessageKey.EMAIL),
            //                        "created_date" : message.getBody(key: CoreMessage_TMessageKey.CREATED_DATE),
            //                        "offline_mode" : message.getBody(key: CoreMessage_TMessageKey.OFFLINE_MODE),
            //                        "network_type" : message.getBody(key: CoreMessage_TMessageKey.NETWORK_TYPE),
            //                        "ex_block" : "0",
            //                        "ex_follow" : "0",
            //                        "ex_follower" : message.getBody(key: CoreMessage_TMessageKey.TOTAL_FOLLOWERS),
            //                        "ex_offmp" : message.getBody(key: CoreMessage_TMessageKey.OFFMP),
            //                        "ex_status" : "0",
            //                        "shop_code" : message.getBody(key: CoreMessage_TMessageKey.SHOP_CODE),
            //                        "shop_name" : message.getBody(key: CoreMessage_TMessageKey.SHOP_NAME),
            //                        "extension" : message.getBody(key: CoreMessage_TMessageKey.EXTENSION),
            //                        "auto_quote" : message.getBody(key: CoreMessage_TMessageKey.AUTO_QUOTE),
            //                        "auto_quote_type" : message.getBody(key: CoreMessage_TMessageKey.AUTO_QUOTE_TYPE),
            //                        "be_info" : message.getBody(key: CoreMessage_TMessageKey.BE_INFO),
            //                        "org_id" : message.getBody(key: CoreMessage_TMessageKey.ORG_ID),
            //                        "org_name" : message.getBody(key: CoreMessage_TMessageKey.ORG_NAME),
            //                        "org_thumb" : message.getBody(key: CoreMessage_TMessageKey.ORG_THUMB),
            //                        "gender" : message.getBody(key: CoreMessage_TMessageKey.GENDER),
            //                        "birthdate" : message.getBody(key: CoreMessage_TMessageKey.BIRTHDATE),
            //                        "type_ads" : message.getBody(key: CoreMessage_TMessageKey.TYPE_ADS),
            //                        "type_lp" : message.getBody(key: CoreMessage_TMessageKey.TYPE_LP),
            //                        "type_post" : message.getBody(key: CoreMessage_TMessageKey.TYPE_POST),
            //                        "address" : message.getBody(key: CoreMessage_TMessageKey.ADDRESS),
            //                        "bidang_industri" : message.getBody(key: CoreMessage_TMessageKey.BIDANG_INDUSTRI),
            //                        "visi" : message.getBody(key: CoreMessage_TMessageKey.VISI),
            //                        "misi" : message.getBody(key: CoreMessage_TMessageKey.MISI),
            //                        "company_lat" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_LAT),
            //                        "company_lng" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_LNG),
            //                        "web" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_WEB),
            //                        "certificate_image" : message.getBody(key: CoreMessage_TMessageKey.COMPANY_CERTIFICATE),
            //                        "card_id" : message.getBody(key: CoreMessage_TMessageKey.CARD_ID),
            //                        "user_type" : message.getBody(key: CoreMessage_TMessageKey.USER_TYPE),
            //                        "real_name" : message.getBody(key: CoreMessage_TMessageKey.REAL_NAME),
            //                        "official_account" : message.getBody(key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT),
            Database.shared.database?.inTransaction({ (fmdb,rollback) in
                do {
                    if let me = UserDefaults.standard.string(forKey: "me"), me == message.mPIN {
                        let update = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: cvalues, _where: "f_pin = '\(message.mPIN)'")
                        if(update > 0){
                            if let delegate = Nexilis.shared.personInfoDelegate {
                                if (!thumb_id.isEmpty){
                                    delegate.onUpdatePersonInfo(state: 6, message: thumb_id)
                                }
                            }
                        }
                    } else {
                        let update = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: cvalues, _where: "f_pin = '\(message.mPIN)'")
                        if(update > 0){
                            if let delegate = Nexilis.shared.personInfoDelegate {
                                if (!thumb_id.isEmpty){
                                    delegate.onUpdatePersonInfo(state: 5, message: thumb_id)
                                }
                             }
                        }
                    }
                }
            })
            ack(message: message)
        }
        if let delegate = Nexilis.shared.personInfoDelegate {
            if(!connected.isEmpty){
                delegate.onUpdatePersonInfo(state: 55, message:connected)
            }else{
                delegate.onUpdatePersonInfo(state: 0, message:error_code)
            }
        }
        
    }
    
    private static func onPushForm(message: TMessage) {
        var form = Form()
        form.formId = message.getBody(key: CoreMessage_TMessageKey.FORM_ID)
        form.title = message.getBody(key: CoreMessage_TMessageKey.TITLE)
        form.createdDate = message.getBodyAsLong(key: CoreMessage_TMessageKey.CREATED_DATE, default_value: 0)
        form.createdBy = message.getBody(key: CoreMessage_TMessageKey.CREATED_BY)
        form.sqNo = message.getBodyAsInteger(key: CoreMessage_TMessageKey.SEQUENCE, default_value: 0)
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "FORM", _where: "form_id = '\(form.formId)'")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "FORM_ITEM", _where: "form_id = '\(form.formId)'")
        })
        if(message.getBody(key: CoreMessage_TMessageKey.STATUS) == "0"){
            return
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            _ = try? Database.shared.insertRecord(fmdb: fmdb, table: "FORM", cvalues: [
                    "form_id" : form.formId,
                    "name": form.title,
                    "created_date": form.createdDate,
                    "created_by": form.createdBy,
                    "sq_no": form.sqNo
                ],
                replace: true)
        })
        let data = message.getBody(key: CoreMessage_TMessageKey.DATA)
        if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                for json in jsonArray{
                    _ = try? Database.shared.insertRecord(fmdb: fmdb, table: "FORM_ITEM",
                        cvalues: [
                            "form_id" : form.formId,
                            "label": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LABEL),
                            "value": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.VALUE),
                            "key": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.KEY),
                            "type": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.TYPE),
                            "sq_no": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.SEQUENCE)
                        ],
                        replace: false)
                }
            })
        }
        
    }
    
//    private static void onPushForm(TMessage p_tmessage) throws Exception {
//            Form_FormHolder form = new Form_FormHolder();
//            form.form_id = p_tmessage.getBody(CoreMessage_TMessageKey.FORM_ID);
//            form.title = p_tmessage.getBody(CoreMessage_TMessageKey.TITLE);
//            form.created_date = p_tmessage.getBodyAsLong(CoreMessage_TMessageKey.CREATED_DATE, 0);
//            form.created_by = p_tmessage.getBody(CoreMessage_TMessageKey.CREATED_BY);
//            form.sq_no = p_tmessage.getBodyAsInteger(CoreMessage_TMessageKey.SEQUENCE, 0);
//            Form_FormDB.deleteRecord(Form_FormDB.FIELD_FORM_ID + "='" + form.form_id + "'");
//            Form_FormItemDB.deleteRecord(Form_FormItemDB.FIELD_FORM_ID + "='" + form.form_id + "'");
//            if (p_tmessage.getBody(CoreMessage_TMessageKey.STATUS, "").equals("0")) {//Delete
//                return;
//            }
//            Form_FormDB.insertRecord(form.getContentValues());
//            JSONArray array = new JSONArray(p_tmessage.getBody(CoreMessage_TMessageKey.DATA));
//            for (int i = 0; i < array.length(); i++) {
//                JSONObject jo = array.getJSONObject(i);
//                Form_FormItemHolder item = new Form_FormItemHolder();
//                item.form_id = form.form_id;
//                item.label = getString(jo, CoreMessage_TMessageKey.LABEL);
//                item.value = getString(jo, CoreMessage_TMessageKey.VALUE);
//                item.key = getString(jo, CoreMessage_TMessageKey.KEY);
//                item.sq_no = getLong(jo);
//                item.type = getString(jo, CoreMessage_TMessageKey.TYPE);
//                Form_FormItemDB.insertRecord(item.getContentValues());
//            }
//            App.postUI(Form_B.FORM_PUSH, form);
//        }
    
}
