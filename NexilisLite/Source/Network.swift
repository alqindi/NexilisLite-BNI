//
//  Network.swift
//  Runner
//
//  Created by Yayan Dwi on 20/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation

public class Network {
    let uploadGroup = DispatchGroup()
    private var path = ""
    private var fileId = ""
    private var fileSize = 0
    private var isCancel = false
    private var progress = 0.0
    private var CHUNK_SIZE = 200 * 1024
    
    public init() {}
    
    public func upload(name: String, completion: @escaping (Bool, Double)->()) {
        DispatchQueue(label: "Network").async {
            do {
                let fileManager = FileManager.default
                let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileDir = documentDir.appendingPathComponent(name)
                let path = fileDir.path
                if FileManager.default.fileExists(atPath: path) {
                    let attrib = try FileManager.default.attributesOfItem(atPath: path)
                    let fileSize = attrib[.size] as! Int
                    let fileName = (path as NSString).lastPathComponent
                    print("file exists: \(path) -> \(fileSize)")
                    if (fileSize > self.CHUNK_SIZE) {
                        Nexilis.putUploadFile(forKey: fileName, uploader: self)
                        print("[bytes_processing] Size: " + String(fileSize))
                        var totalPart = fileSize / self.CHUNK_SIZE
                        if (fileSize % self.CHUNK_SIZE > 0) {
                            totalPart += 1
                        }
                        
                        do {
                            let outputFileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
                            var data = outputFileHandle.readData(ofLength: self.CHUNK_SIZE)
                            var index = 0
                            while !data.isEmpty {
                                if self.isCancel {
                                    completion(false, Double(0))
                                    break
                                }
                                self.uploadGroup.enter()
                                print("[bytes_processing] Sending bytes part #" + String(index + 1) + " of " + String(totalPart) + " -->  " + String(data.count))
                                
                                let message = CoreMessage_TMessageBank.getUploadFile(p_image_id: fileName, file_size: String(fileSize), part_of: String(index), part_size: String(totalPart), p_file: [UInt8] (data))
                                
                                if let response = Nexilis.write(message: message), response.isEmpty {
                                    completion(false, self.progress)
                                    break
                                }
                                print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " uploading...")
                                
                                let wait = self.uploadGroup.wait(timeout: .now() + 30)
                                print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " wait!", wait)
                                if wait == DispatchTimeoutResult.timedOut {
                                    completion(false, self.progress)
                                    Nexilis.removeUploadFile(forKey: fileName)
                                    self.uploadGroup.leave()
                                    break
                                }
                                self.progress = Double(index + 1) / Double(totalPart) * 100
                                completion(true, self.progress)
                                
                                print("[bytes_processing] part #" + String(index + 1) + " of " + String(totalPart) + " uploaded!")
                                data = outputFileHandle.readData(ofLength: self.CHUNK_SIZE)
                                index = index + 1
                            }
                            outputFileHandle.closeFile()
                            _ = Nexilis.removeUploadFile(forKey: fileName)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    else {
                        let data = try Data(contentsOf: URL(fileURLWithPath: path))
                        
                        let message = CoreMessage_TMessageBank.getUploadFile(p_image_id: fileName, file_size: String(fileSize), part_of: "0", part_size: "0", p_file: [UInt8] (data))
                        
                        guard let response = Nexilis.write(message: message), !response.isEmpty else {
                            completion(false, self.progress)
                            return
                        }
                        print("[bytes_processing] File uploaded!")
                        completion(response.count > 1, 100)
                    }
                } else {
                    print("file not exists \(name)")
                    completion(false, 0)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public func cancel() {
        self.isCancel = true
    }
}
