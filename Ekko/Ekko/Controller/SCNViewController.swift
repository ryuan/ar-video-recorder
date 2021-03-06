//
//  SCNViewController.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/13/22.
//

import UIKit
import ARKit
import ARVideoKit
import Photos

class SCNViewController: UIViewController, ARSCNViewDelegate, RenderARDelegate, RecordARDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var stopSquareView: UIView!
    @IBOutlet weak var circleProgressBtn: UIButton!
    @IBOutlet weak var optionButton: UIButton!
    @IBOutlet weak var sceneLabel: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    
    var recorder: RecordAR?
    var circleProgressView: CircleProgressView?
    var currentOption: Int?
    var currentScene: Int?
    
    // Prepare dispatch queue to leverage GCD for running multithreaded operations
    let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    let snappingQueue = DispatchQueue(label: "snappingThread", attributes: .concurrent)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Load the last used scene, otherwise render default scene
        currentScene = DataManager.sharedInstance.getLastScene()
        playScene(currentScene ?? 0)
        
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        // Programmatically make button and loading ring into circle
        recordBtn.layer.cornerRadius = recordBtn.frame.width / 2
        recordBtn.layer.masksToBounds = true
        circleProgressBtn.layer.cornerRadius = circleProgressBtn.frame.width / 2
        circleProgressBtn.layer.masksToBounds = true
        circleProgressBtn.layer.borderWidth = 4
        circleProgressBtn.layer.borderColor = UIColor.white.cgColor
        
        // Programmatically round edges of square stop recording symbol
        stopSquareView.layer.cornerRadius = 5
        stopSquareView.layer.masksToBounds = true
        
        // Initialize initial shooting option based on last option (or 1/video initial)
        let lastOption = DataManager.sharedInstance.getLastOption()
        currentOption = lastOption
        if currentOption == 0 {
            optionButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        } else {
            optionButton.setImage(UIImage(systemName: "livephoto"), for: .normal)
        }
        
        /*-------- Prepare ARVideoKit recorder --------*/
        
        // Initialize ARVideoKit recorder
        recorder = RecordAR(ARSceneKit: sceneView)
        
        // Set the recorder's delegate
        recorder?.delegate = self
        // Set the renderer's delegate
        recorder?.renderAR = self
        // Configure the renderer to perform additional image & video processing
        recorder?.onlyRenderWhileRecording = false
        // Configure ARKit content mode. Default is .auto
        recorder?.contentMode = .aspectFill
        // Add environment light rendering. Default is false
        recorder?.enableAdjustEnvironmentLighting = true
        // Set the UIViewController orientations
        recorder?.inputViewOrientations = [.landscapeLeft, .landscapeRight, .portrait]
        // Configure RecordAR to store media files in local app directory
        recorder?.deleteCacheWhenExported = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        // Prepare the recorder with sessions configuration
        recorder?.prepare(configuration)
        
        // Prompt user for app review if app opened enough times (set to 3).
        StoreReviewHelper.checkAndAskForReview(atController: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        if recorder?.status == .recording {
            recorder?.stopAndExport()
        }
        recorder?.onlyRenderWhileRecording = true
        recorder?.prepare(ARWorldTrackingConfiguration())
        
        // Switch off the orientation lock for UIViewControllers with AR Scenes
        recorder?.rest()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Hide Status Bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Present post-exporting UIAlert
    // REMINDER TO SELF: Method must be called on main thread or app will crash!!!
    func exportMessage(success: Bool, status: PHAuthorizationStatus) {
        if success {
            let alert = UIAlertController(title: "Saved!", message: "Media exported to your camera roll!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if status == .denied || status == .restricted || status == .notDetermined {
            let errorView = UIAlertController(title: "Access Required", message: "Please allow access to the photo library in order to save the file.", preferredStyle: .alert)
            let settingsBtn = UIAlertAction(title: "Open Settings", style: .cancel) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        })
                    } else {
                        UIApplication.shared.openURL(URL(string:UIApplication.openSettingsURLString)!)
                    }
                }
            }
            errorView.addAction(UIAlertAction(title: "Later", style: UIAlertAction.Style.default, handler: {
                (UIAlertAction)in
            }))
            errorView.addAction(settingsBtn)
            self.present(errorView, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Exporting Failed", message: "There was an error while exporting your media file.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}


