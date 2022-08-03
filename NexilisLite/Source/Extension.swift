//
//  StringUtil.swift
//  Runner
//
//  Created by Yayan Dwi on 20/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

extension Date {
    
    public func currentTimeMillis() -> Int {
        return Int(self.timeIntervalSince1970 * 1000)
    }
    
    func format(dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }
    
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    public init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension String {
    
    func toNormalString() -> String {
        let _source = self.replacingOccurrences(of: "+", with: "%20")
        if var result = _source.removingPercentEncoding {
            result = result.replacingOccurrences(of: "<NL>", with: "\n")
            result = result.replacingOccurrences(of: "<CR>", with: "\r")
            return decrypt(source: result)
        }
        return self
    }
    
    func toStupidString() -> String {
        if var result = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            result = result.replacingOccurrences(of: "\n", with: "<NL>")
            result = result.replacingOccurrences(of: "\r", with: "<CR>")
            result = result.replacingOccurrences(of: "+", with: "%2B")
            return result
        }
        return self
    }
    
    private func decrypt(source : String) -> String {
        if let result = source.removingPercentEncoding {
            return result
        }
        return source
    }
    
    public func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
}

extension Int {
    
    func toHex() -> String {
        return String(format: "%02X", self)
    }
    
}

extension UIApplication {
    public static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    var rootViewController: UIViewController? {
        return UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
    }
    
    var visibleViewController: UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}

extension UIView {
    
    public func anchor(top: NSLayoutYAxisAnchor? = nil,
                left: NSLayoutXAxisAnchor? = nil,
                bottom: NSLayoutYAxisAnchor? = nil,
                right: NSLayoutXAxisAnchor? = nil,
                paddingTop: CGFloat = 0,
                paddingLeft: CGFloat = 0,
                paddingBottom: CGFloat = 0,
                paddingRight: CGFloat = 0,
                centerX: NSLayoutXAxisAnchor? = nil,
                centerY: NSLayoutYAxisAnchor? = nil,
                width: CGFloat = 0,
                height: CGFloat = 0,
                minHeight: CGFloat = 0,
                maxHeight: CGFloat = 0,
                minWidth: CGFloat = 0,
                maxWidth: CGFloat = 0,
                dynamicLeft: Bool = false,
                dynamicRight: Bool = false) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        if let left = left {
            if dynamicLeft {
                leftAnchor.constraint(greaterThanOrEqualTo: left, constant: paddingLeft).isActive = true
            } else {
                leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
            }
        }
        if let right = right {
            if dynamicRight {
                leftAnchor.constraint(lessThanOrEqualTo: right, constant: -paddingRight).isActive = true
            } else {
                rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
            }
        }
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        if let centerX = centerX {
            centerXAnchor.constraint(equalTo: centerX).isActive = true
        }
        if let centerY = centerY {
            centerYAnchor.constraint(equalTo: centerY).isActive = true
        }
        if height != 0 || minHeight != 0 || maxHeight != 0 {
            if minHeight != 0 && maxHeight != 0 {
                heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
                heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight).isActive = true
            } else if minHeight != 0 && maxHeight == 0 {
                heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
            } else if minHeight == 0 && maxHeight != 0 {
                heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight).isActive = true
            } else {
                heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        }
        if width != 0 || minWidth != 0 || maxWidth != 0 {
            if minWidth != 0 && maxWidth != 0 {
                heightAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
                heightAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
            } else if minWidth != 0 && maxWidth == 0 {
                heightAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
            } else if minWidth == 0 && maxWidth != 0 {
                heightAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
            } else {
                widthAnchor.constraint(equalToConstant: width).isActive = true
            }
        }
    }
    
}

extension UIViewController {
    
    var previousViewController: UIViewController? {
        guard let navigationController = navigationController else { return nil }
        let count = navigationController.viewControllers.count
        return count < 2 ? nil : navigationController.viewControllers[count - 2]
    }
    
}

extension UIImage {
    func resize(target: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = target.width / size.width
        let heightRatio = target.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}

extension UIImage {
    
    var isPortrait:  Bool    { size.height > size.width }
    var isLandscape: Bool    { size.width > size.height }
    var breadth:     CGFloat { min(size.width, size.height) }
    var breadthSize: CGSize  { .init(width: breadth, height: breadth) }
    var breadthRect: CGRect  { .init(origin: .zero, size: breadthSize) }
    public var circleMasked: UIImage? {
        guard let cgImage = cgImage?
                .cropping(to: .init(origin: .init(x: isLandscape ? ((size.width-size.height)/2).rounded(.down) : 0,
                                                  y: isPortrait  ? ((size.height-size.width)/2).rounded(.down) : 0),
                                    size: breadthSize)) else { return nil }
        let format = imageRendererFormat
        format.opaque = false
        return UIGraphicsImageRenderer(size: breadthSize, format: format).image { _ in
            UIBezierPath(ovalIn: breadthRect).addClip()
            UIImage(cgImage: cgImage, scale: format.scale, orientation: imageOrientation)
                .draw(in: .init(origin: .zero, size: breadthSize))
        }
    }
    
}

extension NSObject {
    
    private static var urlStore = [String:String]()

