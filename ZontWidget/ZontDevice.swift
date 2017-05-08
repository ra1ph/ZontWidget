//
//  ZontDevice.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 04.04.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import Foundation
import SwiftyJSON

struct DeviceTypeStruct: JsonParseable {
    let name: String
    let code: String
    let type: DeviceType?

    init(json: JSON) {
        name = json["name"].stringValue
        code = json["code"].stringValue
        type = DeviceType(code: code)
    }

    enum DeviceType {
        case ZTC700
        init?(code: String) {
            switch(code) {
            case "ZTC-700":
                self = .ZTC700
            default:
                return nil
            }
        }
    }
}

class ZontDevice: JsonParseable{
    let device_id: Int
    let serial: String
    let name: String
    let device_type: DeviceTypeStruct
    
    required init(json: JSON) {
        device_id = json["id"].intValue
        serial = json["serial"].stringValue
        name = json["name"].stringValue
        device_type = DeviceTypeStruct(json: json["device_type"])
    }
}



struct ZontDeviceList: JsonParseable {
    let devices: [ZontDevice]
    init(json: JSON) {
        devices = json["devices"].array?.map{ZontDevice.parseDevice(json: $0)} ?? []
    }
}

extension ZontDevice {
    static func parseDevice(json: JSON) -> ZontDevice {
        let deviceType = DeviceTypeStruct(json: json["device_type"])
        if let deviceType = deviceType.type {
            switch(deviceType) {
            case .ZTC700:
                return ZontZTC700Device(json: json)
            }
        } else {
            return ZontDevice(json: json)
        }
    }
}
