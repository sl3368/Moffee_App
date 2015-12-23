//
//  Helpers.swift
//  Moffee
//

import UIKit

class Helpers {
    
    // Function for displaying default alerts
    static func displayAlert(title: String!, message: String!, viewController: UIViewController!) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.Default, handler: nil))
        viewController.presentViewController(alert, animated: true, completion: nil)
        
    }
    
}