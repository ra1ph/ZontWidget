//
// Created by Mikhail Korshunov on 22.04.17.
// Copyright (c) 2017 ra1ph. All rights reserved.
//

import Foundation
import RxSwift
import KeychainSwift

class ZontExtensionViewModel {
    private let AUTOUPDATE_DELAY = 5.0
    
    private let disposeBag = DisposeBag()
    
    private var zontManager: ZontManager?
    private let keychain = KeychainSwift()
    
    private let currentDevice: ReplaySubject<ZontZTC700Device> = ReplaySubject.create(bufferSize: 1)
    private let message: Variable<String?> = Variable(nil)
    
    let messageObservable: Observable<String?>
    let autoIgnitionObservable: Observable<AutoIgnition?>
    let guardStateObservable: Observable<GuardState?>
    
    init() {
        keychain.accessGroup = GROUP_ALIAS
        messageObservable = message.asObservable().skip(1)
        
        autoIgnitionObservable = currentDevice.asObservable()
            .skip(1)
            .map {
                $0.io.autoIgnition
        }
        
        guardStateObservable = currentDevice.asObservable()
            .skip(1)
            .map {
                $0.io.guardState
        }
        
        _ = updateState()
    }
    
    func updateState()->Observable<Bool> {
        let updateFinishSubject = ReplaySubject<Bool>.create(bufferSize: 1)
        let updateFinishObservable = updateFinishSubject.asObservable();
        
        message.value = "Loading..."
        let login = keychain.get(LOGIN_KEY)
        let password = keychain.get(PASSWORD_KEY)
        
        guard let loginUnwrapped = login, let passwordUnwrapped = password else {
            message.value = "Please authorize at main application"
            updateFinishSubject.onNext(false)
            return updateFinishObservable;
        }
        
        guard let zontManager = zontManager else {
            authZontManager(login: loginUnwrapped, password: passwordUnwrapped)
            updateFinishSubject.onNext(false)
            return updateFinishObservable;
        }
        
        updateDevices(zontManager: zontManager) { (error: Swift.Error) in
            self.message.value = "Please check your internet connection"
            updateFinishSubject.onNext(false)
        }
        
        return updateFinishObservable;
    }
    
    func toggleGuardState()->Observable<Bool> {
        self.message.value = "Loading..."
        let setStateSubject = ReplaySubject<Bool>.create(bufferSize: 1)
        let setStateObservable = setStateSubject.asObservable();
        
        guard let zontManager = zontManager else {
            self.message.value = nil
            setStateSubject.onNext(false)
            return setStateObservable
        }
        
        currentDevice.take(1)
            .subscribe(onNext: {[unowned self] (device) in
                guard let toggledState = device.io.guardState?.toggleState() else {
                    self.message.value = nil
                    setStateSubject.onNext(false)
                    return
                }
                zontManager.setGuardState(device: device, enabled: toggledState)
                    .subscribe(onNext: {[unowned self] _ in
                        setStateSubject.onNext(true)
                        let deadlineTime = DispatchTime.now() + self.AUTOUPDATE_DELAY
                        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                            self.message.value = nil
                            _ = self.updateState()
                        }
                    }, onError: {[unowned self] _ in
                        self.message.value = nil
                        setStateSubject.onNext(false)
                        
                    }).addDisposableTo(self.disposeBag)
                }, onError: {[unowned self] (error) in
                    self.message.value = nil
                    setStateSubject.onNext(false)
            }).addDisposableTo(disposeBag)
        return setStateObservable
    }
    
    func toggleAutoIgnitionState()->Observable<Bool> {
        self.message.value = "Loading..."
        let setStateSubject = ReplaySubject<Bool>.create(bufferSize: 1)
        let setStateObservable = setStateSubject.asObservable();
        
        guard let zontManager = zontManager else {
            self.message.value = nil
            setStateSubject.onNext(false)
            return setStateObservable
        }
        
        currentDevice.take(1)
            .subscribe(onNext: {[unowned self] (device) in
                guard let toggledState = device.io.autoIgnition?.state.toggleState() else {
                    self.message.value = nil
                    setStateSubject.onNext(false)
                    return
                }
                
                zontManager.setAutoIgnitionState(device: device, enabled: toggledState)
                    .subscribe(onNext: {[unowned self] _ in
                        setStateSubject.onNext(true)
                        let deadlineTime = DispatchTime.now() + self.AUTOUPDATE_DELAY
                        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                            self.message.value = nil
                            _ = self.updateState()
                        }
                        }, onError: {[unowned self] _ in
                            self.message.value = nil
                            setStateSubject.onNext(false)
                            
                    }).addDisposableTo(self.disposeBag)
                }, onError: {[unowned self] (error) in
                    self.message.value = nil
                    setStateSubject.onNext(false)
            }).addDisposableTo(disposeBag)
        return setStateObservable
    }
    
    private func authZontManager(login: String, password: String) {
        
        let zontManager = ZontManager(login: login, password: password)
        self.zontManager = zontManager
        updateDevices(zontManager: zontManager) { _ in
            self.message.value = "Some auth error"
        }
    }
    
    private func updateDevices(zontManager: ZontManager, onSuccess: (() -> ())? = nil, onError: ((Swift.Error) -> ())? = nil) {
        zontManager
            .getDevices()
            .subscribe(onNext: { (deviceList) in
                let savedDevice = self.keychain.get(SELECTED_DEVICE_KEY)
                
                let currentDevice = deviceList.devices.filter { device in
                    guard let savedDevice = savedDevice else {
                        return false
                    }
                    
                    if device.serial != savedDevice {
                        return false
                    }
                    
                    if let type = device.device_type.type {
                        return type == .ZTC700
                    }
                    
                    return false
                    }.first
                
                guard let ztc700Device = currentDevice as? ZontZTC700Device else {
                    self.message.value = "Please select device in main application"
                    if let onSuccess = onSuccess {
                        onSuccess()
                    }
                    return
                }
                
                self.message.value = nil
                self.currentDevice.onNext(ztc700Device)
                if let onSuccess = onSuccess {
                    onSuccess()
                }
            }, onError: { (error) in
                self.zontManager = nil
                if let onError = onError {
                    onError(error)
                }
            })
            .addDisposableTo(disposeBag)
    }
}
