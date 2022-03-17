//
//  DataManager.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/17/22.
//

import Foundation
import UIKit

class DataManager {
    public static let sharedInstance = DataManager()
    
    // MARK: - Last shooting option
    func saveLastOption(_ option: Int) {
        UserDefaults.standard.set(option, forKey: "LastOption")
    }
    
    func getLastOption() -> Int {
        if UserDefaults.standard.object(forKey: "LastOption") != nil {
            return UserDefaults.standard.integer(forKey: "LastOption")
        } else {
            return 0
        }
    }
}
