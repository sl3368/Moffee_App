/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse


class ViewController: UIViewController, UITextFieldDelegate {

//    var isDriver = true
    
    var signUpMode = true
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    
    @IBOutlet weak var loginButton: UIButton!

    
    // Action for changing the view mode, sign up or log in.
    @IBAction func login(sender: AnyObject) {
        
        if signUpMode == true {
            
            signUpButton.setTitle("Log in", forState: UIControlState.Normal)
            loginButton.setTitle("or Sign up", forState: UIControlState.Normal)
            riderLabel.alpha = 0
            driverLabel.alpha = 0
            `switch`.alpha = 0
            
            signUpMode = false
        } else {
            
            signUpButton.setTitle("Sign up", forState: UIControlState.Normal)
            loginButton.setTitle("or Log in", forState: UIControlState.Normal)
            riderLabel.alpha = 1
            driverLabel.alpha = 1
            `switch`.alpha = 1
            
            signUpMode = true
            
        }
        
    }
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBAction func signUp(sender: AnyObject) {
        
        // Checks if the username or the password are empty
        if username.text == "" || password.text == "" {
            Helpers.displayAlert("There was an error!", message: "Please type an username and a password.", viewController: self)
        } else {
            
            if signUpMode == true {
                
                // Instantiate the new User
                let user = PFUser()
                user["isDriver"] = `switch`.on
                user.username = username.text!
                user.password = password.text!
                
                user.signUpInBackgroundWithBlock({ (success, error) -> Void in
                    
                    if error != nil {
                        Helpers.displayAlert("There was an error!", message: "There was an error on sign up. Please try again later.", viewController: self)
                    } else {
                        
                        if user["isDriver"] as? Bool == true {
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                        } else {
                            self.performSegueWithIdentifier("loginRider", sender: self)
                        }
                    }
                    
                })
                
            } else {
                
                PFUser.logInWithUsernameInBackground(username.text!, password: password.text!, block: { (user, error) -> Void in
                    
                    if let _ = user {
                        if user!["isDriver"] as? Bool == true {
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                        } else {
                            self.performSegueWithIdentifier("loginRider", sender: self)
                        }
                    } else {
                        Helpers.displayAlert("There was an error!", message: "Please, are you sure this is the right username and password?", viewController: self)
                    }
                    
                })
                
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        // Add gesture for closing keyboard when tapped outside the keyboard area.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        username.delegate = self
        password.delegate = self
    }
    
    // Action for closing the keyboard when tapped
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if PFUser.currentUser()?.username != nil {
            if PFUser.currentUser()?["isDriver"] as? Bool == true {
                performSegueWithIdentifier("loginDriver", sender: self)
            } else {
                performSegueWithIdentifier("loginRider", sender: self)
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Close keyboard when
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
