//
//  ZontSetIOPortResult.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 04.05.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import Foundation
import SwiftyJSON

struct ZontSetIOPortResult: JsonParseable {
    let ok:Bool
    
    init(json: JSON) {
        ok = json["ok"].boolValue
    }
}
