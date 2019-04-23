//
//  ViewController.swift
//  KVPermissions
//
//  Created by Vu Van Khac on 04/17/2019.
//  Copyright (c) 2019 Vu Van Khac. All rights reserved.
//

import UIKit
import KVPermissions

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        KVPermission.notification.request()
    }
}

