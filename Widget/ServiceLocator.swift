//
//  ServiceLocator.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit

public final class ServiceLocator {
    
    public static let instance = ServiceLocator()
    
    private var serviceRegistry: [String : Any] = [:]
    
    private init() {}
    
    func addService<T>(instance: T) {
        let key = String(describing: T.self)
        self.serviceRegistry[key] = instance
    }
    
    func getService<T>(type: T.Type) -> T {
        let key = String(describing: T.self)
        if let service = self.serviceRegistry[key] as? T {
            return service
        } else {
            fatalError("A service of \(String(describing: T.self)) is not registered!")
        }
    }
}
