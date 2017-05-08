//
//  Coordinator.swift
//  ZontWidget
//
//  Created by Mikhail Korshunov on 29.03.17.
//  Copyright © 2017 ra1ph. All rights reserved.
//

import UIKit

protocol Coordinator {
    var childCoordinators: [Coordinator] {get set}
    weak var navigationController: UINavigationController? {get set}
    
    func start()
}
