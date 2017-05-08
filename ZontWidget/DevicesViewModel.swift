//
//  DevicesViewModel.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 04.04.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import Foundation
import RxSwift
import KeychainSwift

class DevicesViewModel {
    let disposeBag = DisposeBag()
    
    private var zontManager: Variable<ZontManager?> = Variable(nil)
    private let keychain = KeychainSwift()
    
    private var devices: Variable<[ZontDevice]> = Variable([])
    private let isLoading = Variable(false)
    
    let devicesObservable: Observable<([ZontDevice], Int)>
    let isLoggedObservable: Observable<Bool>
    let isLoadingObservable: Observable<Bool>
    
    init() {
        keychain.accessGroup = GROUP_ALIAS
        isLoggedObservable = zontManager.asObservable()
            .map(){ $0 != nil }
        isLoadingObservable = isLoading.asObservable()
        
        let tempKeychain = self.keychain
        devicesObservable = devices.asObservable()
            .skip(1)
            .map {(devices) in
                let savedDevice = tempKeychain.get(SELECTED_DEVICE_KEY)
                var selectedIndex = -1
                if let unwrappedSavedDevice = savedDevice {
                    selectedIndex = devices.index{ $0.serial == unwrappedSavedDevice } ?? -1
                }
                
                return (devices, selectedIndex)
        }
        
        let login = keychain.get(LOGIN_KEY)
        let password = keychain.get(PASSWORD_KEY)
        
        if let login = login, let password = password {
            auth(login: login, password: password)
        }
    }
    
    func auth(login: String, password: String){
        let zontManager = ZontManager(login: login, password: password)
        
        updateDevices(zontManager: zontManager) {
            self.zontManager.value = zontManager
            self.keychain.set(login, forKey: LOGIN_KEY)
            self.keychain.set(password, forKey: PASSWORD_KEY)
        }
    }
    
    func updateDevices() {
        if let zontManager = self.zontManager.value {
            self.updateDevices(zontManager: zontManager)
        }
    }
    
    func updateDevices(zontManager: ZontManager, success: (()->())? = nil) {
        isLoading.value = true
        zontManager
            .getDevices()
            .subscribe(onNext: { (deviceList) in
                self.devices.value = deviceList.devices
                if let success = success {
                    success()
                }
                self.isLoading.value = false
            }, onError: { (error) in
                self.zontManager.value = nil
                self.keychain.clear()
                self.isLoading.value = false
            })
            .addDisposableTo(disposeBag)
    }
    
    func saveSelectedDevice(device: ZontDevice?) {
        if let deviceSerial = device?.serial {
            keychain.set(deviceSerial, forKey: SELECTED_DEVICE_KEY)
        } else {
            keychain.delete(SELECTED_DEVICE_KEY)
        }
    }
}
