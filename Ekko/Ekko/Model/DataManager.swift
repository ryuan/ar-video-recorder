//
//  DataManager.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/17/22.
//

import Foundation
import UIKit
import SceneKit

class DataManager {
    public static let sharedInstance = DataManager()
    
//    private(set) var sceneShip: SCNScene
    
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
    
    // MARK: - Last scene option
    func saveLastScene(_ option: Int) {
        defaults.set(option, forKey: "LastScene")
        print("last scene saved: \(option)")
    }
    
    func getLastScene() -> Int {
        if UserDefaults.standard.object(forKey: "LastScene") != nil {
            print("last scene found: \(defaults.integer(forKey: "LastScene"))")
            return defaults.integer(forKey: "LastScene")
        } else {
            print("last scene not found - defaulting to 0")
            return 0
        }
    }
}
