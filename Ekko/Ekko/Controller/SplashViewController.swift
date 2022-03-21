//
//  SplashViewController.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/20/22.
//

import UIKit
import ARKit

class SplashViewController: UIViewController, ARSCNViewDelegate {
    //
    // MARK: - Properties
    //
    var autoDismiss = false
    var label = "hi there"
    
    //
    // MARK: - IBOutlets
    //
    @IBOutlet weak var screenLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var splashSceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let ship = scene.rootNode.childNode(withName: "shipMesh", recursively: true)!

        // Set the pivot point of the AR scene to the center of the bounding box

        // 1. Get The Bounding Box Of The Node
        let minimum = SIMD3<Float>(ship.boundingBox.min)
        let maximum = SIMD3<Float>(ship.boundingBox.max)

        // 2. Set The Translation To Be Half Way Between The Vector
        let translation = (maximum + minimum) * 0.5

        // 3. Set The Pivot
        ship.pivot = SCNMatrix4MakeTranslation(translation.x, translation.y, translation.z)

        // Animate the scene by rotating its y-axis on the centered pivot
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 1)))
        // Scale down the size of the scene to better fit view boundary
        ship.scale = SCNVector3(0.015, 0.015, 0.015)
        // Set position so that the whole model is visible within view
        ship.position = SCNVector3(0.0, 0.0, -0.8)
        
        splashSceneView.scene = scene
        splashSceneView.backgroundColor = UIColor.systemGreen
    }
    
    //
    // MARK: - Lifecyle
    //
    
    override func viewWillAppear(_ animated: Bool) {
        print("ViewWillAppear")
        
        self.screenLabel.text = self.label

        // If auto-dismissing hide the button and rely on tap to dismiss
        if self.autoDismiss {
            self.continueButton.isHidden = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.dismiss(animated: true, completion: {
                    print("done")
                })
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
    //
    // MARK: - IBActions
    //

    @IBAction func tapContinue(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
