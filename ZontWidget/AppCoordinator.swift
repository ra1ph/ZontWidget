//
//  AppCoordinator.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 29.03.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import UIKit

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewController = ViewController(viewModel: DevicesViewModel())
        navigationController?.pushViewController(viewController, animated: false);
    }
}
