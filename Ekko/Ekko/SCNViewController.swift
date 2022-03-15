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
    
    var recorder: RecordAR?
    var circleProgressView: CircleProgressView?
    
    // Prepare dispatch queue to leverage GCD for running different recording tasks and managing threads
    let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.rootNode.scale = SCNVector3(0.2, 0.2, 0.2)
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
        
        // Initialize ARVideoKit recorder
        recorder = RecordAR(ARSceneKit: sceneView)
        
        /*-------- ARVideoKit Configuration --------*/
        
        // Set the recorder's delegate
        recorder?.delegate = self

        // Set the renderer's delegate
        recorder?.renderAR = self
        
        // Configure the renderer to perform additional image & video processing 👁
        recorder?.onlyRenderWhileRecording = false
        
        // Configure ARKit content mode. Default is .auto
        recorder?.contentMode = .aspectFill
        
        //record or photo add environment light rendering, Default is false
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
        
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

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        // Present an error message to the user
//
//    }
//
//    func sessionWasInterrupted(_ session: ARSession) {
//        // Inform the user that the session has been interrupted, for example, by presenting an overlay
//
//    }
//
//    func sessionInterruptionEnded(_ session: ARSession) {
//        // Reset tracking and/or remove existing anchors if consistent tracking is required
//
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Hide Status Bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Exported UIAlert present method
    func exportMessage(success: Bool, status: PHAuthorizationStatus) {
        if success {
            let alert = UIAlertController(title: "Exported", message: "Media exported to camera roll successfully!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Awesome", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if status == .denied || status == .restricted || status == .notDetermined {
            let errorView = UIAlertController(title: "😅", message: "Please allow access to the photo library in order to save this media file.", preferredStyle: .alert)
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


//MARK: - Button Action Methods

extension SCNViewController {
    @IBAction func record(_ sender: UIButton) {
        // Record with duration
        if recorder?.status == .readyToRecord {
            // Recording started. Set to Record
            sender.backgroundColor = .red
            stopSquareView.backgroundColor = .systemPink
            
            // Generate circle progress ring
            let loadingView = CircleProgressView(progress: 1, baseColor: .white, progressColor: .red)
            loadingView.bounds = CGRect(x: 0, y: 0, width: 85, height: 85)
            loadingView.center = sender.center
            self.sceneView.insertSubview(loadingView, belowSubview: sender)
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
                            self.circleProgressBtn.layer.borderColor = UIColor.white.cgColor
                            loadingView.removeFromSuperview()
                            self.exportMessage(success: saved, status: status)
                        }
                    }
                }
            }
        } else if recorder?.status == .recording {
            // Recording stopped. Set to readyToRecord
            sender.backgroundColor = .white
            stopSquareView.backgroundColor = .clear
            circleProgressBtn.layer.borderColor = UIColor.white.cgColor
            circleProgressView = nil
            recorder?.stop() { path in
                self.recorder?.export(video: path) { saved, status in
                    DispatchQueue.main.sync {
                        self.exportMessage(success: saved, status: status)
                    }
                }
            }
        }
    }
}


//MARK: - ARVideoKit Delegate Methods

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