// MARK: - Gesture Methods

extension SCNViewController {
    @IBAction func swipeMade(_ sender: UISwipeGestureRecognizer) {
        if recorder?.status == .readyToRecord {
            guard let prevScene = currentScene else {
                return
            }
            if sender.direction == .right {
                print("swiped right!")
                if prevScene > 0 {
                    currentScene = prevScene - 1
                    playScene(currentScene!)
                    DataManager.sharedInstance.saveLastScene(currentScene ?? 0)
                }
            }
            if sender.direction == .left {
                print("swiped left!")
                if prevScene < 2 {
                    currentScene = prevScene + 1
                    playScene(currentScene!)
                    DataManager.sharedInstance.saveLastScene(currentScene ?? 0)
                }
            }
        }
    }
}


// MARK: - Prepare and play SCNScenes

extension SCNViewController {
    func playScene(_ sceneOption: Int) {
        print(sceneOption)
        
        switch sceneOption {
        case 0:
            prepareShip()
            sceneLabel.text = "??????"
        case 1:
            prepareFox()
            sceneLabel.text = "????"
        case 2:
            prepareSphere()
            sceneLabel.text = "????"
        default:
            prepareShip()
            sceneLabel.text = "??????"
        }
        
        // Reset the recorder with new RecordAR instance to align all rendering threads for recording
        recorder = RecordAR(ARSceneKit: sceneView)
    }
    
