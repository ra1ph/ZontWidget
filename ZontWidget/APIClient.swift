//
//  APIClient.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 04.04.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import SwiftyJSON

let BASE_URL = "https://zont-online.ru/api"

class APIClient {
    let encodedAuth: String
    
    init(encodedAuth: String) {
        self.encodedAuth = encodedAuth
    }
    
    func request<E: JsonParseable>(zontRequest: ZontRequest)-> Observable<E>{
        return Observable<E>.create { (observer) -> Disposable in
            let request = Alamofire.request(zontRequest.asURLRequest(auth: self.encodedAuth))
                .responseJSON(completionHandler: { (dataResponse) in
                    switch dataResponse.result {
                    case .success:
                        if let value = dataResponse.result.value {
                            let json = JSON(value)
                            
                            if json["ok"].boolValue == true {
                                observer.onNext(E(json: json))
                            } else {
                                observer.onError(ZontError(json: json))
                            }
                        }
                    case .failure:
                        if let error = dataResponse.result.error {
                            observer.onError(error)
                        }
                    }
                })
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
}

protocol JsonParseable {
    init(json: JSON)
}

@objc protocol ZontRequest {
    var url: String { get }
    var params: [String: Any] { get }
    @objc optional var method: String { get }
}

extension ZontRequest {
    func asURLRequest(auth: String) -> URLRequest {
        var request = URLRequest(url: URL(string: BASE_URL + url)!)
        request.httpMethod = method ?? "post"
        request.addValue("mr.ra1ph91@gmail.com", forHTTPHeaderField: "X-ZONT-Client")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic " + auth, forHTTPHeaderField: "Authorization")
        request.httpBody = try! JSONSerialization.data(withJSONObject: params)
        return request
    }
}

class ZontDevicesRequest: ZontRequest {
    let loadIO: Bool
    
    var url: String { return "/devices"}
    var params: [String : Any] { return ["load_io" : loadIO] }
    
    init(loadIO: Bool = true) {
        self.loadIO = loadIO
    }
}

class ZontSetIOPortRequest: ZontRequest {
    let deviceId: String
    
    var url: String { return "/set_io_port" }
    var params: [String : Any] {
        var result = [String : Any]()
        result["device_id"] = deviceId
        result["portname"] = self.portName
        result["type"] = self.type
        result["value"] = self.value
        return result
    }
    
    var type: String { return "unknown" }
    var portName: String { return "unknown" }
    var value: Any { return "unknown" }
    
    init(deviceId: String) {
        self.deviceId = deviceId
    }
}

class ZontGuardStateRequest: ZontSetIOPortRequest {
    let guardEnabled: Bool
    
    override var portName: String { return "guard-state" }
    override var type: String { return "string" }
    override var value: Any { return guardEnabled ? "enabled" : "disabled" }
    
    init(deviceId: String, guardEnabled: Bool) {
        self.guardEnabled = guardEnabled
        super.init(deviceId: deviceId)
    }
}

class ZontAutoIgnitionRequest: ZontSetIOPortRequest {
    let autoIgnitionEnabled: Bool
    
    override var portName: String { return "auto-ignition" }
    override var type: String { return "auto-ignition" }
    override var value: Any { return ["state" : autoIgnitionEnabled ? "enabled" : "disabled"] }
    
    init(deviceId: String, autoIgnitionEnabled: Bool) {
        self.autoIgnitionEnabled = autoIgnitionEnabled
        super.init(deviceId: deviceId)
    }
}
