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
}

final class Storage {

    private var defaults: UserDefaults!
    
    private init() {
        self.defaults = UserDefaults(suiteName: "group.flatstack.VK-Online")
    }
    
    static let shared: Storage = Storage()
    
    func set(object: [VKUser]) {
        let users = object.map { User(user: $0) }
        self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: users), forKey: StorageKeys.users.rawValue)
        self.defaults.synchronize()
    }
    
    func get() -> [VKUser] {
        guard let data = self.defaults.value(forKey: StorageKeys.users.rawValue) as? Data else { return [] }
        guard let users = NSKeyedUnarchiver.unarchiveObject(with: data) as? [User] else { return [] }
        return users.map { $0.user }
    }
}


final class User: VKUser, NSCoding {
    
    fileprivate var user: VKUser = VKUser()
    
    init(user: VKUser) {
        self.user = user
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.user.last_name, forKey: "last_name")
        aCoder.encode(self.user.first_name, forKey: "first_name")
        aCoder.encode(self.user.photo_100, forKey: "photo_100")
        aCoder.encode(self.user.online, forKey: "online")
        aCoder.encode(self.user.online, forKey: "online_mobile")
    }
    
    init?(coder aDecoder: NSCoder) {
        self.user.last_name = aDecoder.decodeObject(forKey: "last_name") as? String
        self.user.first_name = aDecoder.decodeObject(forKey: "first_name") as? String
        self.user.photo_100 = aDecoder.decodeObject(forKey: "photo_100") as? String
        self.user.online = aDecoder.decodeObject(forKey: "online") as? NSNumber
        self.user.online = aDecoder.decodeObject(forKey: "online_mobile") as? NSNumber
        super.init()
    }
    
}