    func prepareShip() {
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Ship/ship.scn")!
        let ship = scene.rootNode.childNode(withName: "shipMesh", recursively: true)!

        // Set pivot point away from ship body
        ship.pivot = SCNMatrix4MakeTranslation(40, 0, 0)
        // Rotate the ship towards its direction of movement
        ship.eulerAngles = SCNVector3Make(0, -90, 0);

        // Animate the ship so it spins around its pivot axis
        let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi), z: 0, duration: 6.0)
        let hoverUp = SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 2.5)
        let hoverDown = SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 2.5)
        let hoverSequence = SCNAction.sequence([hoverUp, hoverDown])
        let rotateAndHover = SCNAction.group([rotateOne, hoverSequence])
        let repeatForever = SCNAction.repeatForever(rotateAndHover)
        ship.runAction(repeatForever)

        // Scale down the size of the scene to better fit live camera feed
        ship.scale = SCNVector3(0.012, 0.012, 0.012)
        // Set position so that the model is comfortable height and distance from device
        ship.position = SCNVector3(0.0, -0.1, -1.2)

        // Set the scene to the view
        self.sceneView.scene = scene
    }
    
    func prepareSphere() {
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Sphere/sphere.scn")!
        let sphere = scene.rootNode.childNode(withName: "sphereMesh", recursively: true)!

        self.centerPivot(sphere)

        // Animate the sphere so it rotates and gently bobbles up and down
        let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi), z: 0, duration: 5.0)
        let hoverUp = SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 2.5)
        let hoverDown = SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 2.5)
        let hoverSequence = SCNAction.sequence([hoverUp, hoverDown])
        let rotateAndHover = SCNAction.group([rotateOne, hoverSequence])
        let repeatForever = SCNAction.repeatForever(rotateAndHover)
        sphere.runAction(repeatForever)

        // Scale down the size of the scene to better fit live camera feed
        sphere.scale = SCNVector3(0.3, 0.3, 0.3)
        // Set position so that the model is comfortable height and distance from device
        sphere.position = SCNVector3(0.0, 0.0, -1.0)

        // Set the scene to the view
        self.sceneView.scene = scene
    }
    
    func prepareFox() {
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Fox/max.scn")!
        let model = scene.rootNode.childNode(withName: "Max_rootNode", recursively: true)!
        
        // Prepare and load different fox animations onto base model
        let idleAnimation = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "art.scnassets/Fox/max_idle.scn")
        idleAnimation.stop()
        model.addAnimationPlayer(idleAnimation, forKey: "idle")
        let walkAnimation = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "art.scnassets/Fox/max_walk.scn")
        walkAnimation.stop()
        model.addAnimationPlayer(walkAnimation, forKey: "walk")
        let jumpAnimation = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "art.scnassets/Fox/max_jump.scn")
        jumpAnimation.stop()
        model.addAnimationPlayer(jumpAnimation, forKey: "jump")
        let spinAnimation = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "art.scnassets/Fox/max_spin.scn")
        spinAnimation.stop()
        model.addAnimationPlayer(spinAnimation, forKey: "spin")

        // Recursively call circleLeft and circleRight. Start with circleRight.
        pauseSpin(model)

        // Scale up the size of the scene to better fit live camera feed
        model.scale = SCNVector3(1.5, 1.5, 1.5)

        // Set the scene to the view
        self.sceneView.scene = scene
    }
    
    func pauseSpin(_ node: SCNNode) {
        node.animationPlayer(forKey: "idle")?.play()

        node.position = SCNVector3(0.25, -1.5, -1.5)

        let pause = SCNAction.wait(duration: 1.5)
        node.runAction(pause) {
            node.animationPlayer(forKey: "spin")?.play()
            node.runAction(pause) {
                self.circleRight(node)
            }
        }
    }

    func circleRight(_ node: SCNNode) {
        node.animationPlayer(forKey: "walk")?.play()
        
        // Set pivot point away from fox body
        node.pivot = SCNMatrix4MakeTranslation(0.5, 0, 0)
        // Set position of fox to center ahead of device after adjusting pivot (considering circleLeft)
        node.position = SCNVector3(-0.5, -1.5, -1.5)
        
        // Assign semicircle with arcRight, then sequence it twice for a full circle
        let arcRight = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi), z: 0, duration: 3.0)
        let circleRight = SCNAction.sequence([arcRight, arcRight])
        
        node.runAction(circleRight) {
            self.circleLeft(node)
        }
    }
    
    func circleLeft(_ node: SCNNode) {
        node.animationPlayer(forKey: "walk")?.play()
        
        // Set pivot point away from fox body
        node.pivot = SCNMatrix4MakeTranslation(-0.5, 0, 0)
        // Set position of fox to center ahead of device after adjusting pivot (considering circleRight)
        node.position = SCNVector3(1, -1.5, -1.5)
        
        // Assign semicircle with arcLeft, then sequence it twice for a full circle
        let arcLeft = SCNAction.rotateBy(x: 0, y: -CGFloat(Float.pi), z: 0, duration: 3.0)
        let circleLeft = SCNAction.sequence([arcLeft, arcLeft])
        
        node.runAction(circleLeft) {
            self.circleRight(node)
        }
    }
    
    func centerPivot(_ node: SCNNode) {
        // Set the pivot point of the AR scene to the center of the bounding box
        
        // 1. Get The Bounding Box Of The Node
        let minimum = SIMD3<Float>(node.boundingBox.min)
        let maximum = SIMD3<Float>(node.boundingBox.max)
        
        // 2. Set The Translation To Be Half Way Between The Vector
        let translation = (maximum + minimum) * 0.5

        // 3. Set The Pivot
        node.pivot = SCNMatrix4MakeTranslation(translation.x, translation.y, translation.z)
    }
}

extension SCNAnimationPlayer {
    class func loadAnimation(fromSceneNamed sceneName: String) -> SCNAnimationPlayer {
        let scene = SCNScene( named: sceneName )!
        // find top level animation
        var animationPlayer: SCNAnimationPlayer! = nil
        scene.rootNode.enumerateChildNodes { (child, stop) in
            if !child.animationKeys.isEmpty {
                animationPlayer = child.animationPlayer(forKey: child.animationKeys[0])
                stop.pointee = true
            }
        }
        return animationPlayer
    }
}


// MARK: - Button Action Methods

