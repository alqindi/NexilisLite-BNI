//
//  Download.swift
//  Runner
//
//  Created by Yayan Dwi on 24/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation

public class Download {
    
    public init() {}
    
    var delegate : DownloadDelegate?
    
    public func getDelegate() -> DownloadDelegate? {
        return delegate
    }
    
    private var downloadBufferQueue = DispatchQueue(label: "DOWNLOAD_BUFFER", attributes: .concurrent)
    
    var DOWNLOAD_BUFFER = [Data?]()
    
    public func start(forKey: String, delegate: DownloadDelegate){
        self.delegate = delegate
        let download = Nexilis.getDownload(forKey: forKey)
        if download == nil {
            Nexilis.addDownload(forKey: forKey, download: self)
        }
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getImageDownload(p_image_id: forKey))
    }
    
    var onDownloadProgress: ((String, Double) -> ())?
    
    public func start(forKey: String, completion: @escaping (String, Double)->()) {
        self.onDownloadProgress = completion
        let download = Nexilis.getDownload(forKey: forKey)
        if download == nil {
            Nexilis.addDownload(forKey: forKey, download: self)
        }
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getImageDownload(p_image_id: forKey))
    }
    
    func put(part: Int, buffer: Data){
        downloadBufferQueue.async (flags: .barrier){
            self.DOWNLOAD_BUFFER.insert(buffer, at: part)
        }
    }
    
    func size() -> Int {
        var size = 0
        downloadBufferQueue.sync {
            for b in DOWNLOAD_BUFFER {
                size += b?.count ?? 0
            }
        }
        return size
    }
    
    func remove() -> Data {
        var result = Data()
        downloadBufferQueue.sync {
            for i in DOWNLOAD_BUFFER {
                if let b = i {
                    result.append(contentsOf: b)
                }
            }
        }
        return result
    }
}
