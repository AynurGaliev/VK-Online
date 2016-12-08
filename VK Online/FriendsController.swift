//
//  ViewController.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.ноября.2016.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import UIKit
import VKSdkFramework
import UserNotifications
import UserNotificationsUI
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
    var task: BackgroundTask? = nil
    var timer: Timer?
    var titleView: TitleView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let users: [User] = Storage.shared.get()
        self.categorise(users: users)
        
        self.titleView = Bundle.main.loadNibNamed("TitleView", owner: nil, options: nil)!.first! as! TitleView
        self.titleView.sizeToFit()
        self.navigationItem.titleView = self.titleView
        
        self.updateTitle(with: Storage.shared.get())
        
        self.task = BackgroundTask()
        self.task?.startBackgroundTask(time: 300) // 5 minutes
    
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(authStateChanged(sender:)),
                                               name: NSNotification.Name.init(authNotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(watchedFriendsChanged(sender:)),
                                               name: NSNotification.Name.init("WatchingFriendsDidChanged"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(lastUpdateDateChanged(sender:)),
                                               name: NSNotification.Name.init("LastUpdateDateDidChanged"),
                                               object: nil)
        
        
        self.tableView.registerCellNib(type: FriendCell.self)
        self.tableView.registerHeaderNib(type: HeaderView.self)
        self.tableView.sectionIndexColor = mainColor
        self.tableView.addSubview(self.refreshControl)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.categoryIdentifier = "com.flatstack.VK-Online.Category"
            content.title = "Title"
            content.subtitle = "Subtitle"
            content.sound = UNNotificationSound.default()
            content.badge = 1
            
            let request = UNNotificationRequest(identifier: "com.VK-Online.LocalNotification", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        })
        
    }
    
    func updateTitle(with date: Date?) {
        guard let lDate = date else {
            self.titleView.subtitleLabel.text = "Not updated yet"
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.default
        dateFormatter.dateFormat = "dd MMM"
        let firstPart = dateFormatter.string(from: lDate)
        dateFormatter.dateFormat = "HH:mm"
        let secondPart = dateFormatter.string(from: lDate)
        self.titleView.subtitleLabel.text = "Last updated \(firstPart) at \(secondPart)"
    }
    
    func watchedFriendsChanged(sender: Notification) {
        let users: [User] = Storage.shared.get()
        self.categorise(users: users)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func lastUpdateDateChanged(sender: Notification) {
        let date: Date? = Storage.shared.get()
        self.updateTitle(with: date)
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        let users: [User] = Storage.shared.get()
        self.categorise(users: users)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
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
            
            Storage.shared.set(lastUpdate: Date())
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name.init("LastUpdateDateDidChanged"), object: nil)
            }
            
            let mappedArray: [User] = array.map({ (vkUser) -> User in
            
                let user = User(user: vkUser)
                
                if let index = prevStateArray.index(where: { (currentItem) -> Bool in
                    return vkUser.id == currentItem.user.id
                })
                {
                    user.isWatching = prevStateArray[index].isWatching
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
        self.watchedFriends = [:]
        
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


