//
//  MainViewController.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/21/22.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {
    @IBOutlet weak var videoView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        playVideo()
    }    

    func playVideo() {
        // Setup the layer
        let playerLayer = AVPlayerLayer(player: DataManager.sharedInstance.player)
        playerLayer.frame = self.view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(playerLayer)
        
        DataManager.sharedInstance.player?.play()
    }
}
