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
import SafariServices

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
            
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            let cancelAction = UNNotificationAction(identifier: "com.flatstack.Cancel", title: "Cancel", options: UNNotificationActionOptions.destructive)
            let openAction = UNNotificationAction(identifier: "com.flatstack.Open", title: "Open in App", options: UNNotificationActionOptions.foreground)
            
            let mainCategory = UNNotificationCategory(identifier: "com.flatstack.NotificationCategory", actions: [cancelAction, openAction], intentIdentifiers: [], options: [])
            
            center.setNotificationCategories([mainCategory])
            
            center.requestAuthorization(options: [.alert, .sound], completionHandler: { (success, error) in
                print(error)
            })
        
        } else {
            application.registerUserNotificationSettings(UIUserNotificationSettings.init(types: [.alert, .sound], categories: nil))
        }
        
        return true
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    @available(iOS 10.0, *)
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

extension AppDelegate: VKSdkUIDelegate, SFSafariViewControllerDelegate {
    
    func vkSdkShouldPresent(_ controller: UIViewController!) {
        
        let _ = controller.view
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            guard let navController = self.window?.rootViewController as? UINavigationController else { return }
            guard let topViewController = navController.topViewController else { return }
            topViewController.present(controller, animated: true, completion: nil)
        }
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    }
    
    func vkSdkNeedCaptchaEnter(_ captchaError: VKError!) {
        
    }
    
}
