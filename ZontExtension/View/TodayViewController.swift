//
//  TodayViewController.swift
//  ZontExtension
//
//  Created by Mikhail Korshunov on 27.03.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import UIKit
import NotificationCenter
import SnapKit
import RxSwift
import RxCocoa

class TodayViewController: UIViewController, NCWidgetProviding {
    private let disposeBag = DisposeBag()
    
    private var viewModel:ZontExtensionViewModel!
    private var updateButton:UIButton!
    private var buttonsView:UIView!
    private var messageView:UILabel!
    private var openDoorButton:UIButton!
    private var startEngineButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ZontExtensionViewModel()
        initUI()
        bindUI()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        viewModel.updateState()
            .subscribe { completionHandler(NCUpdateResult.newData) }
            .addDisposableTo(disposeBag)
    }
    
    private func initUI() {
        updateButton = UIButton(frame: CGRect())
        updateButton.setTitleColor(UIColor.black, for: .normal)
        updateButton.setTitle("Update", for: .normal)
        
        buttonsView = UIView(frame: CGRect())
        messageView = UILabel(frame: CGRect())
        messageView.textColor = UIColor.black
        messageView.textAlignment = .center
        
        openDoorButton = UIButton(frame: CGRect())
        openDoorButton.setTitleColor(UIColor.black, for: .normal)
        
        startEngineButton = UIButton(frame: CGRect())
        startEngineButton.setTitleColor(UIColor.black, for: .normal)
        
        self.view.addSubview(buttonsView)
        self.view.addSubview(messageView)
        buttonsView.addSubview(updateButton)
        buttonsView.addSubview(openDoorButton)
        buttonsView.addSubview(startEngineButton)
        
        buttonsView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        messageView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        updateButton.snp.makeConstraints { make in
            make.left.top.right.equalTo(self.buttonsView)
            make.height.equalTo(40)
        }
        
        openDoorButton.snp.makeConstraints { make in
            make.top.equalTo(self.updateButton.snp.bottom)
            make.left.bottom.equalTo(self.buttonsView)
        }
        
        startEngineButton.snp.makeConstraints { make in
            make.top.equalTo(self.updateButton.snp.bottom)
            make.right.bottom.equalTo(self.buttonsView)
            make.left.equalTo(self.openDoorButton.snp.right)
            make.width.equalTo(self.openDoorButton)
        }
    }
    
    private func setMessage(message: String) {
        messageView.isHidden = false
        messageView.text = message
        buttonsView.isHidden = true
    }
    
    private func hideMessage() {
        messageView.isHidden = true
        buttonsView.isHidden = false
    }
    
    private func bindUI() {
        self.viewModel
            .messageObservable
            .subscribe(onNext: {[unowned self] message in
                if let message = message {
                    self.setMessage(message: message)
                } else {
                    self.hideMessage()
                }
            }).addDisposableTo(disposeBag)
        
        self.viewModel
            .autoIgnitionObservable
            .subscribe(onNext: {[unowned self] (autoIgnition) in
                guard let autoIgnitionUnwrapped = autoIgnition else {
                    self.startEngineButton.isEnabled = false
                    return
                }
                
                if !autoIgnitionUnwrapped.available {
                    self.startEngineButton.isEnabled = false
                    return
                }
                self.startEngineButton.isEnabled = true
                
                switch(autoIgnitionUnwrapped.state) {
                case .disabled:
                    self.startEngineButton.setTitle("Start engine", for: .normal)
                    break
                case .enabling:
                    self.startEngineButton.setTitle("Starting engine...", for: .normal)
                    break
                case .enabled:
                    self.startEngineButton.setTitle("Stop engine", for: .normal)
                    break
                default:
                    break
                }
            }).addDisposableTo(disposeBag)
        
        self.viewModel
            .guardStateObservable
            .subscribe(onNext: {[unowned self] (guardState) in
                guard let unwrapedGuardState = guardState else {
                    self.openDoorButton.isEnabled = false
                    return
                }
                
                switch(unwrapedGuardState) {
                case .disabled:
                    self.openDoorButton.setTitle("Close doors", for: .normal)
                    break
                case .enabling:
                    self.openDoorButton.setTitle("Closing doors...", for: .normal)
                    break
                case .enabled:
                    self.openDoorButton.setTitle("Open doors", for: .normal)
                    break
                }
            }).addDisposableTo(disposeBag)
        
        self.updateButton
            .rx.tap
            .subscribe(onNext: {[unowned self] _ in
                _ = self.viewModel.updateState()
            })
            .addDisposableTo(disposeBag)
        
        self.openDoorButton
            .rx.tap
            .subscribe(onNext: {[unowned self] _ in
                _ = self.viewModel.toggleGuardState()
            })
            .addDisposableTo(disposeBag)
        
        self.startEngineButton
            .rx.tap
            .subscribe(onNext: {[unowned self] _ in
                _ = self.viewModel.toggleAutoIgnitionState()
            })
            .addDisposableTo(disposeBag)
    }
}