    public func getImage(name url: String, placeholderImage: UIImage? = nil, isCircle: Bool = false, tableView: UITableView? = nil, indexPath: IndexPath? = nil, completion: @escaping (Bool, Bool, UIImage?)->()) {
        let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
        type(of: self).urlStore[tmpAddress] = url
        if url.isEmpty {
            completion(false, false, placeholderImage)
            return
        }
        do {
            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let file = documentDir.appendingPathComponent(url)
            if FileManager().fileExists(atPath: file.path) {
                let image = UIImage(contentsOfFile: file.path)?.sd_resizedImage(with: CGSize(width: 400, height: 400), scaleMode: .aspectFill)
                completion(true, false, isCircle ? image?.circleMasked : image)
            } else {
                completion(false, false, placeholderImage)
                Download().start(forKey: url) { (name, progress) in
                    guard progress == 100 else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if tableView != nil {
                            tableView!.beginUpdates()
                            tableView!.reloadRows(at: [indexPath!], with: .none)
                            tableView!.endUpdates()
                        }
                        if type(of: self).urlStore[tmpAddress] == name {
                            let image = UIImage(contentsOfFile: file.path)?.sd_resizedImage(with: CGSize(width: 400, height: 400), scaleMode: .aspectFill)
                            completion(true, true, isCircle ? image?.circleMasked : image)
                        }
                    }
                }
            }
        } catch {}
    }
    
    func loadImage(named: String, placeholderImage: UIImage?, completion: @escaping (UIImage?, Bool) -> ()) {
        guard !named.isEmpty else {
            completion(placeholderImage, true)
            return
        }
        SDWebImageManager.shared.loadImage(with: URL.palioImage(named: named), options: .highPriority, progress: .none) { image, data, error, type, finish, url in
            completion(image, finish)
        }
    }
    
    public func deleteAllRecordDatabase() {
        Database.shared.database?.inTransaction({ fmdb, rollback in
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "BUDDY", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "POST", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_STATUS", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "OUTGOING", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "FOLLOW", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_FAVORITE", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "LINK_PREVIEW", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "PULL_DB", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "PREFS", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "FORM", _where: "")
            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "FORM_ITEM", _where: "")
        })
    }
    
}

extension URL {
    
    static func palioImage(named: String) -> URL? {
        return URL(string: "http://202.158.33.26/filepalio/image/\(named)")
    }
    
}

extension UIColor {
    public static var mainColor: UIColor {
        renderColor(hex: "#000000")
    }
    
    public static var secondaryColor: UIColor {
        return renderColor(hex: "#FAFAFF")
    }
    
    public static var orangeColor: UIColor {
        return renderColor(hex: "#FFA03E")
    }
    
    public static var orangeBNI: UIColor {
        return renderColor(hex: "#EE6600")
    }
    
    public static var greenColor: UIColor {
        return renderColor(hex: "#C7EA46")
    }
    
    public static var grayColor: UIColor {
        return renderColor(hex: "#F5F5F5")
    }
    
    public static var docColor: UIColor {
        return renderColor(hex: "#798F9A")
    }
    
    public static var linkColor: UIColor {
        return renderColor(hex: "#68BBE3")
    }
    
    public static var blueBubbleColor: UIColor {
        return renderColor(hex: "#C5D1E1")
    }
    
    public class func renderColor(hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UIView {
    
    public func circle() {
        layer.cornerRadius = 0.5 * bounds.size.width
        clipsToBounds = true
    }
    
    public func maxCornerRadius() -> CGFloat {
        return (self.frame.width > self.frame.height) ? self.frame.height / 2 : self.frame.width / 2
    }
    
}

extension String {
    
    public func localized() -> String {
        if let _ = UserDefaults.standard.string(forKey: "i18n_language") {} else {
            // we set a default, just in case
            UserDefaults.standard.set("en", forKey: "i18n_language")
            UserDefaults.standard.synchronize()
        }
        let lang = UserDefaults.standard.string(forKey: "i18n_language")
        let bundle = Bundle.resourceBundle(for: Nexilis.self).path(forResource: lang, ofType: "lproj")
        let bundlePath = Bundle(path: bundle!)
        print()
        return NSLocalizedString(
            self,
            tableName: "Localizable",
            bundle: bundlePath!,
            value: self,
            comment: self)
    }
    
}

extension UIViewController {
    
    public func showToast(message : String, font: UIFont = UIFont.systemFont(ofSize: 12, weight: .medium), controller: UIViewController) {
        
        let toastContainer = UIView(frame: CGRect())
        toastContainer.backgroundColor = UIColor.mainColor.withAlphaComponent(0.6)
        toastContainer.alpha = 0.0
        toastContainer.layer.cornerRadius = 25;
        toastContainer.clipsToBounds  =  true
        
        let toastLabel = UILabel(frame: CGRect())
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = font
        toastLabel.text = message
        toastLabel.clipsToBounds  =  true
        toastLabel.numberOfLines = 0
        
        toastContainer.addSubview(toastLabel)
        controller.view.addSubview(toastContainer)
        controller.view.bringSubviewToFront(toastContainer)
        
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let a1 = NSLayoutConstraint(item: toastLabel, attribute: .leading, relatedBy: .equal, toItem: toastContainer, attribute: .leading, multiplier: 1, constant: 15)
        let a2 = NSLayoutConstraint(item: toastLabel, attribute: .trailing, relatedBy: .equal, toItem: toastContainer, attribute: .trailing, multiplier: 1, constant: -15)
        let a3 = NSLayoutConstraint(item: toastLabel, attribute: .bottom, relatedBy: .equal, toItem: toastContainer, attribute: .bottom, multiplier: 1, constant: -15)
        let a4 = NSLayoutConstraint(item: toastLabel, attribute: .top, relatedBy: .equal, toItem: toastContainer, attribute: .top, multiplier: 1, constant: 15)
        toastContainer.addConstraints([a1, a2, a3, a4])
        
        let c1 = NSLayoutConstraint(item: toastContainer, attribute: .leading, relatedBy: .equal, toItem: controller.view, attribute: .leading, multiplier: 1, constant: 65)
        let c2 = NSLayoutConstraint(item: toastContainer, attribute: .trailing, relatedBy: .equal, toItem: controller.view, attribute: .trailing, multiplier: 1, constant: -65)
        let c3 = NSLayoutConstraint(item: toastContainer, attribute: .bottom, relatedBy: .equal, toItem: controller.view, attribute: .bottom, multiplier: 1, constant: -75)
        controller.view.addConstraints([c1, c2, c3])
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
            toastContainer.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1.5, options: .curveEaseOut, animations: {
                toastContainer.alpha = 0.0
            }, completion: {_ in
                toastContainer.removeFromSuperview()
            })
        })
    }
    
    public func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0);
        image.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
}

