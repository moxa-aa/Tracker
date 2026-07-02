//
//  SceneDelegate.swift
//  Tracker
//
//  Created by Moxa on 25/06/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let launchVC = LaunchViewController(
            trackerStore: appDelegate.trackerStore,
            trackerCategoryStore: appDelegate.trackerCategoryStore,
            trackerRecordStore: appDelegate.trackerRecordStore
        )
        window.rootViewController = launchVC
        window.makeKeyAndVisible()
        self.window = window
    }
}

