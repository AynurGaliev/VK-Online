//
//  AppDelegate.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import VKSdkFramework
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    var completionCallBack: (() -> ())?
    
    lazy var splashWindow: UIWindow? = {
        let window = UIWindow()
        let splashController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        window.rootViewController = splashController
        window.windowLevel = UIWindowLevelAlert
        return window
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        print(#function)
    
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
        
        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                
            })
            
            UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { (categories) in
                
            })
            
            UNUserNotificationCenter.current().delegate = self
            
            let showMoreAction = UNNotificationAction(identifier: "showMore", title: "Подробнее", options: [])
            let addBalanceAction = UNNotificationAction(identifier: "addBalance", title: "Пополнить на 500 ₽", options: [])
            let myPlanAction = UNNotificationAction(identifier: "myPlan", title: "Мой тариф", options: [])
            
            let balanceCategory = UNNotificationCategory(identifier: "com.flatstack.VK-Online.Category", actions: [showMoreAction, addBalanceAction, myPlanAction], intentIdentifiers: [], options: [])
            
            UNUserNotificationCenter.current().setNotificationCategories([balanceCategory])
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert], completionHandler: { (success, error) in
                
                if success && error == nil {
                    
                }
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                
                let content = UNMutableNotificationContent()
                content.categoryIdentifier = "com.flatstack.VK-Online.Category"
                content.title = "Title"
                content.subtitle = "Subtitle"
                content.sound = UNNotificationSound.default()
                content.badge = 1
                
                let request = UNNotificationRequest(identifier: "com.VK-Online.LocalNotification", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            })
        
        } else {
            application.registerUserNotificationSettings(UIUserNotificationSettings.init(types: [.alert, .sound], categories: nil))
        }
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print(#function)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print(#function)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let appString = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String else { return true }
        return VKSdk.processOpen(url, fromApplication: appString)
    }
}

extension AppDelegate: URLSessionDownloadDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print(#function)
        self.completionCallBack?()
        self.completionCallBack = nil
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print(#function)
        
        NotificationCenter.default.post(name: NSNotification.Name.init("DownloadDidFinished"), object: nil, userInfo: ["url" : location])
        
        if UIApplication.shared.applicationState == .active {
            self.completionCallBack?()
            self.completionCallBack = nil
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if challenge.protectionSpace.host == "api.vk.com" || challenge.protectionSpace.host == "vk.com" {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
                return
            }
        }
        
        completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        print(#function)
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if challenge.protectionSpace.host == "api.vk.com" || challenge.protectionSpace.host == "vk.com" {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
                return
            }
        }
        
        completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(#function)
        print(error)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(#function)
        print(error)
        
        if let _ = error {
            self.completionCallBack?()
            self.completionCallBack = nil
        }
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