extension UITextView {

    enum ShouldChangeCursor {
        case incrementCursor
        case preserveCursor
    }

    func preserveCursorPosition(withChanges mutatingFunction: (UITextPosition?) -> (ShouldChangeCursor)) {

        //save the cursor positon
        var cursorPosition: UITextPosition? = nil
        if let selectedRange = self.selectedTextRange {
            let offset = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
            cursorPosition = self.position(from: self.beginningOfDocument, offset: offset)
        }

        //make mutaing changes that may reset the cursor position
        let shouldChangeCursor = mutatingFunction(cursorPosition)

        //restore the cursor
        if var cursorPosition = cursorPosition {

            if shouldChangeCursor == .incrementCursor {
                cursorPosition = self.position(from: cursorPosition, offset: 1) ?? cursorPosition
            }

            if let range = self.textRange(from: cursorPosition, to: cursorPosition) {
                self.selectedTextRange = range
            }
        }

    }

}

extension String {
    
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return String(self[startIndex ..< endIndex])
    }
    
    func countEmojiCharacter() -> Int {
        
        func isEmoji(s:NSString) -> Bool {
            
            let high:Int = Int(s.character(at: 0))
            if 0xD800 <= high && high <= 0xDBFF {
                let low:Int = Int(s.character(at: 1))
                let codepoint: Int = ((high - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000
                return (0x1D000 <= codepoint && codepoint <= 0x1F9FF)
            }
            else {
                return (0x2100 <= high && high <= 0x27BF)
            }
        }
        
        let nsString = self as NSString
        var length = 0
        
        nsString.enumerateSubstrings(in: NSMakeRange(0, nsString.length), options: NSString.EnumerationOptions.byComposedCharacterSequences) { (subString, substringRange, enclosingRange, stop) -> Void in
            
            if isEmoji(s: subString! as NSString) {
                length+=1
            }
        }
        
        return length
    }
    
    public func richText(isUcList: Bool = false, isEditing: Bool = false, first: Int = 0, last: Int = 0) -> NSAttributedString {
        var font = UIFont.systemFont(ofSize: 12)
        if isUcList {
            font = UIFont.systemFont(ofSize: 10)
        }
        let textUTF8 = String(self.utf8)
        let finalText = NSMutableAttributedString(string: textUTF8, attributes: [NSAttributedString.Key.font: font])
        var boolStar = false
        var startStar = 0
        var endStar = 0
        
        var boolItalic = false
        var startItalic = 0
        var endItalic = 0
        
        var boolUnderLine = false
        var startUnderLine = 0
        var endUnderLine = 0
        
        var boolStrike = false
        var startStrike = 0
        var endStrike = 0
        
        var firstCount = 0
        var lastCount = textUTF8.count - 1
        if isEditing {
            firstCount = first
            lastCount = last
        }
        
        if textUTF8.count > 0 {
            for i in firstCount...lastCount {
                //BOLD
                if String(textUTF8.substring(from: i, to: i)) == "*" && !boolStar {
                    boolStar = true
                    startStar = i
                    startStar = startStar - (textUTF8.count - finalText.string.count)
                } else if String(textUTF8.substring(from: i, to: i)) == "*" && boolStar {
                    endStar = i
                    endStar = endStar - (self.count - finalText.string.count)
                    //!String(textUTF8.substring(from: startStar + 1, to: endStar)).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if (startStar - 1 == -1 || checkCharBeforeAfter(char: String(finalText.string.substring(from: startStar - 1, to: startStar - 1)))) && (endStar + 1 == finalText.string.count || checkCharBeforeAfter(char: String(finalText.string.substring(from: endStar + 1, to: endStar + 1)))) && endStar - startStar != 1 && !String(finalText.string.substring(from: startStar + 1, to: endStar - 1)).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let countEmoji = finalText.string.countEmojiCharacter()
                        finalText.addAttribute(.font, value: font.bold, range: NSRange(location: startStar, length: endStar - startStar + countEmoji + 1))
                        if !isEditing{
                            finalText.mutableString.replaceOccurrences(of: "*", with: "", options: .literal, range: NSRange(location: startStar, length: endStar - startStar + countEmoji + 1))
                        } else {
                            finalText.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(startStar + countEmoji...startStar + countEmoji))
                            finalText.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(endStar + countEmoji...endStar + countEmoji))
                        }
                        boolStar = false
                        startStar = 0
                    } else {
                        startStar = i
                        startStar = startStar - (textUTF8.count - finalText.string.count)
                    }
                }
                
                //ITALIC
                if String(textUTF8.substring(from: i, to: i)) == "_" && !boolItalic {
                    boolItalic = true
                    startItalic = i
                    startItalic = startItalic - (textUTF8.count - finalText.string.count)
                } else if String(textUTF8.substring(from: i, to: i)) == "_" && boolItalic {
                    endItalic = i
                    endItalic = endItalic - (textUTF8.count - finalText.string.count)
                    if (startItalic - 1 == -1 || checkCharBeforeAfter(char: String(finalText.string.substring(from: startItalic - 1, to: startItalic - 1)))) && (endItalic + 1 == finalText.string.count || checkCharBeforeAfter(char: String(finalText.string.substring(from: endItalic + 1, to: endItalic + 1)))) && endItalic - startItalic != 1 && !String(finalText.string.substring(from: startItalic + 1, to: endItalic - 1)).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let countEmoji = finalText.string.countEmojiCharacter()
                        finalText.addAttribute(.font, value: font.italic, range: NSRange(location: startItalic, length: endItalic - startItalic + (countEmoji + 1)))
                        if !isEditing{
                            finalText.mutableString.replaceOccurrences(of: "_", with: "", options: .literal, range: NSRange(location: startItalic, length: endItalic - startItalic + (countEmoji + 1)))
                        } else {
                            finalText.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(startItalic + countEmoji...startItalic + countEmoji))
                            finalText.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(endItalic + countEmoji...endItalic + countEmoji))
                        }
                        boolItalic = false
                        startItalic = 0
                    } else {
                        startItalic = i
                        startItalic = startItalic - (textUTF8.count - finalText.string.count)
                    }
                }
                
                //UNDERLINE
                if String(textUTF8.substring(from: i, to: i)) == "^" && !boolUnderLine {
                    boolUnderLine = true
                    startUnderLine = i
                    startUnderLine = startUnderLine - (textUTF8.count - finalText.string.count)
                } else if String(textUTF8.substring(from: i, to: i)) == "^" && boolUnderLine {
                    endUnderLine = i
                    endUnderLine = endUnderLine - (textUTF8.count - finalText.string.count)
                    if (startUnderLine - 1 == -1 || checkCharBeforeAfter(char: String(finalText.string.substring(from: startUnderLine - 1, to: startUnderLine - 1)))) && (endUnderLine + 1 == finalText.string.count || checkCharBeforeAfter(char: String(finalText.string.substring(from: endUnderLine + 1, to: endUnderLine + 1)))) && endUnderLine - startUnderLine != 1 && !String(finalText.string.substring(from: startUnderLine + 1, to: endUnderLine - 1)).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let countEmoji = finalText.string.countEmojiCharacter()
                        finalText.addAttribute(.underlineStyle, value: NSUnderlineStyle.thick.rawValue, range: NSRange(location: startUnderLine, length: endUnderLine - startUnderLine + (countEmoji + 1)))
                        if !isEditing{
                            finalText.mutableString.replaceOccurrences(of: "^", with: "", options: .literal, range: NSRange(location: startUnderLine, length: endUnderLine - startUnderLine + (countEmoji + 1)))
                        } else {
                            finalText.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(startUnderLine + countEmoji...startUnderLine + countEmoji))
                            finalText.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(endUnderLine + countEmoji...endUnderLine + countEmoji))
                        }
                        boolUnderLine = false
                        startUnderLine = 0
                    } else {
                        startUnderLine = i
                        startUnderLine = startUnderLine - (textUTF8.count - finalText.string.count)
                    }
                }
                
                //STRIKETHROUGH
                if String(textUTF8.substring(from: i, to: i)) == "~" && !boolStrike {
                    boolStrike = true
                    startStrike = i
                    startStrike = startStrike - (textUTF8.count - finalText.string.count)
                } else if String(textUTF8.substring(from: i, to: i)) == "~" && boolStrike {
                    endStrike = i
                    endStrike = endStrike - (textUTF8.count - finalText.string.count)
                    if (startStrike - 1 == -1 || checkCharBeforeAfter(char: String(finalText.string.substring(from: startStrike - 1, to: startStrike - 1)))) && (endStrike + 1 == finalText.string.count || checkCharBeforeAfter(char: String(finalText.string.substring(from: endStrike + 1, to: endStrike + 1)))) && endStrike - startStrike != 1 && !String(finalText.string.substring(from: startStrike + 1, to: endStrike - 1)).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let countEmoji = finalText.string.countEmojiCharacter()
                        finalText.addAttribute(.strikethroughStyle, value: 2, range: NSRange(location: startStrike, length: endStrike - startStrike + (countEmoji + 1)))
                        if !isEditing {
                            finalText.mutableString.replaceOccurrences(of: "~", with: "", options: .literal, range: NSRange(location: startStrike, length: endStrike - startStrike + (countEmoji + 1)))
                        } else {
                            finalText.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(startStrike + countEmoji...startStrike + countEmoji))
                            finalText.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(endStrike + countEmoji...endStrike + countEmoji))
                        }
                        boolStrike = false
                        startStrike = 0
                    } else {
                        startStrike = i
                        startStrike = startStrike - (textUTF8.count - finalText.string.count)
                    }
                }
            }
            if !isEditing {
                let listText = finalText.string.split(separator: " ")
                for i in 0...listText.count - 1 {
                    if listText[i].lowercased().checkStartWithLink() {
                        if ((listText[i].lowercased().starts(with: "www.") && listText[i].lowercased().split(separator: ".").count >= 3) || (!listText[i].lowercased().starts(with: "www.") && listText[i].lowercased().split(separator: ".").count >= 2)) && listText[i].lowercased().split(separator: ".").last!.count >= 2 {
                            if let range: Range<String.Index> = finalText.string.range(of: listText[i]) {
                                let index: Int = finalText.string.distance(from: finalText.string.startIndex, to: range.lowerBound)
                                finalText.addAttribute(.foregroundColor, value: UIColor.linkColor, range: NSRange(index...index + listText[i].count - 1))
                                finalText.addAttribute(.underlineStyle, value: NSUnderlineStyle.thick.rawValue, range: NSRange(index...index + listText[i].count - 1))
                            }
                        }
                    }
                }
            }
        }
        
        return finalText
    }
    
    func checkCharBeforeAfter(char: String) -> Bool {
        return char == " " || char == "\n" || char == "*" || char == "_" || char == "^" || char == "~"
    }
    
    func checkStartWithLink() -> Bool {
        return self.starts(with: "https://") || self.starts(with: "http://") || self.starts(with: "www.")
        //|| self.starts(with: "*https://") || self.starts(with: "*http://") || self.starts(with: "*www.") || self.starts(with: "_https://") || self.starts(with: "_http://") || self.starts(with: "_www.") || self.starts(with: "^https://") || self.starts(with: "^http://") || self.starts(with: "^www.") || self.starts(with: "~https://") || self.starts(with: "~http://") || self.starts(with: "~www.")
    }
    
}

