//
//  CustomTextView.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 27/09/21.
//

import UIKit

class CustomTextView: UITextView {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let menuController = UIMenuController.shared
        if var menuItems = menuController.menuItems,
           (menuItems.map { $0.action }).elementsEqual([#selector(toggleBoldface), #selector(toggleItalics), #selector(toggleUnderline)]) {
            menuItems.append(UIMenuItem(title: "Strikethrough", action: #selector(toggleStrikethrough)))
            menuController.menuItems = menuItems
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    @objc func toggleStrikethrough(_ sender: Any?) {
        if let range = self.selectedTextRange {
            self.replace(self.textRange(from: range.start, to: range.end)!, withText: "~\(self.text(in: range)!)~")
            UIMenuController.shared.isMenuVisible = false
        }
    }

    override func toggleBoldface(_ sender: Any?) {
        if let range = self.selectedTextRange {
//            var firstSpace = ""
//            var endSpace = ""
//            let idxFirst = self.offset(from: self.beginningOfDocument, to: range.start)
//            let idxEnd = self.offset(from: self.beginningOfDocument, to: range.end)
//            if (idxFirst - 1 != -1 && !EditorPersonal.checkCharBeforeAfter(char: String(self.text[idxFirst - 1]))) {
//                firstSpace = " "
//            }
//            if idxEnd == self.text.count || !EditorPersonal.checkCharBeforeAfter(char: String(self.text[idxEnd])) {
//                endSpace = " "
//            }
//            self.replace(self.textRange(from: range.start, to: range.end)!, withText: "\(firstSpace)*\(self.text(in: range)!)*\(endSpace)")
            self.replace(self.textRange(from: range.start, to: range.end)!, withText: "*\(self.text(in: range)!)*")
            UIMenuController.shared.isMenuVisible = false
        }
    }
    
    override func toggleUnderline(_ sender: Any?) {
        if let range = self.selectedTextRange {
            self.replace(self.textRange(from: range.start, to: range.end)!, withText: "^\(self.text(in: range)!)^")
            UIMenuController.shared.isMenuVisible = false
        }
    }
    
    override func toggleItalics(_ sender: Any?) {
        if let range = self.selectedTextRange {
            self.replace(self.textRange(from: range.start, to: range.end)!, withText: "_\(self.text(in: range)!)_")
            UIMenuController.shared.isMenuVisible = false
        }
    }
    
    

}
