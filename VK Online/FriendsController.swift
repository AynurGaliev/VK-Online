//
//  ViewController.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import VKSdkFramework
import NotificationCenter

final class FriendsController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.lightGray
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    fileprivate var friends: [String:[User]] = [:]
    fileprivate var watchedFriends: [String:[User]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(authStateChanged(sender:)),
                                               name: NSNotification.Name.init(authNotification),
                                               object: nil)
        self.tableView.registerCellNib(type: FriendCell.self)
        self.tableView.registerHeaderNib(type: HeaderView.self)
        self.tableView.sectionIndexColor = UIColor.darkGray
        self.tableView.addSubview(self.refreshControl)
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        let users: [User] = Storage.shared.get()
        self.categorise(users: users)
        self.tableView.reloadData()
    }
    
    func authStateChanged(sender: Notification) {
        guard let state = sender.userInfo?["state"] as? VKAuthorizationState else { return }
        guard state == .authorized else { return }
        self.performRequest()
    }
    
    func refresh(sender: AnyObject) {
        self.performRequest()
    }
    
    func performRequest() {
        
        let request = VKApi.friends()
        let friendsRequest = request?.get([VK_API_FIELDS : ["photo_100,online,online_mobile"]])
        friendsRequest?.responseQueue = DispatchQueue.global()
        friendsRequest?.execute(resultBlock: { (response: VKResponse<VKApiObject>?) in
            
            guard let JSON = response?.json as? Dictionary<String, Any> else { return }
            guard let usersArray = VKUsersArray(dictionary: JSON) else { return }
            let array = usersArray.items.map { $0 as! VKUser }
            
            let prevStateArray: [User] = Storage.shared.get()
            
            let mappedArray: [User] = array.map({ (vkUser) -> User in
            
                let user = User(user: vkUser)
                
                if let index = prevStateArray.index(where: { (currentItem) -> Bool in
                    return vkUser.id == currentItem.user.id
                })
                {
                    guard let prevOnline = prevStateArray[index].online else { return user }
                    user.user.online = prevOnline
                }
                return user
            })

            Storage.shared.set(object: mappedArray)
            self.categorise(users: mappedArray)
            
        }, errorBlock: { (error) in
            debugPrint("Fail to perform request")
        })
    }
    
    func categorise(users array: [User]) {
        
        self.friends = [:]
        
        array.forEach { (user: User) in
            
            let firstSymbol = user.user.last_name.lowercased().substring(with: 0..<1)
            
            if let users = self.friends[firstSymbol] {
                var newUsers = Array(users)
                newUsers.append(user)
                newUsers.sort(by: { (left, right) -> Bool in
                    return left.user.last_name > right.user.last_name
                })
                self.friends[firstSymbol] = newUsers
            } else {
                self.friends[firstSymbol] = [user]
            }
            
            if user.isWatching {
            
                if let users = self.watchedFriends[firstSymbol] {
                    var newUsers = Array(users)
                    newUsers.append(user)
                    newUsers.sort(by: { (left, right) -> Bool in
                        return left.user.last_name > right.user.last_name
                    })
                    self.watchedFriends[firstSymbol] = newUsers
                } else {
                    self.watchedFriends[firstSymbol] = [user]
                }
            }
        }
        
        DispatchQueue.main.async {
            NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: "com.flatstack.VK-Online.Widget")
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    var sortedKeys: [String] {
        let keys = Array(self.friends.keys)
        return keys.sorted()
    }
    
    var watchedSortedKeys: [String] {
        let keys = Array(self.watchedFriends.keys)
        return keys.sorted()
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension FriendsController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.segmentControl.selectedSegmentIndex == 0 {
            return self.friends.keys.count
        } else {
            return self.watchedFriends.keys.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.segmentControl.selectedSegmentIndex == 0 {
            let key = self.sortedKeys[section]
            return self.friends[key]?.count ?? 0
        } else {
            let key = self.watchedSortedKeys[section]
            return self.watchedFriends[key]?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: FriendCell = tableView.dequeCell()
        
        if self.segmentControl.selectedSegmentIndex == 0 {
            let key = self.sortedKeys[indexPath.section]
            if let users = self.friends[key] {
                cell.prepareCell(user: users[indexPath.row])
            }
        } else {
            let key = self.watchedSortedKeys[indexPath.section]
            if let users = self.watchedFriends[key] {
                cell.prepareCell(user: users[indexPath.row])
            }
        }
        
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if self.segmentControl.selectedSegmentIndex == 0 {
            return self.sortedKeys.map { $0.uppercased() }
        } else {
            return self.watchedSortedKeys.map { $0.uppercased() }
        }
    }
}

extension FriendsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view: HeaderView = tableView.dequeHeader()
        
        var key: String = ""
        if self.segmentControl.selectedSegmentIndex == 0 {
            key = self.sortedKeys[section]
            guard let users = self.friends[key], users.count > 0 else { return nil }
        } else {
            key = self.watchedSortedKeys[section]
            guard let users = self.watchedFriends[key], users.count > 0 else { return nil }
        }
        
        view.label.text = key.uppercased()
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28.0
    }
}


