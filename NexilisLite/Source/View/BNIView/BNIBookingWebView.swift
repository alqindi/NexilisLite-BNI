//
//  BNIBookingWebView.swift
//  FMDB
//
//  Created by Qindi on 01/04/22.
//

import UIKit
import WebKit

class BNIBookingWebView: UIViewController, WKNavigationDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, WKScriptMessageHandler {
    var webView = WKWebView()
    let closeButton = UIButton()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        webView.navigationDelegate = self
        
        Database().database?.inTransaction({ fmdb, rollback in
            let idMe = UserDefaults.standard.string(forKey: "me") as String?
            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name from BUDDY where f_pin = '\(idMe!)'"), c.next() {
                let name = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                let url = URL(string: "https://sqappointment.murni.id:4200/bookingonline/#/?userid=\(name)")!
                webView.load(URLRequest(url: url))
                c.close()
            }
        })
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.delegate = self
        
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: "sendQueueBNI")
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" +
            "head.appendChild(meta);"
        
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWebView(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.orange, for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30.0).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0).isActive = true
        closeButton.addTarget(self, action: #selector(close(sender:)), for: .touchUpInside)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipUpAction))
        swipeUp.direction = .up
        swipeUp.cancelsTouchesInView = false
        swipeUp.delegate = self
        webView.scrollView.addGestureRecognizer(swipeUp)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func swipUpAction() {
        if !closeButton.isHidden {
            closeButton.isHidden = true
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y <= 0) {
            if closeButton.isHidden {
                closeButton.isHidden = false
            }
        }
    }
    
    @objc func close(sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "sendQueueBNI" {
            guard let dict = message.body as? [String: AnyObject],
                  let param1 = dict["param1"] as? String else {
                return
            }
            DispatchQueue.global().async {
                let _ = Nexilis.writeSync(message: CoreMessage_TMessageBank.queueBNI(service_id: param1), timeout: 30 * 1000)
            }
        }
    }
    
    @objc func reloadWebView(_ sender: UIRefreshControl) {
        webView.reload()
        sender.endRefreshing()
    }
}
