//
//  Extensions.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 04.04.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import UIKit
import RxSwift
import MBProgressHUD

extension MBProgressHUD {
    var rx_mbprogresshud_animating: AnyObserver<Bool> {
        
        return AnyObserver { event in
            
            MainScheduler.ensureExecutingOnScheduler()
            
            switch (event) {
            case .next(let value):
                if value {
                    let loadingNotification = MBProgressHUD.showAdded(to: (UIApplication.shared.keyWindow?.subviews.last)!, animated: true)
                    loadingNotification.mode = self.mode
                    loadingNotification.label.text = self.label.text
                } else {
                    MBProgressHUD.hide(for: (UIApplication.shared.keyWindow?.subviews.last)!, animated: true)
                }
            case .error(let error):
                let error = "Binding error to UI: \(error)"
                print(error)
            case .completed:
                break
            }
        }
    }
}
