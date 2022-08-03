//
//  WhiteboardViewController.swift
//  NexilisLite
//
//  Created by Kevin Maulana on 31/03/22.
//

// Rn
// onalphachanged

import UIKit

class WhiteboardViewController: UIViewController, WhiteboardDelegate {
    
    func draw(x: String, y: String, w: String, h: String, fc: String, sw: String, xo: String, yo: String, data: String) {
        wb!.draw(x: x, y: y, w: w, h: h, fc: fc, sw: sw, xo: xo, yo: yo, data: data)
    }
    
    @objc func clear(){
        wb?.clear()
    }
    
    var wbc : WhiteboardCanvas?
    var wbcConstraintTop = NSLayoutConstraint()
    var wbcConstraintBottom = NSLayoutConstraint()
    var wbcConstraintLeft = NSLayoutConstraint()
    var wbcConstraintRight = NSLayoutConstraint()
    var wb : Whiteboard?
    var roomId = ""
    var destinations = [String]()
    var incoming = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wb = Whiteboard(delegated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initWhiteboard()
        self.title = "Whiteboard".localized()
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close".localized(), style: .plain, target: self, action: #selector(close))
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear".localized(), style: .plain,target: self, action: #selector(clear))
        

        // Do any additional setup after loading the view.
    }
    
    func initWhiteboard(){
        let wbHeight = self.view.frame.width * 20.0 / 9.0
        let rect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height)
        wbc = WhiteboardCanvas(frame: rect)
//        wbc?.translatesAutoresizingMaskIntoConstraints = false
//        wbcConstraintTop = (wbc?.topAnchor.constraint(equalTo: self.view.topAnchor))!
//        wbcConstraintBottom = (wbc?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor))!
//        wbcConstraintRight = (wbc?.rightAnchor.constraint(equalTo: self.view.rightAnchor))!
//        wbcConstraintLeft = (wbc?.leftAnchor.constraint(equalTo: self.view.leftAnchor))!
//        NSLayoutConstraint.activate([wbcConstraintTop, wbcConstraintBottom, wbcConstraintLeft, wbcConstraintRight])
        wb?.canvas = wbc
        self.view.addSubview(wbc!)
        Nexilis.setWhiteboardDelegate(delegate: self)
        
    }
    
    func sendInit(){
        let d = destinations.joined(separator: ",")
//            roomId = "\(me)\(tid)"
        wb?.setRoomId(roomId: roomId)
        wb!.sendInit(destinations: d)
        
    }
    
    func sendJoin(){
        wb?.setRoomId(roomId: roomId)
        wb!.sendJoin()
    }
    
    var close : (() -> Void)?
    
    func terminate(){
        wb?.sendTerminate()
        Nexilis.setWhiteboardDelegate(delegate: nil)
        close?()
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        close?()
    }
    
    @IBAction func didTapClear(_ sender: Any) {
        wb?.clear()
        wb?.sendClear()
    }
    
    
    @IBAction func onAlphaChanged(_ sender: UISlider) {
        let alp = sender.value / 100.0
        view.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: CGFloat(alp))
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
