//
//  OutgoingThread.swift
//  Runner
//
//  Created by Yayan Dwi on 20/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import FMDB

class OutgoingThread {
    
    static let `default` = OutgoingThread()
    
    private var isRunning = false
    
    private var semaphore = DispatchSemaphore(value: 0)
    
    private var connection = DispatchSemaphore(value: 0)
    
    private var dispatchQueue = DispatchQueue(label: "OutgoingThread")
    
    private var queue = [TMessage]()
    
    init() {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message from OUTGOING") {
                while cursor.next() {
                    if let message = cursor.string(forColumnIndex: 0) {
                        addQueue(message: TMessage(data: message))
                    }
                }
                cursor.close()
            }
        })
    }
    
    func addQueue(message: TMessage) {
        queue.append(message)
        semaphore.signal()
        addOugoing(message: message)
    }
    
    private func addQueue(_ message: TMessage, at: Int) {
        Thread.sleep(forTimeInterval: 1)
        queue.insert(message, at: at)
        semaphore.signal()
    }
    
    private func addOugoing(message: TMessage) {
        DispatchQueue.global().async {
            let messageId = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
            if !messageId.isEmpty {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "OUTGOING", cvalues: [
                            "id" : messageId,
                            "message" : message.pack(),
                        ], replace: true)
                    } catch {
                        rollback.pointee = true
                        print(error)
                    }
                })
            }
        }
    }
    
    private func delOutgoing(fmdb: Any, messageId: String) {
        _ = Database.shared.deleteRecord(fmdb: fmdb as! FMDatabase, table: "OUTGOING", _where: "id = '\(messageId)'")
    }
    
    func delOutgoing(fmdb: Any, packageId: String) {
        _ = Database.shared.deleteRecord(fmdb: fmdb as! FMDatabase, table: "OUTGOING", _where: "package = '\(packageId)'")
    }
    
    private var isWait = false
    
    func set(wait: Bool) {
        isWait = wait
        if !isWait {
            connection.signal()
        }
    }
    
    func getQueue() -> TMessage {
        while queue.isEmpty || queue.count == 0 {
            print("QUEUE.wait")
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
                if self.isWait {
                    print("CONNECTION.wait")
                    self.connection.wait()
                }
                self.process(message: self.getQueue())
            }
        }
    }
    
    private func process(message: TMessage) {
        print("outgoing process", message.toLogString())
        if message.getCode() == CoreMessage_TMessageCode.SEND_CHAT {
            sendChat(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.DELETE_CTEXT {
            deleteMessage(message: message)
        }
    }
    
    /**
     *
     */
    
    private func sendChat(message: TMessage) {
        Nexilis.saveMessage(message: message)
        print("save message sendChat")
        
        // if media exist upload first
        var fileName = message.getBody(key: CoreMessage_TMessageKey.IMAGE_ID, default_value: "")
        if fileName.isEmpty {
            fileName = message.getBody(key: CoreMessage_TMessageKey.AUDIO_ID)
        }
        if fileName.isEmpty {
            fileName = message.getBody(key: CoreMessage_TMessageKey.VIDEO_ID)
        }
        if fileName.isEmpty {
            fileName = message.getBody(key: CoreMessage_TMessageKey.FILE_ID)
        }
        let isMedia = !fileName.isEmpty
        if isMedia {
            if (!message.getBody(key: CoreMessage_TMessageKey.THUMB_ID).isEmpty) {
                Network().upload(name: message.getBody(key: CoreMessage_TMessageKey.THUMB_ID)) { (result, progress) in
                    if result, progress == 100 {
                        do {
                            let fileManager = FileManager.default
                            let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                            let fileDir = documentDir.appendingPathComponent(message.getBody(key: CoreMessage_TMessageKey.THUMB_ID))
                            let path = fileDir.path
                            if FileManager.default.fileExists(atPath: path) {
                                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                                message.setMedia(media: [UInt8] (data))
                            }
                        } catch {}
                        Network().upload(name: fileName) { (result, progress) in
                            if result {
                                if let delegate = Nexilis.shared.messageDelegate {
                                    delegate.onUpload(name: fileName, progress: progress)
                                }
                                if progress == 100 {
                                    if let response = Nexilis.writeSync(message: message) {
                                        print("sendChat", response.toLogString())
                                        let messageId = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                "status" : response.getBody(key: CoreMessage_TMessageKey.STATUS, default_value: "2")
                                            ], _where: "message_id = '\(messageId)'")
                                            self.delOutgoing(fmdb: fmdb, messageId: messageId)
                                        })
                                    } else {
                                        self.addQueue(message, at: 0)
                                    }
                                }
                            } else {
                                self.addQueue(message, at: 0)
                            }
                        }
                    }
                }
            } else {
                Network().upload(name: fileName) { (result, progress) in
                    if result {
                        if let delegate = Nexilis.shared.messageDelegate {
                            delegate.onUpload(name: fileName, progress: progress)
                        }
                        if progress == 100 {
                            if let response = Nexilis.writeSync(message: message) {
                                print("sendChat", response.toLogString())
                                let messageId = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                        "status" : response.getBody(key: CoreMessage_TMessageKey.STATUS, default_value: "2")
                                    ], _where: "message_id = '\(messageId)'")
                                    self.delOutgoing(fmdb: fmdb, messageId: messageId)
                                })
                            } else {
                                self.addQueue(message, at: 0)
                            }
                        }
                    } else {
                        self.addQueue(message, at: 0)
                    }
                }
            }
        } else {
            if let response = Nexilis.writeSync(message: message) {
                print("sendChat", response.toLogString())
                let messageId = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "status" : response.getBody(key: CoreMessage_TMessageKey.STATUS, default_value: "2")
                    ], _where: "message_id = '\(messageId)'")
                    self.delOutgoing(fmdb: fmdb, messageId: messageId)
                })
            } else {
                self.addQueue(message, at: 0)
            }
        }
    }
    
    private func deleteMessage(message: TMessage) {
        let messageId = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
        let type = message.getBody(key: CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG)
        
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if type == "1" {
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
                ], _where: "message_id = '\(messageId)'")
                if let package = Nexilis.write(message: message) {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "OUTGOING", cvalues: [
                        "package" : package
                    ], _where: "id = '\(messageId)'")
                }
                if let delegate = Nexilis.shared.messageDelegate {
                    delegate.onMessage(message: message)
                }
            } else {
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "message_id = '\(messageId)'")
                _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "message_id = '\(messageId)'")
                let l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
                let chat = message.getBody(key: CoreMessage_TMessageKey.CHAT_ID)
                var lastMessage: String?
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where opposite_pin = '\(l_pin)' order by server_date desc limit 1"), cursor.next() {
                    lastMessage = cursor.string(forColumnIndex: 0)
                    cursor.close()
                }
                if let l = lastMessage {
                    do {
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                            "l_pin" : chat.isEmpty ? l_pin : chat,
                            "message_id" : l,
                            "counter" : 0
                        ], replace: true)
                    } catch {
                        rollback.pointee = true
                        print(error)
                    }
                }
                self.delOutgoing(fmdb: fmdb, messageId: messageId)
            }
        })
    }
    
}
