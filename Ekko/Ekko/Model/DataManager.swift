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
    
//    // Init with default values
//    private init() {
//        sceneShip = SCNScene(named: "art.scnassets/ship.scn")!
//    }
//    
//    // MARK: - Prepare SCNScene
//    func prepareShipNode() {
//        let ship = sceneShip.rootNode.childNode(withName: "shipMesh", recursively: true)!
//        
//        // Set the pivot point of the AR scene to the center of the bounding box
//        
//        // 1. Get The Bounding Box Of The Node
//        let minimum = SIMD3<Float>(ship.boundingBox.min)
//        let maximum = SIMD3<Float>(ship.boundingBox.max)
//        
//        // 2. Set The Translation To Be Half Way Between The Vector
//        let translation = (maximum + minimum) * 0.5
//
//        // 3. Set The Pivot
//        ship.pivot = SCNMatrix4MakeTranslation(translation.x, translation.y, translation.z)
//        
//        // Animate the scene by rotating its y-axis on the centered pivot
////        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 1)))
//        // Scale down the size of the scene to better fit view boundary
//        ship.scale = SCNVector3(0.010, 0.010, 0.010)
//        // Set position so that the whole model is visible within view
//        ship.position = SCNVector3(0.0, 0.0, -0.8)
//    }
//    
//    func getShipScene() -> SCNScene {
//        return sceneShip
//    }
    
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