extension UIFont {
    var bold: UIFont {
        return with(traits: .traitBold)
    } // bold
    
    var italic: UIFont {
        return with(traits: .traitItalic)
    } // italic
    
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        } // guard
        
        return UIFont(descriptor: descriptor, size: 0)
    } // with(traits:)
}

extension UILabel {
    public func set(image: UIImage, with text: String, size: CGFloat, y: CGFloat) {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: y, width: size, height: size)
        let attachmentStr = NSAttributedString(attachment: attachment)
        
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(attachmentStr)
        
        let textString = NSAttributedString(string: text, attributes: [.font: self.font!])
        mutableAttributedString.append(textString)
        
        self.attributedText = mutableAttributedString
    }
    
    public func setAttributeText(image: UIImage, with textMutable: NSAttributedString, size: CGFloat, y: CGFloat) {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: y, width: size, height: size)
        let attachmentStr = NSAttributedString(attachment: attachment)
        
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(attachmentStr)
        
        mutableAttributedString.append(textMutable)
        
        self.attributedText = mutableAttributedString
    }
}

extension Bundle {

    public static func resourceBundle(for frameworkClass: AnyClass) -> Bundle {
        guard let moduleName = String(reflecting: frameworkClass).components(separatedBy: ".").first else {
            fatalError("Couldn't determine module name from class \(frameworkClass)")
        }
        
        let frameworkBundle = Bundle(for: frameworkClass)

        guard let resourceBundleURL = frameworkBundle.url(forResource: "NexilisLite", withExtension: "bundle"),
              let resourceBundle = Bundle(url: resourceBundleURL) else {
            print("\(moduleName).bundle not found in \(frameworkBundle)")
            return frameworkBundle
        }

        return resourceBundle
    }
    
}

