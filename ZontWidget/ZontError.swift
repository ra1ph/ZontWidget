//
//  ZontError.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 04.04.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import Foundation
import SwiftyJSON

struct ZontError: Swift.Error {
    let error: String
    let message: String
}

extension ZontError: JsonParseable {
    init(json: JSON) {
        error = json["error"].stringValue
        message = json["error_ui"].stringValue
    }
}
