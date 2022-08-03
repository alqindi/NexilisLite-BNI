//
//  Callback.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import nuSDKService

class Callback : CallBack {
    var sID: String = "Callback"
    
    func connectionStateChanged(sUserID: String!, sDeviceID: String!, bConState: Bool!, nConType: Int!, nConSubType: Int!, nCLMConStat: UInt8!) {
        print(sUserID, "/", sDeviceID, "/", bConState, "/", nConType, "/", nConSubType, "/", nCLMConStat)
        if let dispatch = Nexilis.dispatch, bConState {
            dispatch.leave()
        }
        if let delegate = Nexilis.shared.connectionDelegate {
            delegate.connectionStateChanged(userId: sUserID, deviceId: sDeviceID, state: bConState)
        }
        OutgoingThread.default.set(wait: nCLMConStat == 0)
    }
    
    func gpsStateChanged(nState: Int!) {
        
    }
    
    func sleepStateChanged(bState: Bool!) {
        
    }
    
    func callStateChanged(nState: Int!, sMessage: String!) -> Int {
        print(nState,"/",sMessage)
        if nState == 21 || nState == 31 {
            if let delegate = Nexilis.shared.callDelegate {
                delegate.onIncomingCall(state: nState, message: sMessage)
            }
        } else {
//            if nState == 28 {
//                let pin = sMessage.split(separator: ",")[0]
//                if let call = Palio.shared.callManager.call(with: String(pin)), !call.hasVideo, !call.hasEnded {
//                    call.reconnectingCall()
//                    return 1
//                }
//            }
            if let delegate = Nexilis.shared.callDelegate {
                delegate.onStatusCall(state: nState, message: sMessage)
            }
        }
        
        return 1
    }
    
    func bcastStateChanged(nState: Int!, sMessage: String!) -> Int {
        print("LS CALLBACK ",nState,"/",sMessage)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onStartLS(state: nState, message: sMessage)
        }
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: nState, message: sMessage)
        }
        return 1
    }
    
    func sshareStateChanged(nState: Int!, sMessage: String!) -> Int {
        print("Screen sharing state: ",nState,"/",sMessage)
        switch nState {
            case 0:
                if (sMessage.starts(with: "Initiating")){
                    if let delegate = Nexilis.shared.screenSharingDelegate {
                        delegate.onStartScreenSharing(state: nState, message: sMessage)
                    }
                }
            case 12:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onStartScreenSharing(state: nState, message: sMessage)
                }
            case 22:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onJoinScreenSharing(state: nState, message: sMessage)
                }
            case 88:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onStartScreenSharing(state: nState, message: sMessage)
                }
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onJoinScreenSharing(state: nState, message: sMessage)
                }
            default:
                break
        }
        return 1
    }
    
    func incomingData(sPacketID: String!, oData: AnyObject!) throws {
        Nexilis.incomingData(packetId: sPacketID!, data: oData!)
    }
    
    func lateResponse(sPacketID: String!, sResponse: String!) throws {
        
    }
    
    func asycnACKReceived(sPacketID: String!) throws {
        print("asycnACKReceived: \(sPacketID)")
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                OutgoingThread.default.delOutgoing(fmdb: fmdb, packageId: sPacketID)
            })
        }
    }
    
    func locationUpdated(lTime: Int64!, sLocationInfo: String!) {
        
    }
    
    func resetDB() {
        
    }
    
}
