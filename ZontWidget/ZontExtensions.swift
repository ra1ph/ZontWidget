//
// Created by Mikhail Korshunov on 22.04.17.
// Copyright (c) 2017 ra1ph. All rights reserved.
//

import Foundation

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}