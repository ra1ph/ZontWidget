//
//  APIClient.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 04.04.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import Foundation
import RxSwift

class ZontManager {
    private let apiClient: APIClient
    private let encodedAuthPair: String
    
    init(login: String, password: String) {
        let authPair = login + ":" + password;
        encodedAuthPair = authPair.toBase64()
        apiClient = APIClient(encodedAuth: encodedAuthPair)
    }
    
    func getDevices()->Observable<ZontDeviceList> {
        return apiClient.request(zontRequest: ZontDevicesRequest())
    }
    
    func setGuardState(device: ZontDevice, enabled: Bool)->Observable<ZontSetIOPortResult> {
        return apiClient.request(zontRequest: ZontGuardStateRequest(deviceId: String(device.device_id), guardEnabled: enabled))
    }
    
    func setAutoIgnitionState(device: ZontDevice, enabled: Bool)->Observable<ZontSetIOPortResult> {
        return apiClient.request(zontRequest: ZontAutoIgnitionRequest(deviceId: String(device.device_id), autoIgnitionEnabled: enabled))
    }
}
