//
//  BackgroundTask.swift
//  VK Online
//
//  Created by Aynur Galiev on 28.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

final class BackgroundTask: NSObject {

    private var task: UIBackgroundTaskIdentifier?
    private var expirationDate: Date?
    private var timer: Timer?
    private var timeInterval: TimeInterval?
    private var target: AnyObject?
    private var selector: Selector?
    private var player: AVAudioPlayer?
    
    func startBackgroundTask(time: TimeInterval, target: AnyObject, selector: Selector) {
        self.timeInterval = time
        self.target = target
        self.selector = selector
        
        self.initBackgroundTask()
        
        UIApplication.shared.setKeepAliveTimeout(600) { 
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
        }
    }
    
    func audioInterrupted(notification: Notification) {
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
            //player.stop()
            print("###############Background Task Expired")
        }
        
        self.task = UIApplication.shared.beginBackgroundTask(expirationHandler: expirationHandler)
        
        DispatchQueue.main.async {
            
            let docsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                              FileManager.SearchPathDomainMask.userDomainMask,
                                                              true).first!
            let filePath = docsDir + "/background.wav"
            let success = FileManager.default.createFile(atPath: filePath, contents: Data.init(), attributes: nil)
            
            let url = URL.init(fileURLWithPath: filePath)
            
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true)
                
                self.player = try AVAudioPlayer.init(contentsOf: url)
                self.player?.volume = 0
                self.player?.numberOfLoops = -1
                self.player?.prepareToPlay()
                self.player?.play()
                self.timer = Timer.scheduledTimer(timeInterval: self.timeInterval!,
                                                  target: self.target,
                                                  selector: self.selector!,
                                                  userInfo: nil,
                                                  repeats: true)
                
            } catch let error {
                print(error)
            }
        }
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
}
