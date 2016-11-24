//
//  AppDelegate.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import VKSdkFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var splashWindow: UIWindow? = {
        let window = UIWindow()
        let splashController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        window.rootViewController = splashController
        window.windowLevel = UIWindowLevelAlert
        return window
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
    
        let vkInstance = VKSdk.initialize(withAppId: "5744427")
        
        vkInstance?.register(UIApplication.shared.delegate as! VKSdkDelegate!)
        vkInstance?.uiDelegate = UIApplication.shared.delegate as! VKSdkUIDelegate!
        
        let permissions = [VK_PER_FRIENDS]
        
        VKSdk.wakeUpSession(permissions) { (authState: VKAuthorizationState, error: Error?) in
            if authState != VKAuthorizationState.authorized {
                VKSdk.authorize(permissions)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(authNotification),
                                                object: nil,
                                                userInfo: ["state" : authState])
            }
        }
        
        //UINavigationBar
        let navigationBar = UINavigationBar.appearance()
        navigationBar.barTintColor = mainColor
        navigationBar.isTranslucent = false
        navigationBar.shadowImage = UIImage()
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationBar.barStyle = UIBarStyle.default
        navigationBar.tintColor = UIColor.white
        navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(Date()) - Background fetch")
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let appString = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String else { return true }
        return VKSdk.processOpen(url, fromApplication: appString)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.splashWindow?.resignKey()
        self.splashWindow?.isHidden = true
        self.window?.makeKeyAndVisible()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        self.splashWindow?.makeKeyAndVisible()
    }
}

extension AppDelegate: VKSdkDelegate {
    
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        NotificationCenter.default.post(name: NSNotification.Name(authNotification),
                                        object: nil,
                                        userInfo: ["state" : result.state])
    }

    func vkSdkUserAuthorizationFailed() {
        
    }
    
    func vkSdkAuthorizationStateUpdated(with result: VKAuthorizationResult!) {
        NotificationCenter.default.post(name: NSNotification.Name(authNotification),
                                        object: nil,
                                        userInfo: ["state" : result.state])
    }
}

extension AppDelegate: VKSdkUIDelegate {
    
    func vkSdkShouldPresent(_ controller: UIViewController!) {
       self.window?.rootViewController?.present(controller, animated: true, completion: nil)
    }
    
    func vkSdkNeedCaptchaEnter(_ captchaError: VKError!) {
        
    }
    
}
