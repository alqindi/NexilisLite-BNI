//
//  User.swift
//  Qmera
//
//  Created by Yayan Dwi on 28/09/21.
//

import Foundation

public class User: Model {
    
    let pin: String
    let firstName: String
    let lastName: String
    var thumb: String
    var official: String?
    var userType: String?
    var privacy_flag: String?
    var offline_mode: String?
    var ex_block: String?
    var ex_offmp: String?
    
    var isSelected: Bool = false
    
    init(pin: String) {
        self.pin = pin
        self.firstName = ""
        self.lastName = ""
        self.thumb = ""
        self.userType = ""
        self.privacy_flag = ""
        self.offline_mode = ""
        self.ex_block = ""
        self.ex_offmp = ""
    }
    
    init(pin: String, firstName: String, lastName: String, thumb: String, userType: String = "0", privacy_flag: String = "", offline_mode: String = "", ex_block: String = "", official: String = "", ex_offmp: String = "") {
        self.pin = pin
        self.firstName = firstName
        self.lastName = lastName
        self.thumb = thumb
        self.userType = userType
        self.privacy_flag = privacy_flag
        self.offline_mode = offline_mode
        self.official = official
        self.ex_block = ex_block
        self.ex_offmp = ex_offmp
    }
    
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.pin == rhs.pin
    }
    
    public var description: String {
        return "\(pin) \(firstName) \(lastName) \(thumb)"
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    public static func getData(pin: String?) -> User? {
        guard let pin = pin else {
            return nil
        }
        var user: User?
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, image_id, user_type, privacy_flag, offline_mode, ex_block from BUDDY where f_pin = '\(pin)'"), cursor.next() {
                user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                            firstName: cursor.string(forColumnIndex: 1) ?? "",
                            lastName: cursor.string(forColumnIndex: 2) ?? "",
                            thumb: cursor.string(forColumnIndex: 3) ?? "",
                            userType: cursor.string(forColumnIndex: 4) ?? "",
                            privacy_flag: cursor.string(forColumnIndex: 5) ?? "",
                            offline_mode: cursor.string(forColumnIndex: 6) ?? "",
                            ex_block: cursor.string(forColumnIndex: 7) ?? "")
                cursor.close()
            }
        })
        return user
    }
    
}
