//
//  ViewController.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 27.03.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import MBProgressHUD

class ViewController: UIViewController {
    private let cellReuseIdentifier = "Cell"
    
    let disposeBag = DisposeBag()
    
    var loginView = UIView(frame: CGRect())
    var nameField = UITextField(frame: CGRect())
    var passwordField = UITextField(frame: CGRect())
    var loginButton = UIButton(type: .system)
    
    var selectDeviceView = UIView(frame: CGRect())
    var devicesTableView = UITableView(frame: CGRect(), style: .plain)
    let progressHUD = MBProgressHUD()
    
    var validationObservable: Observable<Bool>!
    
    let viewModel: DevicesViewModel
    
    init(viewModel: DevicesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        initValidationObservables()
        initBinds()
    }
    
    func initUI() {
        self.view.backgroundColor = UIColor.white
        
        progressHUD.mode = .indeterminate
        progressHUD.label.text = "Loading..."
        
        nameField.placeholder = "Username"
        nameField.layer.cornerRadius = 4
        nameField.layer.borderWidth = 1
        nameField.layer.borderColor = UIColor.gray.cgColor
        nameField.textAlignment = .center
        nameField.autocapitalizationType = .none
        
        passwordField.placeholder = "Password"
        passwordField.layer.cornerRadius = 4
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.gray.cgColor
        passwordField.textAlignment = .center
        passwordField.autocapitalizationType = .none
        //        passwordField.secureTextEntry = true
        
        loginButton.setTitle("Login", for: .normal)
        loginButton.layer.cornerRadius = 4
        loginButton.layer.borderWidth = 1
        loginButton.layer.borderColor = UIColor.gray.cgColor
        
        devicesTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        devicesTableView.estimatedRowHeight = 44.0
        devicesTableView.rowHeight = UITableViewAutomaticDimension
        
        self.view.addSubview(self.loginView)
        self.view.addSubview(self.selectDeviceView)
        self.loginView.addSubview(nameField)
        self.loginView.addSubview(passwordField)
        self.loginView.addSubview(loginButton)
        self.selectDeviceView.addSubview(devicesTableView)
        
        loginView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalTo(self.view)
            make.top.equalTo(self.view).offset(20)
        }
        
        selectDeviceView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalTo(self.view)
            make.top.equalTo(self.view).offset(20)
        }
        
        passwordField.snp.makeConstraints {(make) in
            make.centerX.equalTo(self.loginView)
            
            make.centerY.equalTo(self.loginView)
            make.width.equalTo(self.loginView).multipliedBy(0.8)
            make.height.equalTo(40)
        }
        
        nameField.snp.makeConstraints {(make) in
            make.left.right.height.equalTo(passwordField)
            make.bottom.equalTo(passwordField.snp.top).offset(-20)
        }
        
        loginButton.snp.makeConstraints {(make) in
            make.left.right.height.equalTo(passwordField)
            make.top.equalTo(passwordField.snp.bottom).offset(20)
        }
        
        devicesTableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.selectDeviceView)
        }
        
        keyboardHeight().subscribe(){ (height) in
            UIView.animate(withDuration: 0.2) {
                self.passwordField.snp.updateConstraints {(make) in
                    make.centerY.equalTo(self.loginView).offset((height.element ?? 0) / -2)
                }
                self.view.layoutIfNeeded()
            }
            }
            .addDisposableTo(disposeBag)
        
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.closeKeyboard)))
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    func setVisibility(isLogged: Bool) {
        self.loginView.isHidden = isLogged
        self.loginView.isUserInteractionEnabled = !isLogged
        self.selectDeviceView.isHidden = !isLogged
        self.selectDeviceView.isUserInteractionEnabled = isLogged
    }
    
    func initValidationObservables() {
        let loginValidationObservable = nameField.rx
            .text
            .asObservable()
            .map {$0?.characters.count ?? 0 > 3}
        
        let passwordValidationObservable = passwordField.rx
            .text
            .asObservable()
            .map{$0?.characters.count ?? 0 > 3}
        
        validationObservable = Observable
            .combineLatest(loginValidationObservable, passwordValidationObservable) { return $0.0 && $0.1}
    }
    
    func initBinds() {
        viewModel.isLoggedObservable
            .subscribe(onNext: { (isLogged) in
                self.setVisibility(isLogged: isLogged)
            }).addDisposableTo(disposeBag)
        
        validationObservable.bindTo(loginButton.rx.isEnabled)
            .addDisposableTo(disposeBag)
        
        loginButton.rx
            .tap
            .subscribe { _ in
                self.viewModel
                    .auth(login: self.nameField.text!, password: self.passwordField.text!)
            }.addDisposableTo(disposeBag)
        
        devicesTableView.rx
            .setDelegate(self)
            .addDisposableTo(disposeBag)
        
        viewModel.devicesObservable
            .map { $0.0 }
            .bindTo(devicesTableView.rx.items(cellIdentifier: cellReuseIdentifier)) { (index, device, cell) in
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = device.name
                cell.selectionStyle = .blue
            }.addDisposableTo(disposeBag)
        
        viewModel.devicesObservable
            .subscribe(onNext: { (tuple) in
                if tuple.1 >= 0 {
                    self.devicesTableView.selectRow(at: IndexPath.init(row: tuple.1, section: 0), animated: true, scrollPosition: .top)
                } else if tuple.0.count == 1 {
                    self.devicesTableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: true, scrollPosition: .top)
                    self.viewModel.saveSelectedDevice(device: tuple.0.first)
                }
            }).addDisposableTo(disposeBag)
        
        devicesTableView.rx
            .modelSelected(ZontDevice.self)
            .subscribe(onNext: { (device) in
                self.viewModel.saveSelectedDevice(device: device)
            }).addDisposableTo(disposeBag)
        
        viewModel.isLoadingObservable
            .bindTo(progressHUD.rx_mbprogresshud_animating)
            .addDisposableTo(disposeBag)
    }
    
    func keyboardHeight() -> Observable<CGFloat> {
        return Observable
            .from([
                NotificationCenter.default.rx.notification(NSNotification.Name.UIKeyboardWillShow)
                    .map { notification -> CGFloat in
                        (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
                },
                NotificationCenter.default.rx.notification(NSNotification.Name.UIKeyboardWillHide)
                    .map { _ -> CGFloat in
                        0
                }
                ])
            .merge()
    }
}

extension ViewController: UITableViewDelegate {
    
}

