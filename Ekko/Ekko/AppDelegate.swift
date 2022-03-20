//
//  AppDelegate.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/13/22.
//

import UIKit
import ARVideoKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var launchFromTerminated = false

    // Identifies the recommended orientations for a `UIViewController` that contains AR scenes.
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return ViewAR.orientation
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.launchFromTerminated = true
        
        // Track app launches to trigger app rating alert.
        StoreReviewHelper.incrementAppOpenedCount()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        
        print("Entering background")
//        showSplashScreen(autoDismiss: false, label: "👀")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        print("Did become active")
        if launchFromTerminated {
            showSplashScreen(autoDismiss: false, label: "hi there")
            launchFromTerminated = false
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


extension AppDelegate {
  
    /// Load the SplashViewController from Splash.storyboard
    func showSplashScreen(autoDismiss: Bool, label: String) {
        let storyboard = UIStoryboard(name: "SplashScreen", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "SplashViewController") as! SplashViewController

        // Control the behavior from suspended to launch
        controller.autoDismiss = autoDismiss
        controller.label = label
        controller.modalPresentationStyle = .fullScreen

        // Present the view controller over the top view controller
        let vc = topController()
        vc.present(controller, animated: false, completion: nil)
    }


    /// Determine the top view controller on the screen
    /// - Returns: UIViewController
    func topController(_ parent:UIViewController? = nil) -> UIViewController {
        if let vc = parent {
            if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
                return topController(selected)
            } else if let nav = vc as? UINavigationController, let top = nav.topViewController {
                return topController(top)
            } else if let presented = vc.presentedViewController {
                return topController(presented)
            } else {
                return vc
            }
        } else {
            return topController(UIApplication.shared.keyWindow!.rootViewController!)
        }
    }
}