//extension UIFont {
//    
//    static func register(from url: URL) throws {
//        guard let fontDataProvider = CGDataProvider(url: url as CFURL) else {
//            throw fatalError("Could not create font data provider for \(url).")
//        }
//        let font = CGFont(fontDataProvider)
//        var error: Unmanaged<CFError>?
//        guard CTFontManagerRegisterGraphicsFont(font!, &error) else {
//            throw error!.takeUnretainedValue()
//        }
//    }
//    
//}

extension UIButton {
    private func actionHandleBlock(action:(() -> Void)? = nil) {
        struct __ {
            static var action :(() -> Void)?
        }
        if action != nil {
            __.action = action
        } else {
            __.action?()
        }
    }
    
    @objc private func triggerActionHandleBlock() {
        self.actionHandleBlock()
    }
    
    public func actionHandle(controlEvents control :UIControl.Event, ForAction action:@escaping () -> Void) {
        self.actionHandleBlock(action: action)
        self.addTarget(self, action: #selector(self.triggerActionHandleBlock), for: control)
    }
}

extension UINavigationController {
    func replaceAllViewController(with viewController: UIViewController, animated: Bool) {
        pushViewController(viewController, animated: animated)
        viewControllers.removeSubrange(1...viewControllers.count - 2)
    }
    
