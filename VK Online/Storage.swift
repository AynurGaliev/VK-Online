//
//  Storage.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.11.16.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import VKSdkFramework

enum StorageKeys: String {
    case users = "users"
    case lastUpdate = "lastUpdate"
    case watchIDs = "watchIDs"
}

final class Storage {

    private var defaults: UserDefaults!
    
    private init() {
        self.defaults = UserDefaults(suiteName: "group.flatstack.VK-Online")
    }
    
    static let shared: Storage = Storage()
    
    //Last update
    func set(lastUpdate: Date) {
        self.defaults.set(nil,
                          forKey: StorageKeys.lastUpdate.rawValue)
        self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: lastUpdate),
                          forKey: StorageKeys.lastUpdate.rawValue)
        self.defaults.synchronize()
    }
    
    func get() -> Date? {
        guard let data = self.defaults.value(forKey: StorageKeys.lastUpdate.rawValue) as? Data else { return nil }
        guard let date = NSKeyedUnarchiver.unarchiveObject(with: data) as? Date else { return nil }
        return date
    }
    
    //Watched users
    func set(ids: [String]) {
        self.defaults.set(nil,
                          forKey: StorageKeys.watchIDs.rawValue)
        self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: ids),
                          forKey: StorageKeys.watchIDs.rawValue)
        self.defaults.synchronize()
    }
    
    func get() -> [String] {
        guard let data = self.defaults.value(forKey: StorageKeys.watchIDs.rawValue) as? Data else { return [] }
        guard let IDs = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String] else { return [] }
        return IDs
    }
    
    //Users
    func set(object: [User]) {
        self.defaults.set(nil, forKey: StorageKeys.users.rawValue)
        let data = NSKeyedArchiver.archivedData(withRootObject: object as NSArray)
        self.defaults.set(data, forKey: StorageKeys.users.rawValue)
        self.defaults.synchronize()
    }
    
    func get() -> [User] {
        guard let data = self.defaults.value(forKey: StorageKeys.users.rawValue) as? Data else { return [] }
        guard let users = NSKeyedUnarchiver.unarchiveObject(with: data) as? [User] else { return [] }
        return users.map { $0 }
    }
}


final class User: NSObject, NSCoding {
    
    private(set) var user: VKUser = VKUser()
    var isWatching: Bool = false
    
    init(user: VKUser) {
        super.init()
        self.user = user
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.isWatching, forKey: "isWatching")
        aCoder.encode(self.user.id, forKey: "id")
        aCoder.encode(self.user.last_name, forKey: "last_name")
        aCoder.encode(self.user.first_name, forKey: "first_name")
        aCoder.encode(self.user.photo_100, forKey: "photo_100")
        aCoder.encode(self.user.online, forKey: "online")
        aCoder.encode(self.user.online_mobile, forKey: "online_mobile")
    }
    
    init?(coder aDecoder: NSCoder) {
        self.isWatching = aDecoder.decodeBool(forKey: "isWatching")
        self.user.id = aDecoder.decodeObject(forKey: "id") as? NSNumber
        self.user.last_name = aDecoder.decodeObject(forKey: "last_name") as? String
        self.user.first_name = aDecoder.decodeObject(forKey: "first_name") as? String
        self.user.photo_100 = aDecoder.decodeObject(forKey: "photo_100") as? String
        self.user.online = aDecoder.decodeObject(forKey: "online") as? NSNumber
        self.user.online_mobile = aDecoder.decodeObject(forKey: "online_mobile") as? NSNumber
    }
    
}
