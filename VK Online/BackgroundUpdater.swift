//
//  BackgroundUpdater.swift
//  VK Online
//
//  Created by Aynur Galiev on 27.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import VKSdkFramework

typealias CompletionHandler = (() -> ())?

final class BackgroundUpdater: NSObject, URLSessionDownloadDelegate {
    
    private var completionHandler: CompletionHandler
    
    static var shared: BackgroundUpdater = BackgroundUpdater()
    
    override init() { }
    
    func initialize() {
        let task = self.backgroundTask()
        self.perform(task: task, afterDelay: 0)
    }
    
    func handle(eventWith identifier: String,
                             handler: @escaping () -> Void) {
        
        debugPrint("Session with \(identifier) handled at \(Date())")
        self.completionHandler = handler
    }
    
    func backgroundTask() -> URLSessionDownloadTask {
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "com.flatstack.\(UUID().uuidString)")
        debugPrint("//////////////////////////////////////////////////////////")
        debugPrint("Background update with identifier \(sessionConfiguration.identifier!) started at \(Date())")
        sessionConfiguration.isDiscretionary = true
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        
        let request = VKApi.friends()!
        let friendsRequest = request.get([VK_API_FIELDS : ["photo_100,online,online_mobile"]])!
        let preparedRequest = friendsRequest.getPreparedRequest()!
        return session.downloadTask(with: preparedRequest)
    }
    
    func urlSession(_ session: URLSession,
                 downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL) {
        
        debugPrint(location)
        
        do {
            //let data = try Data.init(contentsOf: location)
            //debugPrint(data)
        } catch let error {
            //debugPrint(error)
        }
        
        self.completionHandler?()
        self.completionHandler = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
        debugPrint("Background update with identifier \(session.configuration.identifier!) finished at \(Date())")
        debugPrint("//////////////////////////////////////////////////////////")
        
        let task = self.backgroundTask()
        self.perform(task: task, afterDelay: 30)
    }
    
    func perform(task: URLSessionTask, afterDelay seconds: UInt32) {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.global().async {
            sleep(seconds)
            task.resume()
            semaphore.signal()
        }
        
        let _ = semaphore.wait(timeout: .now() + .seconds(40))
    }
}
