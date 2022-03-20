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
    
    let defaults = UserDefaults.standard
    
    // MARK: - Last shooting option
    func saveLastOption(_ option: Int) {
        defaults.set(option, forKey: "LastOption")
    }
    
    func getLastOption() -> Int {
        if UserDefaults.standard.object(forKey: "LastOption") != nil {
            return defaults.integer(forKey: "LastOption")
        } else {
            return 0
        }
    }
}
