//
//  ZontZTC700Device.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 05.04.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import Foundation
import SwiftyJSON

struct IO: JsonParseable {
    let guardState: GuardState?
    let autoIgnition: AutoIgnition?
    
    init(json: JSON) {
        guardState = GuardState(state: json["guard-state"].stringValue)
        autoIgnition = AutoIgnition(json: json["auto-ignition"])
    }
}

enum GuardState {
    case enabled, enabling, disabled
    
    init(state: String) {
        switch(state) {
        case "enabled":
            self = .enabled
        case "enabling":
            self = .enabling
        case "disabled":
            self = .disabled
        default:
            self = .disabled
        }
    }
    
    func toggleState()->Bool? {
        switch(self) {
        case .disabled:
            return true
        case .enabled:
            return false
        default:
            return nil
        }
    }
}

struct AutoIgnition: JsonParseable {
    let available: Bool
    let until: Int?
    let state: AutoIgnitionState
    
    init(json: JSON) {
        available = json["available"].boolValue
        until = json["until"].int
        state = AutoIgnitionState(state: json["state"].stringValue)
    }
}

enum AutoIgnitionState {
    case enabled, enabling, disabled, webasto, webasto_confirmed
    
    init(state: String) {
        switch(state) {
        case "enabled":
            self = .enabled
        case "enabling":
            self = .enabling
        case "disabled":
            self = .disabled
        case "webasto":
            self = .webasto
        case "webasto-confirmed":
            self = .webasto_confirmed
        default:
            self = .disabled
        }
    }
    
    func toggleState()->Bool? {
        switch(self) {
        case .disabled:
            return true
        case .enabled:
            return false
        default:
            return nil
        }
    }
}

class ZontZTC700Device: ZontDevice {
    let io: IO
    
    required init(json: JSON) {
        self.io = IO(json: json["io"])
        super.init(json: json)
    }
}