extension SCNViewController {
    @IBAction func close(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func shoot(_ sender: UIButton) {
        if currentOption == 0 {
            print("video option recognized:")
            
            // Record with duration
            if recorder?.status == .readyToRecord {
                // Recording started. Set to Record
                print("recording started")
                
                sender.backgroundColor = .red
                stopSquareView.backgroundColor = .systemPink
                optionButton.isEnabled = false
                
                // Generate circle progress ring
                let loadingView = CircleProgressView(progress: 1, baseColor: .white, progressColor: .red)
                loadingView.bounds = CGRect(x: 0, y: 0, width: 85, height: 85)
                loadingView.center = sender.center
                self.view.insertSubview(loadingView, belowSubview: recordBtn)
                loadingView.animateCircle(duration: 10, delay: 0.5)
                
                circleProgressView = loadingView
                circleProgressBtn.layer.borderColor = UIColor.clear.cgColor
                
                recordingQueue.async {
                    self.recorder?.record(forDuration: 10) { path in
                        self.recorder?.export(video: path) { saved, status in
                            DispatchQueue.main.sync {
                                // Recording stopped. Set to readyToRecord
                                sender.backgroundColor = .white
                                self.stopSquareView.backgroundColor = .clear
                                self.optionButton.isEnabled = true
                                self.circleProgressBtn.layer.borderColor = UIColor.white.cgColor
                                loadingView.removeFromSuperview()
                                self.exportMessage(success: saved, status: status)
                            }
                        }
                    }
                }
            } else if recorder?.status == .recording {
                // Recording stopped. Set to readyToRecord
                print("terminated recording")
                
                sender.backgroundColor = .white
                stopSquareView.backgroundColor = .clear
                optionButton.isEnabled = true
                
                circleProgressBtn.layer.borderColor = UIColor.white.cgColor
                circleProgressView?.removeFromSuperview()
                
                recorder?.stop() { path in
                    self.recorder?.export(video: path) { saved, status in
                        DispatchQueue.main.sync {
                            self.exportMessage(success: saved, status: status)
                        }
                    }
                }
            }
        } else {
            print("live photo option recognized:")
            
            // Live photo
            if recorder?.status == .readyToRecord {
                print("snapping live photo")
                
                sender.backgroundColor = .red
                optionButton.isEnabled = false
                
                // Generate circle progress ring
                let loadingView = CircleProgressView(progress: 1, baseColor: .white, progressColor: .red)
                loadingView.bounds = CGRect(x: 0, y: 0, width: 85, height: 85)
                loadingView.center = sender.center
                self.view.insertSubview(loadingView, belowSubview: recordBtn)
                loadingView.animateCircle(duration: 3, delay: 0.75)
                
                circleProgressBtn.layer.borderColor = UIColor.clear.cgColor
                
                snappingQueue.async {
                    self.recorder?.livePhoto(export: true) { ready, photo, status, saved in
                        /*
                         if ready {
                         // Do something with the `photo` (PHLivePhotoPlus)
                         }
                         */
                        
                        if saved {
                            // Inform user Live Photo has exported successfully
                            print("live photo successfully saved")
                            DispatchQueue.main.sync {
                                sender.backgroundColor = .white
                                self.optionButton.isEnabled = true
                                self.circleProgressBtn.layer.borderColor = UIColor.white.cgColor
                                loadingView.removeFromSuperview()
                                self.exportMessage(success: saved, status: status)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func changeOption(_ sender: UIButton) {
        if currentOption == 0 {
            optionButton.setImage(UIImage(systemName: "livephoto"), for: .normal)
            currentOption = 1
        } else {
            optionButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
            currentOption = 0
        }
        DataManager.sharedInstance.saveLastOption(currentOption!)
    }
}


// MARK: - ARVideoKit Delegate Methods

extension SCNViewController {
    func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        // Do some image/video processing.
    }
    
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError {
            // Do something with the video path.
        }
    }
    
    func recorder(didFailRecording error: Error?, and status: String) {
        // Inform user an error occurred while recording.
    }
    
    func recorder(willEnterBackground status: RecordARStatus) {
        // Use this method to pause or stop video recording. Check [applicationWillResignActive(_:)](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622950-applicationwillresignactive) for more information.
        if status == .recording {
            recorder?.stopAndExport()
        }
    }
}
