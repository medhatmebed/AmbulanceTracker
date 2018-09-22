//
//  PatientViewController.swift
//  AmbulanceTracker
//
//  Created by medhat on 1/11/18.
//  Copyright © 2018 Medhatm3bd. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

class PatientViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var map_rider: MKMapView!
    @IBOutlet weak var btnOutlet_callAmbulance: UIButton!
    
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var uberHasBeenCalled = false
    var driverOnTheWay = false
    var driverLocation = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest 
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let email = Auth.auth().currentUser?.email {
            Database.database().reference().child("RideRequest").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                self.uberHasBeenCalled = true
                self.btnOutlet_callAmbulance.setTitle("Cancel Uber", for: .normal)
                Database.database().reference().child("RideRequest").removeAllObservers()
                
                if let rideRequestDictionary = snapshot.value as? [String: AnyObject] {
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.displayDriverAndRider()
                            
                            if let email = Auth.auth().currentUser?.email { Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged, with: { (snapshot) in
                                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                            self.driverOnTheWay = true
                                            self.displayDriverAndRider()
                                        }
                                    }
                                }
                            })
                            }
                        }
                    }
                }
            })
        }
    }
    
    func displayDriverAndRider() {
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        btnOutlet_callAmbulance.setTitle("Your Driver is \(roundedDistance)km away!", for: .normal)
        map_rider.removeAnnotations(map_rider.annotations)
        
        let latDelta = abs(driverLocation.latitude - userLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - userLocation.longitude) * 2 + 0.005
        
         let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map_rider.setRegion(region, animated: true)
        
        let riderAnno = MKPointAnnotation()
        riderAnno.coordinate = userLocation
        riderAnno.title = "Your Location"
        map_rider.addAnnotation(riderAnno)
        
        let driverAnno = MKPointAnnotation()
        driverAnno.coordinate = driverLocation
        driverAnno.title = "Your Driver"
        map_rider.addAnnotation(driverAnno)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            userLocation = center
            
            if uberHasBeenCalled {
                displayDriverAndRider()
            } else {
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                map_rider.setRegion(region, animated: true)
                map_rider.removeAnnotations(map_rider.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "Your Location"
                map_rider.addAnnotation(annotation)
            }
        }
    }
    
    @IBAction func btn_logOut(_ sender: Any) {
        try? Auth.auth().signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btn_callAnUber(_ sender: Any) {
        if !driverOnTheWay {
            if let email = Auth.auth().currentUser?.email {
                if uberHasBeenCalled {
                    uberHasBeenCalled = false
                    btnOutlet_callAmbulance.setTitle("Call an Uber", for: .normal)
                    Database.database().reference().child("RideRequest").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                        snapshot.ref.removeValue()
                        Database.database().reference().child("RideRequest").removeAllObservers()
                })
            } else {
                let rideRequestDictionary : [String:Any] = ["email" : email, "lat" : userLocation.latitude, "lon" : userLocation.longitude]
                Database.database().reference().child("RideRequest").childByAutoId().setValue(rideRequestDictionary)
                uberHasBeenCalled = true
                btnOutlet_callAmbulance.setTitle("Cancel Uber", for: .normal)
                }
            }
        }
    }
}
