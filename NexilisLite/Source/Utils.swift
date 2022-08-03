//
//  Utils.swift
//  Runner
//
//  Created by Rifqy Fakhrul Rijal on 13/08/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import UIKit
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

public final class Utils {
    
    public static func getCurrentTime()->Int64 {
        return Int64(Date().timeIntervalSince1970)
    }
    
    public static func getCurrentTimeMillis()->Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    public static func getCurrentTimeNanos()->Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000_000_000)
    }
    
    public static func getElapsedRealtime() -> Int64 {
        return Int64((ProcessInfo().systemUptime).rounded()) // SystemClock.elapsedRealtime();
    }
    
    public static func getElapsedRealtimeMillis() -> Int64 {
        return Int64((ProcessInfo().systemUptime * 1000).rounded()) // SystemClock.elapsedRealtime();
    }
    
    public static func getElapsedRealtimeNanos() -> Int64 {
        return Int64((ProcessInfo().systemUptime * 1000_000_000).rounded()) // SystemClock.elapsedRealtimeNano();
    }
    
    public static func sGetCurrentDateTime(sFormat: String!) -> String! {
        let todaysDate = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = sFormat
        return dateFormatter.string(from: todaysDate as Date)
    }
    
    public static func getMD5(string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }
    
    static let callDurationFormatter: DateComponentsFormatter = {
        let dateFormatter: DateComponentsFormatter
        dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .positional
        dateFormatter.allowedUnits = [.minute, .second]
        dateFormatter.zeroFormattingBehavior = .pad
        
        return dateFormatter
    }()
    
    public static func previewMessageText(chat: Chat) -> Any {
        if chat.attachmentFlag == "27" {
            return "📄 " + "Live Streaming".localized()
        } else if !chat.image.isEmpty {
            if !chat.messageText.isEmpty {
                return "📷 \(chat.messageText)".richText(isUcList: true)
            } else {
                return "📷 " + "Photo".localized()
            }
        }
        else if !chat.video.isEmpty {
            if !chat.messageText.isEmpty {
                return "📹 \(chat.messageText)".richText(isUcList: true)
            } else {
                return "📹 " + "Video".localized()
            }
        }
        else if !chat.file.isEmpty {
            if chat.messageScope == "18" {
                return "📄 Form"
            }
            print("KACAU \(chat.messageText)")
            return "📄 " + chat.messageText.components(separatedBy: "|")[0]
        } else if chat.attachmentFlag == "11" {
            return "❤️ " + "Sticker".localized()
        }
        else {
            return chat.messageText.richText(isUcList: true)
        }
    }
    
}
public extension UIImage {
    var jpeg: Data? { jpegData(compressionQuality: 1) }  // QUALITY min = 0 / max = 1
    var png: Data? { pngData() }
}

public extension Data {
    var uiImage: UIImage? { UIImage(data: self) }
}
public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}