    var rootViewController : UIViewController? {
        return viewControllers.first
    }
}

extension UIImageView {

    private static var taskKey = 0
    private static var urlKey = 0

    private var currentTask: URLSessionTask? {
        get { return objc_getAssociatedObject(self, &UIImageView.taskKey) as? URLSessionTask }
        set { objc_setAssociatedObject(self, &UIImageView.taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var currentURL: URL? {
        get { return objc_getAssociatedObject(self, &UIImageView.urlKey) as? URL }
        set { objc_setAssociatedObject(self, &UIImageView.urlKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func loadImageAsync(with urlString: String?) {
        // cancel prior task, if any

        weak var oldTask = currentTask
        currentTask = nil
        oldTask?.cancel()

        // reset imageview's image

        self.image = nil

        // allow supplying of `nil` to remove old image and then return immediately

        guard let urlString = urlString else { return }

        // check cache

        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            self.image = cachedImage
            return
        }

        // download

        let url = URL(string: urlString)!
        currentURL = url
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            self?.currentTask = nil

            //error handling

            if let error = error {
                // don't bother reporting cancelation errors

                if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorCancelled {
                    return
                }

                print(error)
                return
            }

            guard let data = data, let downloadedImage = UIImage(data: data) else {
                print("unable to extract image")
                return
            }

            ImageCache.shared.save(image: downloadedImage, forKey: urlString)

            if url == self?.currentURL {
                DispatchQueue.main.async {
                    self?.image = downloadedImage
                }
            }
        }

        // save and start new task

        currentTask = task
        task.resume()
    }
    
    private func actionHandleBlock(action:(() -> Void)? = nil) {
        struct __ {
            static var action :(() -> Void)?
        }
        if action != nil {
            __.action = action
        } else {
            __.action?()
        }
    }
    
    @objc private func triggerActionHandleBlock() {
        self.actionHandleBlock()
    }
    
    func actionHandle(controlEvents control :UIControl.Event, ForAction action:@escaping () -> Void) {
        self.actionHandleBlock(action: action)
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.triggerActionHandleBlock)))
    }

}

extension UITextField {

    public enum PaddingSide {
        case left(CGFloat)
        case right(CGFloat)
        case both(CGFloat)
    }

    public func addPadding(_ padding: PaddingSide) {

        self.leftViewMode = .always
        self.layer.masksToBounds = true


        switch padding {

        case .left(let spacing):
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
            self.leftView = paddingView
            self.rightViewMode = .always

        case .right(let spacing):
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
            self.rightView = paddingView
            self.rightViewMode = .always

        case .both(let spacing):
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: self.frame.height))
            // left
            self.leftView = paddingView
            self.leftViewMode = .always
            // right
            self.rightView = paddingView
            self.rightViewMode = .always
        }
    }
}

class ImageCache {
    private let cache = NSCache<NSString, UIImage>()
    private var observer: NSObjectProtocol!

    static let shared = ImageCache()

