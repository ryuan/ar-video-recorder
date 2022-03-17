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
    @IBOutlet weak var closeBtn: UIButton!
    
    var recorder: RecordAR?
    var circleProgressView: CircleProgressView?
    var currentOption: Int?
    
    // Prepare dispatch queue to leverage GCD for running multithreaded operations
    let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    let snappingQueue = DispatchQueue(label: "snappingThread", attributes: .concurrent)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.rootNode.scale = SCNVector3(0.2, 0.2, 0.5)
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
        
        // Initialize ARVideoKit recorder
        recorder = RecordAR(ARSceneKit: sceneView)
        
        /*-------- ARVideoKit Configuration --------*/
        
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
    // REMINDER TO SELF: METHOD MUST BE CALLED IN MAIN THREAD OR APP WILL CRASH
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