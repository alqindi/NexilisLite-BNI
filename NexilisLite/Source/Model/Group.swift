//
//  Group.swift
//  Qmera
//
//  Created by Yayan Dwi on 28/09/21.
//

import Foundation

public class Group: Model {
    
    public let id: String
    public let name: String
    public var profile: String
    public let quote: String
    public let by: String
    public let date: String
    public let parent: String
    public let chatId: String
    public var isOpen: String
    public let official: String
    public let isEducation: String
    public let groupType: String
    public let isLounge: Bool
    public var topics: [Topic] = []
    public var childs: [Group] = []
    public var members: [Member] = []
    public let level: String
    
    public var isSelected = false
    
    public init(id: String, name: String, profile: String, quote: String, by: String, date: String, parent: String, chatId: String = "", groupType: String, isOpen: String, official: String, isEducation: String = "", isLounge: Bool = false, level: String = "") {
        self.id = id
        self.name = name
        self.profile = profile
        self.quote = quote
        self.by = by
        self.date = date
        self.parent = parent
        self.chatId = chatId
        self.groupType = groupType
        self.isOpen = isOpen
        self.official = official
        self.isEducation = isEducation
        self.isLounge = isLounge
        self.level = level
    }
    
    var isInternal: Bool {
        return isEducation == "2" || isEducation == "3" || isEducation == "4"
    }
    
    public var description: String {
        return "(\(id), \(name), \(chatId), \(groupType), \(childs)"
    }
    
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.id == rhs.id
    }
    
    
    
}

public class Topic: Model {
    
    public let chatId: String
    public let title: String
    public let thumb: String
    
    public init(chatId: String, title: String, thumb: String) {
        self.chatId = chatId
        self.title = title
        self.thumb = thumb
    }
    
    public static func == (lhs: Topic, rhs: Topic) -> Bool {
        return lhs.chatId == rhs.chatId
    }
    
    public var description: String {
        return ""
    }
    
}

public class Member: User {
    
    public var position: String
    
    override init(pin: String) {
        self.position = "0"
        super.init(pin: pin)
    }
    
    public init(pin: String, firstName: String, lastName: String, thumb: String, position: String) {
        self.position = position
        super.init(pin: pin, firstName: firstName, lastName: lastName, thumb: thumb)
    }
    
}