    private init() {
        // make sure to purge cache on memory pressure

        observer = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: nil) { [weak self] notification in
            self?.cache.removeAllObjects()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(observer as Any)
    }

    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func save(image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

//let alert = UIAlertController(title: "", message: "\n\n\n\n\n\n\n\n\n\n".localized(), preferredStyle: .alert)
//let newWidth = UIScreen.main.bounds.width * 0.90 - 270
//// update width constraint value for main view
//if let viewWidthConstraint = alert.view.constraints.filter({ return $0.firstAttribute == .width }).first{
//    viewWidthConstraint.constant = newWidth
//}
//// update width constraint value for container view
//if let containerViewWidthConstraint = alert.view.subviews.first?.constraints.filter({ return $0.firstAttribute == .width }).first {
//    containerViewWidthConstraint.constant = newWidth
//}
//let titleFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.black]
//let titleAttrString = NSMutableAttributedString(string: m["MERNAM"]!.localized(), attributes: titleFont)
//alert.setValue(titleAttrString, forKey: "attributedTitle")
//alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = .lightGray
//alert.view.tintColor = .black
//if fileType != BroadcastViewController.FILE_TYPE_CHAT{
//    let height:NSLayoutConstraint = NSLayoutConstraint(item: alert.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: UIScreen.main.bounds.height * 0.6)
//    alert.view.addConstraint(height)
//}
//
//var containerView = UIView(frame: CGRect(x: 20, y: 60, width: alert.view.bounds.size.width * 0.9 - 40, height: 350))
//if fileType == BroadcastViewController.FILE_TYPE_CHAT {
//    containerView = UIView(frame: CGRect(x: 20, y: 60, width: alert.view.bounds.size.width * 0.9 - 40, height: 100))
//}
//alert.view.addSubview(containerView)
//containerView.layer.cornerRadius = 10.0
//containerView.clipsToBounds = true
//
//let buttonClose = UIButton(type: .close)
//buttonClose.frame = CGRect(x: alert.view.bounds.size.width * 0.9 - 50, y: 15, width: 30, height: 30)
//buttonClose.layer.cornerRadius = 15.0
//buttonClose.clipsToBounds = true
//buttonClose.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
//buttonClose.actionHandle(controlEvents: .touchUpInside,
// ForAction:{() -> Void in
//    alert.dismiss(animated: true, completion: nil)
// })
//alert.view.addSubview(buttonClose)
//
//let titleBroadcast = UILabel()
//containerView.addSubview(titleBroadcast)
//titleBroadcast.translatesAutoresizingMaskIntoConstraints = false
//NSLayoutConstraint.activate([
//    titleBroadcast.topAnchor.constraint(equalTo: containerView.topAnchor),
//    titleBroadcast.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//    titleBroadcast.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//])
//titleBroadcast.font = UIFont.systemFont(ofSize: 18)
//titleBroadcast.numberOfLines = 0
//titleBroadcast.text = m[CoreMessage_TMessageKey.TITLE]
//titleBroadcast.textColor = .black
//
//let descBroadcast = UILabel()
//containerView.addSubview(descBroadcast)
//descBroadcast.translatesAutoresizingMaskIntoConstraints = false
//NSLayoutConstraint.activate([
//    descBroadcast.topAnchor.constraint(equalTo: titleBroadcast.bottomAnchor, constant: 10),
//    descBroadcast.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//    descBroadcast.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//])
//descBroadcast.font = UIFont.systemFont(ofSize: 15)
//descBroadcast.numberOfLines = 0
//descBroadcast.text = m[CoreMessage_TMessageKey.MESSAGE_TEXT_ENG]
//descBroadcast.textColor = .black
//
//let stringLink = m[CoreMessage_TMessageKey.LINK] ?? ""
//let linkBroadcast = UILabel()
//if !stringLink.isEmpty {
//    containerView.addSubview(linkBroadcast)
//    linkBroadcast.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//        linkBroadcast.topAnchor.constraint(equalTo: descBroadcast.bottomAnchor, constant: 10),
//        linkBroadcast.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//        linkBroadcast.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//    ])
//    linkBroadcast.font = UIFont.systemFont(ofSize: 15)
//    linkBroadcast.isUserInteractionEnabled = true
//    linkBroadcast.numberOfLines = 0
//    let attributedString = NSMutableAttributedString(string: stringLink, attributes:[NSAttributedString.Key.link: URL(string: stringLink)!])
//    linkBroadcast.attributedText = attributedString
//    let tap = ObjectGesture(target: self, action: #selector(tapLinkBroadcast))
//    tap.message_id = stringLink
//    linkBroadcast.addGestureRecognizer(tap)
//}
//
//let dottedLine = UIView()
//containerView.addSubview(dottedLine)
//dottedLine.translatesAutoresizingMaskIntoConstraints = false
//var constraintDottedLine = dottedLine.topAnchor.constraint(equalTo: descBroadcast.bottomAnchor, constant: 20)
//if !stringLink.isEmpty{
//    constraintDottedLine = dottedLine.topAnchor.constraint(equalTo: linkBroadcast.bottomAnchor, constant: 20)
//}
//NSLayoutConstraint.activate([
//    constraintDottedLine,
//    dottedLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//    dottedLine.widthAnchor.constraint(equalToConstant: alert.view.bounds.size.width * 0.9 - 40),
//    dottedLine.heightAnchor.constraint(equalToConstant: 2)
//])
//dottedLine.backgroundColor = .black.withAlphaComponent(0.1)
//let shapeLayer = CAShapeLayer()
//shapeLayer.strokeColor = UIColor.black.withAlphaComponent(0.2).cgColor
//shapeLayer.lineWidth = 2
//// passing an array with the values [2,3] sets a dash pattern that alternates between a 2-user-space-unit-long painted segment and a 3-user-space-unit-long unpainted segment
//shapeLayer.lineDashPattern = [2,3]
//
//let path = CGMutablePath()
//path.addLines(between: [CGPoint(x: 0, y: 0),
//                        CGPoint(x: alert.view.bounds.size.width * 0.9 - 20, y: 0)])
//shapeLayer.path = path
//dottedLine.layer.addSublayer(shapeLayer)
//
//let thumb = m[CoreMessage_TMessageKey.THUMB_ID] ?? ""
//let image = m[CoreMessage_TMessageKey.IMAGE_ID] ?? ""
//let video = m[CoreMessage_TMessageKey.VIDEO_ID] ?? ""
//let file = m[CoreMessage_TMessageKey.FILE_ID] ?? ""
//if fileType != BroadcastViewController.FILE_TYPE_CHAT {
//    let imageBroadcast = UIImageView()
//    containerView.addSubview(imageBroadcast)
//    imageBroadcast.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//        imageBroadcast.topAnchor.constraint(equalTo: dottedLine.bottomAnchor, constant: 20),
//        imageBroadcast.widthAnchor.constraint(equalToConstant: alert.view.bounds.size.width * 0.9 - 40),
//        imageBroadcast.heightAnchor.constraint(equalToConstant: 250)
//    ])
//    imageBroadcast.layer.cornerRadius = 10.0
//    imageBroadcast.clipsToBounds = true
//    if fileType != BroadcastViewController.FILE_TYPE_DOCUMENT {
//        imageBroadcast.contentMode = .scaleAspectFill
//        imageBroadcast.setImage(name: thumb)
//
//        if fileType == BroadcastViewController.FILE_TYPE_VIDEO {
//            let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
//            imageBroadcast.addSubview(imagePlay)
//            imagePlay.clipsToBounds = true
//            imagePlay.translatesAutoresizingMaskIntoConstraints = false
//            imagePlay.centerYAnchor.constraint(equalTo: imageBroadcast.centerYAnchor).isActive = true
//            imagePlay.centerXAnchor.constraint(equalTo: imageBroadcast.centerXAnchor).isActive = true
//            imagePlay.widthAnchor.constraint(equalToConstant: 60).isActive = true
//            imagePlay.heightAnchor.constraint(equalToConstant: 60).isActive = true
//            imagePlay.tintColor = .gray.withAlphaComponent(0.5)
//        }
//    } else {
//        imageBroadcast.image = UIImage(systemName: "doc.fill")
//        imageBroadcast.tintColor = .mainColor
//        imageBroadcast.contentMode = .scaleAspectFit
//    }
//
//    imageBroadcast.actionHandle(controlEvents: .touchUpInside,
//     ForAction:{() -> Void in
//        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
//        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
//        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
//        if fileType == BroadcastViewController.FILE_TYPE_IMAGE {
//            if let dirPath = paths.first {
//                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(image)
//                if FileManager.default.fileExists(atPath: imageURL.path) {
//                    let image    = UIImage(contentsOfFile: imageURL.path)
//                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
//                    previewImageVC.image = image
//                    previewImageVC.isHiddenTextField = true
//                    previewImageVC.modalPresentationStyle = .overFullScreen
//                    previewImageVC.modalTransitionStyle  = .crossDissolve
//                    let checkViewController = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController
//                    if checkViewController != nil {
//                        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.present(previewImageVC, animated: true, completion: nil)
//                    } else {
//                        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.present(previewImageVC, animated: true, completion: nil)
//                    }
//                } else {
//                    Download().start(forKey: image) { (name, progress) in
//                        guard progress == 100 else {
//                            return
//                        }
//
//                        DispatchQueue.main.async {
//                            let image    = UIImage(contentsOfFile: imageURL.path)
//                            let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
//                            previewImageVC.image = image
//                            previewImageVC.isHiddenTextField = true
//                            previewImageVC.modalPresentationStyle = .overFullScreen
//                            previewImageVC.modalTransitionStyle  = .crossDissolve
//                            let checkViewController = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController
//                            if checkViewController != nil {
//                                UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.present(previewImageVC, animated: true, completion: nil)
//                            } else {
//                                UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.present(previewImageVC, animated: true, completion: nil)
//                            }
//                        }
//                    }
//                }
//            }
//        } else if fileType == BroadcastViewController.FILE_TYPE_VIDEO {
//            if let dirPath = paths.first {
//                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(video)
//                if FileManager.default.fileExists(atPath: videoURL.path) {
//                    let player = AVPlayer(url: videoURL as URL)
//                    let playerVC = AVPlayerViewController()
//                    playerVC.player = player
//                    playerVC.modalPresentationStyle = .custom
//                    let checkViewController = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController
//                    if checkViewController != nil {
//                        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.present(playerVC, animated: true, completion: nil)
//                    } else {
//                        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.present(playerVC, animated: true, completion: nil)
//                    }
//                } else {
//                    Download().start(forKey: video) { (name, progress) in
//                        DispatchQueue.main.async {
//                            guard progress == 100 else {
//                                return
//                            }
//                            let player = AVPlayer(url: videoURL as URL)
//                            let playerVC = AVPlayerViewController()
//                            playerVC.player = player
//                            playerVC.modalPresentationStyle = .custom
//                            let checkViewController = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController
//                            if checkViewController != nil {
//                                UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.present(playerVC, animated: true, completion: nil)
//                            } else {
//                                UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.present(playerVC, animated: true, completion: nil)
//                            }
//                        }
//                    }
//                }
//            }
//        } else if fileType == BroadcastViewController.FILE_TYPE_DOCUMENT {
//            if let dirPath = paths.first {
//                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
//                if FileManager.default.fileExists(atPath: fileURL.path) {
//                    previewItem = fileURL as NSURL
//                    let previewController = QLPreviewController()
//                    let rightBarButton = UIBarButtonItem()
//                    previewController.navigationItem.rightBarButtonItem = rightBarButton
//                    previewController.dataSource = self
//                    previewController.modalPresentationStyle = .overFullScreen
//
//                    let checkViewController = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController
//                    if checkViewController != nil {
//                        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.show(previewController, sender: nil)
//                    } else {
//                        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.show(previewController, sender: nil)
//                    }
//                } else {
//                    Download().start(forKey: file) { (name, progress) in
//                        DispatchQueue.main.async {
//                            guard progress == 100 else {
//                                return
//                            }
//                            previewItem = fileURL as NSURL
//                            let previewController = QLPreviewController()
//                            let rightBarButton = UIBarButtonItem()
//                            previewController.navigationItem.rightBarButtonItem = rightBarButton
//                            previewController.dataSource = self
//                            previewController.modalPresentationStyle = .overFullScreen
//
//                            let checkViewController = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController
//                            if checkViewController != nil {
//                                UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.show(previewController, sender: nil)
//                            } else {
//                                UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.show(previewController, sender: nil)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//     })
//}
//
//let checkViewController = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController
//if checkViewController != nil {
//    UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.present(alert, animated: true, completion: nil)
//} else {
//    UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.present(alert, animated: true, completion: nil)
//}
