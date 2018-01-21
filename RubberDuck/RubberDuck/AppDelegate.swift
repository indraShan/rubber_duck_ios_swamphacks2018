//
//  AppDelegate.swift
//  RubberDuck
//
//  Created by Indrajit on 20/01/18.
//  Copyright © 2018 Indrajit. All rights reserved.
//

import UIKit
import LoginWithAmazon

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return AMZNAuthorizationManager.handleOpen(url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String)
    }


}

