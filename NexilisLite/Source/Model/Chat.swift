//
//  Chat.swift
//  Qmera
//
//  Created by Yayan Dwi on 14/10/21.
//

import Foundation

public class Chat: Model {
    
    public let pin: String
    public let messageId: String
    public let counter: String
    public let messageText: String
    public let serverDate: String
    public let image: String
    public let video: String
    public let file: String
    public let attachmentFlag: String
    public let messageScope: String
    public let name: String
    public let profile: String
    public let official: String
    
    public init(pin: String) {
        self.pin = pin
        self.messageId = ""
        self.counter = ""
        self.messageText = ""
        self.serverDate = ""
        self.image = ""
        self.video = ""
        self.file = ""
        self.attachmentFlag = ""
        self.messageScope = ""
        self.name = ""
        self.profile = ""
        self.official = ""
    }
    
    public init(pin: String, messageId: String, counter: String, messageText: String, serverDate: String, image: String, video: String, file: String, attachmentFlag: String, messageScope: String, name: String, profile: String, official: String ) {
        self.pin = pin
        self.messageId = messageId
        self.counter = counter
        self.messageText = messageText
        self.serverDate = serverDate
        self.image = image
        self.video = video
        self.file = file
        self.attachmentFlag = attachmentFlag
        self.messageScope = messageScope
        self.name = name
        self.profile = profile
        self.official = official
    }
    
    public static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.pin == rhs.pin
    }
    
    public var description: String {
        return ""
    }
    
    public static func getData(messageId: String = "") -> [Chat] {
        var chats: [Chat] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let query = """
                            select ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.first_name || ' ' || ifnull(b.last_name, '') name, b.image_id profile, b.official_account from MESSAGE_SUMMARY ms, MESSAGE m, BUDDY b where ms.message_id = m.message_id and ms.l_pin = b.f_pin \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'")
                            union
                            select ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, 'Bot' name, '' profile, '' from MESSAGE_SUMMARY ms, MESSAGE m where ms.message_id = m.message_id and ms.l_pin = '-999' \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'")
                            union
                            select ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.f_name || ' (\("Lounge".localized()))', b.image_id profile, b.official from MESSAGE_SUMMARY ms, MESSAGE m, GROUPZ b where ms.message_id = m.message_id and ms.l_pin = b.group_id \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'")
                            union
                            select ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, c.f_name || ' (' || b.title || ')', b.thumb profile, '' from MESSAGE_SUMMARY ms, MESSAGE m, DISCUSSION_FORUM b, GROUPZ c where ms.message_id = m.message_id and ms.l_pin = b.chat_id and b.group_id = c.group_id \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'")
                            order by 5 desc
                            """
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    while cursorData.next() {
                        let chat = Chat(pin: cursorData.string(forColumnIndex: 0) ?? "",
                                        messageId: cursorData.string(forColumnIndex: 1) ?? "",
                                        counter: cursorData.string(forColumnIndex: 2) ?? "",
                                        messageText: cursorData.string(forColumnIndex: 3) ?? "",
                                        serverDate: cursorData.string(forColumnIndex: 4) ?? "",
                                        image: cursorData.string(forColumnIndex: 5) ?? "",
                                        video: cursorData.string(forColumnIndex: 6) ?? "",
                                        file: cursorData.string(forColumnIndex: 7) ?? "",
                                        attachmentFlag: cursorData.string(forColumnIndex: 8) ?? "",
                                        messageScope: cursorData.string(forColumnIndex: 9) ?? "",
                                        name: cursorData.string(forColumnIndex: 10) ?? "",
                                        profile: cursorData.string(forColumnIndex: 11) ?? "",
                                        official: cursorData.string(forColumnIndex: 12) ?? "")
                        chats.append(chat)
                    }
                    cursorData.close()
                    if chats.count == 0 {
                        if let cursorCounter = Database.shared.getRecords(fmdb: fmdb, query: "SELECT SUM(counter) FROM MESSAGE_SUMMARY"), cursorCounter.next() {
                            if cursorCounter.int(forColumnIndex: 0) != 0 {
                                _ = Database.shared.updateAllRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                                    "counter" : 0
                                ])
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                            }
                            cursorCounter.close()
                        }
                    }
                }
            } catch {
                rollback.pointee = true
                print(error)
            }
        })
        return chats
    }
    
}
