//
//  AppDelegate.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 27.03.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appCoordinator: AppCoordinator!
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        window!.rootViewController = navigationController
        self.appCoordinator = AppCoordinator(navigationController: navigationController)
        appCoordinator.start()
        
        window!.makeKeyAndVisible()
        return true
    }
}

