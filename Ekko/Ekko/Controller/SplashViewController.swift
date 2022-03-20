//
//  SplashViewController.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/20/22.
//

import UIKit

class SplashViewController: UIViewController {
    //
    // MARK: - Properties
    //
    var autoDismiss = false
    var label = "hi there"
    
    //
    // MARK: - IBOutlets
    //
    @IBOutlet weak var screenLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
