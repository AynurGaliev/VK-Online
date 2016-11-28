//
//  Helpers.swift
//  VK Online
//
//  Created by Aynur Galiev on 24.11.16.
//  Copyright © 2016 Aynur Galiev. All rights reserved.
//

import Foundation
import UIKit

let authNotification = "AuthNotification"

let mainColor = UIColor(red: 93.0/255.0, green: 137.0/255.0, blue: 179.0/255.0, alpha: 1.0)

extension String {
    
    var url: URL? {
        return URL(string: self)
    }
}

//MARK: -
extension NSObject {
    
    class var className: String {
        return String(describing: self)
    }
    
    var className: String {
        return type(of: self).className
    }
    
    class var moduleName: String {
        return NSStringFromClass(self).components(separatedBy: ".").first!
    }
}

extension String {
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
}

//MARK: -
enum XibSupportError: Swift.Error {
    case viewInNibNotFound
    case nibIsMissing
}

protocol XibSupport {
    static var nibFileName: String { get }
    static func getViewFromNib() throws -> Self
}

extension NSObject: XibSupport {
    
    class var nibFileName: String {
        return self.className
    }
    
    class func getNib() -> UINib {
        return UINib.init(nibName: self.nibFileName, bundle: Bundle(for: self))
    }
    
    class func getViewFromNib() throws -> Self {
        return try self.getViewFromNibHelper(self.nibFileName)
    }
    
    fileprivate static func getViewFromNibHelper<T>(_ nibName: String) throws -> T {
        guard let _ = Bundle.main.path(forResource: "\(nibName)", ofType: "nib") else { throw XibSupportError.nibIsMissing }
        let topLevelObjects = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil) ?? []
        
        for topLevelObject in topLevelObjects {
            if let object = topLevelObject as? T {
                return object
            }
        }
        throw XibSupportError.viewInNibNotFound
    }
}

extension UITableView {
    
    override open var contentInset: UIEdgeInsets {
        
        set(newValue) {
            
            if self.isTracking {
                let difference = newValue.top - self.contentInset.top
                var translation = self.panGestureRecognizer.translation(in: self)
                translation.y -= difference*1.45
                self.panGestureRecognizer.setTranslation(translation, in: self)
            }
            super.contentInset = newValue
        }
        get {
            return super.contentInset
        }
    }
}

extension UITableView {

    //MARK: -
    func registerCellClass<T: UITableViewCell>(type: T.Type) {
        self.register(type, forCellReuseIdentifier: T.className)
    }
    
    func registerCellNib<T: UITableViewCell>(type: T.Type) {
        self.register(T.getNib(), forCellReuseIdentifier: T.className)
    }
    
    func registerHeaderNib<T: UITableViewHeaderFooterView>(type: T.Type) {
        self.register(type.getNib(), forHeaderFooterViewReuseIdentifier: type.className)
    }
    
    func registerHeaderClass<T: UITableViewHeaderFooterView>(type: T.Type) {
        self.register(type, forHeaderFooterViewReuseIdentifier: type.className)
    }
    
    //MARK: -
    func dequeCell<T: UITableViewCell>() -> T {
        return self.dequeueReusableCell(withIdentifier: T.className) as! T
    }
    
    func dequeCell<T: UITableViewCell>(indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: T.className, for: indexPath) as! T
    }
    
    func dequeHeader<T: UITableViewHeaderFooterView>() -> T {
        return self.dequeueReusableHeaderFooterView(withIdentifier: T.className) as! T
    }

}
