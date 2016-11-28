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
class AppDelegate: UIResponder, UIApplicationDelegate {

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
        print(application.backgroundRefreshStatus.rawValue)
    
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

        application.registerUserNotificationSettings(UIUserNotificationSettings.init(types: [.alert, .sound], categories: nil))
        UNUserNotificationCenter
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "com.flatstack.\(UUID().uuidString)")
        print("\(Date()) - Init fetch with \(sessionConfiguration.identifier!)")
        //sessionConfiguration.isDiscretionary = true
        let session = URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        
        var request = URLRequest.init(url: "https://vk.com/feed?section=comments".url!)
        request.timeoutInterval = 15
        
        let task = session.downloadTask(with: request)
        
        task.resume()
        
        return true
    }
    
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(Date()) - Background fetch")
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("\(Date()) - Session  with \(identifier)")
        self.completionCallBack = completionHandler
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
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print(#function)
        self.splashWindow?.resignKey()
        self.splashWindow?.isHidden = true
        self.window?.makeKeyAndVisible()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print(#function)
        self.splashWindow?.makeKeyAndVisible()
    }
}

extension AppDelegate: URLSessionDownloadDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("\(Date()) - Complete with \(session.configuration.identifier!)")
        self.completionCallBack?()
        self.completionCallBack = nil
        self.startBackgroundSession()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print(#function)
        
        if UIApplication.shared.applicationState == .active {
            self.completionCallBack?()
            self.completionCallBack = nil
            self.startBackgroundSession()
        }
        
        guard let handle = try? FileHandle.init(forReadingFrom: location) else {
            print("Failed to create file handle")
            return
        }
        let data = handle.readDataToEndOfFile()
        
        DispatchQueue.global().async {
    
            do {

                let dict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : Any]
                guard let response = dict?["response"] as? Dictionary<String,Any> else { print("Serialization error at line \(#line) with \(dict)"); return }
                
                guard let usersArray = VKUsersArray(dictionary: response) else { print("Array creation error at line \(#line) with \(response)"); return }
                let array = usersArray.items.map { $0 as! VKUser }
                let prevStateArray: [User] = Storage.shared.get()
                
                print("Count - \(array.count)")
                
                let mappedArray: [User] = array.map({ (vkUser) -> User in

                    let user = User(user: vkUser)

                    if let index = prevStateArray.index(where: { (currentItem) -> Bool in
                        return vkUser.id == currentItem.user.id
                    }) {
                        guard let prevOnline = prevStateArray[index].online else { return user }
                        user.user.online = prevOnline
                    }
                    return user
                })
                
                let watchingFriends: [String] = Storage.shared.get()
                
                let filteredArray = prevStateArray.filter { (item) -> Bool in
                    return watchingFriends.contains(item.user.id.stringValue)
                }
                
                var updatedFriends: [VKUser] = []
                
                filteredArray.forEach({ (item) in
                    print("\(item.user.first_name) \(item.user.last_name) was \(item.user.online)")
                    if let index = mappedArray.index(where: { (currentItem) -> Bool in
                        return item.user.id == currentItem.user.id &&
                               item.user.online != currentItem.user.online &&
                               currentItem.user.online.boolValue
                    }) {
                        updatedFriends.append(array[index])
                    }
                })
                
                Storage.shared.set(object: mappedArray)
    
                if updatedFriends.count > 0 {
                
                    DispatchQueue.main.async {
                        let notification = UILocalNotification()
                        let friendsString = updatedFriends.map({ (user) -> String in
                            return "\(user.first_name!) \(user.last_name!)"
                        }).joined(separator: " ,")
                        notification.alertBody = "\(friendsString) appeared in online"
                        notification.alertTitle = "VK Online"
                        notification.hasAction = false
                        notification.fireDate = Date(timeIntervalSinceNow: 5)
                        notification.timeZone = NSTimeZone.default
                        notification.soundName = UILocalNotificationDefaultSoundName
                        notification.repeatInterval = NSCalendar.Unit(rawValue: UInt(0))
                        UIApplication.shared.scheduleLocalNotification(notification)
                    }
                }
                
            } catch let error {
                debugPrint(error)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
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

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(error)
        print(#function)
        if let _ = error {
            self.startBackgroundSession()
        }
    }
    
    func startBackgroundSession(delay: Int = 20) {
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "com.flatstack.\(UUID().uuidString)")
        print("\(Date()) - Started with \(sessionConfiguration.identifier!)")
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        
        let request = VKApi.friends()!
        let friendsRequest = request.get([VK_API_FIELDS : ["photo_100,online,online_mobile"]])!
        var preparedRequest = friendsRequest.getPreparedRequest()!
        preparedRequest.timeoutInterval = 15
        
        let task = session.downloadTask(with: preparedRequest)
        
        if delay == 0 {
            task.resume()
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            print("Start 1 - \(Date.init())")
            DispatchQueue.global().async {
                print(Thread.current)
                print("Start 2 - \(Date.init())")
                sleep(UInt32(delay+10))
                print("Start 3 - \(Date.init())")
                task.resume()
                semaphore.signal()
            }
            
            //Thread.sleep(forTimeInterval: <#T##TimeInterval#>)
            
            let _ = semaphore.wait(timeout: .now() + .seconds(delay))
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(error)
        print(#function)
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
