//
//  DataManager.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/17/22.
//

import UIKit
import SceneKit
import AVFoundation

class DataManager {
    public static let sharedInstance = DataManager()
    
    private(set) var player: AVQueuePlayer?
    private(set) var playerLooper: AVPlayerLooper?
    let defaults = UserDefaults.standard
    
    private init() {
        guard let path = Bundle.main.path(forResource: "ocean", ofType: ".mp4") else {
            return
        }
        
        // Load the resource
        let video = AVAsset(url: URL(fileURLWithPath: path))
        let playerItem = AVPlayerItem(asset: video)
        
        // Setup the player
        player = AVQueuePlayer(playerItem: playerItem)
        
        // Create a new player looper with the queue player and template item
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
    }
    
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
