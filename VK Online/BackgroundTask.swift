//
//  BackgroundTask.swift
//  VK Online
//
//  Created by Aynur Galiev on 28.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import AVFoundation
import VKSdkFramework
import UserNotifications
import UserNotificationsUI

final class BackgroundTask: NSObject {

    private var task: UIBackgroundTaskIdentifier?
    private var expirationDate: Date?
    private var timer: Timer?
    private var timeInterval: TimeInterval = 30
    private var target: Any?
    private var selector: Selector?
    private var player: AVAudioPlayer?
    private var session: URLSession?
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleRequest(notification:)), name: NSNotification.Name.init("DownloadDidFinished"), object: nil)
    }
    
    func handleRequest(notification: Notification) {
        
        guard let location = notification.userInfo?["url"] as? URL else { return }
        
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
                
                Storage.shared.set(lastUpdate: Date())
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name.init("LastUpdateDateDidChanged"), object: nil)
                }
                
                print("Count - \(array.count)")
                
                let mappedArray: [User] = array.map({ (vkUser) -> User in
                    
                    let user = User(user: vkUser)
                    
                    if let index = prevStateArray.index(where: { (currentItem) -> Bool in
                        return vkUser.id == currentItem.user.id
                    }) {
                        user.isWatching = prevStateArray[index].isWatching
                    }
                    return user
                })
                
                let watchingFriends: [String] = Storage.shared.get()
                print(watchingFriends)
                
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
                        
                        if #available(iOS 10.0, *) {
                            
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                            
                            let content = UNMutableNotificationContent()
                            content.categoryIdentifier = "com.flatstack.NotificationCategory"
                            content.title = "VK Online alert"
                            content.body = "Somebody appeared in online..." // Must not be empty
                            content.sound = UNNotificationSound.default()
                            content.badge = 1
                            content.userInfo["users"] = updatedFriends.map({ (user) -> String in
                                return "\(user.first_name!) \(user.last_name!)"
                            })
                            
                            let request = UNNotificationRequest(identifier: "com.VK-Online.LocalNotification", content: content, trigger: trigger)
                            
                            UNUserNotificationCenter.current().add(request)
                            
                        } else {
                         
                            let notification = UILocalNotification()
                            let friendsString = updatedFriends.map({ (user) -> String in
                                return "\(user.first_name!) \(user.last_name!)"
                            }).joined(separator: " ,")
                            notification.alertBody = "\(friendsString) appeared in online"
                            notification.alertTitle = "VK Online"
                            notification.hasAction = false
                            notification.fireDate = Date(timeIntervalSinceNow: 0)
                            notification.timeZone = NSTimeZone.default
                            notification.soundName = UILocalNotificationDefaultSoundName
                            notification.repeatInterval = NSCalendar.Unit(rawValue: UInt(0))
                            UIApplication.shared.scheduleLocalNotification(notification)
                        }
                    }
                }
                
            } catch let error {
                debugPrint(error)
            }
        }
    }
    
    func startBackgroundSession() {
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "com.flatstack.\(UUID().uuidString)")
        print("Session with \(sessionConfiguration.identifier!) started")
        sessionConfiguration.timeoutIntervalForRequest = 8
        sessionConfiguration.timeoutIntervalForResource = 8
        let session = URLSession(configuration: sessionConfiguration, delegate: UIApplication.shared.delegate as! AppDelegate, delegateQueue: OperationQueue.main)
        
        let request = VKApi.friends()!
        let friendsRequest = request.get([VK_API_FIELDS : ["photo_100,online,online_mobile"]])!
        var preparedRequest = friendsRequest.getPreparedRequest()!
        preparedRequest.timeoutInterval = 8
        
        let task = session.downloadTask(with: preparedRequest)
        
        task.resume()
    }
    
    func startBackgroundTask(time: TimeInterval) {
        self.timeInterval = time
        self.initBackgroundTask()
        
        UIApplication.shared.setKeepAliveTimeout(800) {
            self.initBackgroundTask()
        }
    }
    
    func initBackgroundTask() {
        
        DispatchQueue.main.async {
            if self.isRunning() {
                self.stopAudio()
            }
            while self.isRunning() {
                Thread.sleep(forTimeInterval: 10)
            }
            self.playAudio()
        }
    }
    
    @objc func audioInterrupted(notification: Notification) {
        guard let interuptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber else { return }
        if interuptionType.intValue == 1 {
            self.initBackgroundTask()
        }
    }
    
    func interruptionListenerCallback(notification: Notification) {
    }
    
    func playAudio() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.audioInterrupted(notification:)),
                                               name: NSNotification.Name.AVAudioSessionInterruption,
                                               object: nil)
        let expirationHandler = {
            UIApplication.shared.endBackgroundTask(self.task!)
            self.task = UIBackgroundTaskInvalid
            self.timer?.invalidate()
            self.timer = nil
            self.player?.stop()
            print("###############Background Task Expired")
        }
        
        self.task = UIApplication.shared.beginBackgroundTask(expirationHandler: expirationHandler)
        
        DispatchQueue.main.async {
            
            let bytes: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x26, 0x0, 0x0, 0x0, 0x57, 0x41, 0x56, 0x45, 0x66, 0x6d, 0x74, 0x20, 0x10, 0x0, 0x0, 0x0, 0x1, 0x0, 0x1, 0x0, 0x44, 0xac, 0x0, 0x0, 0x88, 0x58, 0x1, 0x0, 0x2, 0x0, 0x10, 0x0, 0x64, 0x61, 0x74, 0x61, 0x2, 0x0, 0x0, 0x0, 0xfc, 0xff]
        
            let data = Data(bytes: bytes)
            
            let docsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                              FileManager.SearchPathDomainMask.userDomainMask,
                                                              true).first!
            let filePath = docsDir + "/background.wav"
            let _ = FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
            
            let url = URL.init(fileURLWithPath: filePath)
            
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true)
                
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.volume = 0
                self.player?.numberOfLoops = -1
                self.player?.prepareToPlay()
                self.player?.play()
                self.timer = Timer.scheduledTimer(timeInterval: self.timeInterval,
                                                  target: self,
                                                  selector: #selector(self.timerCallback),
                                                  userInfo: nil,
                                                  repeats: true)
                
            } catch let error {
                print(error)
            }
        }
    }
    
    func timerCallback() {
        self.startBackgroundSession()
    }
    
    func stopAudio() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        if let lTimer = self.timer, lTimer.isValid {
            lTimer.invalidate()
        }
        if let lPlayer = self.player, lPlayer.isPlaying {
            lPlayer.stop()
        }
        if let lTask = self.task, lTask != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(lTask)
            self.task = UIBackgroundTaskInvalid
        }
    }
    
    func isRunning() -> Bool {
        guard let lTask = self.task else { return false }
        return lTask != UIBackgroundTaskInvalid
    }
    
    func stopBackgroundTask() {
        self.stopAudio()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init("DownloadDidFinished"), object: nil)
    }
}
