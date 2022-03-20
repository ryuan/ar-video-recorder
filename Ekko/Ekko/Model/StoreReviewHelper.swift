//
//  StoreReviewHelper.swift
//  Ekko
//
//  Created by Ruoda Yuan on 3/19/22.
//

import Foundation
import StoreKit

let defaults = UserDefaults.standard

struct StoreReviewHelper {
    /** Set to present review request alert after 3 launches, then based on number of factorials */
    
    static func incrementAppOpenedCount() {
        guard let appOpenCount = defaults.value(forKey: UserDefaults.appOpenedNo) as? Int else {
            defaults.set(1, forKey: UserDefaults.appOpenedNo)
            defaults.set(0, forKey: UserDefaults.reviewRequestNo)
            return
        }
        defaults.set(appOpenCount + 1, forKey: UserDefaults.appOpenedNo)
    }
    
    static func checkAndAskForReview(atController: UIViewController) {
        print("app review alert checked")
        guard let appOpenCount = defaults.value(forKey: UserDefaults.appOpenedNo) as? Int,
            let reviewRequestCount = defaults.value(forKey: UserDefaults.reviewRequestNo) as? Int else {
                return
        }
        
        let nextlevel = 2 * (StoreReviewHelper.factorial(reviewRequestCount + 1))
        print(appOpenCount)
        print(nextlevel)
        if appOpenCount > nextlevel {
            StoreReviewHelper().requestReview(atController: atController)
            defaults.set(reviewRequestCount + 1, forKey: UserDefaults.reviewRequestNo)
            defaults.set(0, forKey: UserDefaults.appOpenedNo)
        }
    }

    fileprivate func requestReview(atController: UIViewController) {
        let alert = UIAlertController(title: "Enjoying Ekko?", message: "Tap a star to rate it on the App Store.", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let play = UIAlertAction(title: "Submit", style: .default, handler: {(alert: UIAlertAction!) in print("Success!")})
        
        alert.addAction(cancel)
        alert.addAction(play)
        
        atController.present(alert, animated: true, completion: nil)
    }
    
    static func factorial(_ number: Int) -> Int {
        if number == 0 {
            return 1
        }
        var sum: Int = 1
        for index in 1...number {
            sum *= index
        }
        return sum
    }
}

extension UserDefaults {
    static let appOpenedNo = "app_openned"
    static let reviewRequestNo = "review_requested"
}
