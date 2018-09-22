//
//  ViewController.swift
//  AmbulanceTracker
//
//  Created by medhat on 1/11/18.
//  Copyright © 2018 Medhatm3bd. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var lbl_rider: UILabel!
    @IBOutlet weak var lbl_driver: UILabel!
    @IBOutlet weak var txtField_email: UITextField!
    @IBOutlet weak var txtField_password: UITextField!
    @IBOutlet weak var switch_riderDriver: UISwitch!
    @IBOutlet weak var btnOutlet_signUp: UIButton!
    @IBOutlet weak var btnOutlet_logIn: UIButton!
    
    var signUpMode = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func btn_sign(_ sender: Any) {
        if (txtField_email.text == "" || txtField_password.text == "") {
            displayAlert(title: "Missing Information", message: "You must provide both a email and password")
        } else {
            if let email = txtField_email.text, let password = txtField_password.text {
                if signUpMode {
                    //SIGN UP
                    Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                        if (error != nil) {
                            self.displayAlert(title: "Error", message: (error?.localizedDescription)!)
                        } else {
                            if self.switch_riderDriver.isOn {
                                //DRIVER
                                let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                req?.displayName = "Driver"
                                req?.commitChanges(completion: nil)
                                self.performSegue(withIdentifier: "driverSegue", sender: nil)
                            } else {
                                //RIDER
                                let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                req?.displayName = "Rider"
                                req?.commitChanges(completion: nil)
                                self.performSegue(withIdentifier: "riderSegue", sender: nil)
                                print("Sign Up Success")
                            }
                        }
                    })
                } else {
                    // LOG IN
                    Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                        if (error != nil) {
                            self.displayAlert(title: "Error", message: (error?.localizedDescription)!)
                        } else {
                            if user?.displayName == "Driver" {
                                //DRIVER
                                print("driver")
                                self.performSegue(withIdentifier: "driverSegue", sender: nil)
                            } else {
                                //RIDER
                                print("Log In Success")
                                self.performSegue(withIdentifier: "riderSegue", sender: nil)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func  displayAlert(title: String, message: String)  {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func btn_logIn(_ sender: Any) {
        if signUpMode {
            btnOutlet_signUp.setTitle("Log In", for: .normal)
            btnOutlet_logIn.setTitle("Switch to Sign Up", for: .normal)
            switch_riderDriver.isHidden = true
            lbl_rider.isHidden = true
            lbl_driver.isHidden = true
            signUpMode = false
        } else {
            btnOutlet_signUp.setTitle("Sign Up", for: .normal)
            btnOutlet_logIn.setTitle("Switch to Log In", for: .normal)
            switch_riderDriver.isHidden = false
            lbl_driver.isHidden = false
            lbl_rider.isHidden = false
            signUpMode = true
        }
    }
}

