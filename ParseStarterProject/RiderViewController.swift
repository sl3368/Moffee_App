//
//  RiderViewController.swift
//  Moffee


import UIKit
import MapKit
import CoreLocation
import Parse

class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var callUberButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblStatus: UILabel!
    
    var locationManager: CLLocationManager!
    
    var latitude: CLLocationDegrees! = 0 , longitude: CLLocationDegrees! = 0
    
    var uberRequested = false
    var driverOnTheWay = false
    var lastLocation: CLLocation!;
    var userLocation: CLLocation?;
    var currentDriver: String!;
    var riderRequest: PFObject!;
    var coffeeshop: PFObject!;
    
    let userAnnotationTitle = "You are here";
    let driverAnnotationTitle = "Your Coffee is Here"
    let strRequestMoffee = "Request Moffee";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Starts getting the location
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.delegate = self
        mapView.showsUserLocation = true;
        
    }
    
    @IBAction func callUber(sender: AnyObject) {
        if uberRequested == false {

            if self.mapView.selectedAnnotations.count == 0 {
                print("Please select a coffee shop")
                Helpers.displayAlert("Operation cannot be performed", message: "Please select a coffee shop", viewController: self)
                return
            }
            
            let ann = self.mapView.selectedAnnotations[0]
            print ("\(ann.title!)")
            
            
            riderRequest = PFObject(className: "RiderRequest")
            riderRequest["username"] = PFUser.currentUser()!.username
            riderRequest["location"] = PFGeoPoint(latitude: latitude, longitude: longitude)
            riderRequest["coffeeshopname"] = ann.title!
            riderRequest["coffeeshopid"] = ann.subtitle!
            
            coffeeshop = PFObject(className: "CoffeeShop")
            coffeeshop["name"] = ann.title!
            coffeeshop["id"] = ann.subtitle!
            coffeeshop["location"] = PFGeoPoint(latitude: ann.coordinate.latitude, longitude: ann.coordinate.longitude)
        
            // make sure it's public so that drivers can accept request
            let acl = PFACL()
            acl.setPublicReadAccess(true)
            acl.setPublicWriteAccess(true)
            riderRequest.ACL = acl
            coffeeshop.ACL = acl
            
            coffeeshop.saveInBackgroundWithBlock { (success, error) -> Void in
                if success {
                    print("saved coffee shop");
                } else {
                    Helpers.displayAlert("Error adding coffee shop.", message: "cannot add coffee shop", viewController: self)
                }
            }
            
            // save
            riderRequest.saveInBackgroundWithBlock { (success, error) -> Void in
                if success {
                    self.callUberButton.setTitle("Cancel Moffee", forState: UIControlState.Normal)
                    self.lblStatus.text = "Waiting for mofers..."
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    self.uberRequested = true
                } else {
                    Helpers.displayAlert("There was an error while saving request.", message: "There was an error on requesting coffee, please try again.", viewController: self)
                }
            }
        } else {
            
            if driverOnTheWay == false {
                // cancel moffee request
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
                
                query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                    
                    if error == nil {
                        print("Succesfully retrieved \(objects?.count) objects.")
                        
                        if let objects = objects {
                            for object in objects {
                                object.deleteInBackground()
                            }
                            self.callUberButton.setTitle(self.strRequestMoffee, forState: UIControlState.Normal)
                            self.uberRequested = false
                            self.lblStatus.text = ""
                        }
                    }
                    
                })
            } else {
                
                // Got his coffee! Save fulfilled request
                let CoffeeDelivered = PFObject(className: "CoffeeDelivered")
                CoffeeDelivered["username"] = riderRequest["username"]
                CoffeeDelivered["mofer"] = currentDriver
                CoffeeDelivered["location"] = riderRequest["location"]
                CoffeeDelivered["coffeeshopname"] = riderRequest["coffeeshopname"]
                CoffeeDelivered["coffeeshopid"] = riderRequest["coffeeshopid"]
                

                // make sure it's public so that drivers can accept request
                let acl = PFACL()
                acl.setPublicReadAccess(true)
                acl.setPublicWriteAccess(true)
                CoffeeDelivered.ACL = acl
                print("saving to coffee delivered obj")
                print("\(CoffeeDelivered)")
                
                // save
                CoffeeDelivered.saveInBackgroundWithBlock { (success, error) -> Void in
                    if success {
                        self.callUberButton.setTitle(self.strRequestMoffee, forState: UIControlState.Normal)
                        self.lblStatus.text = ""
                        self.uberRequested = false
                        self.driverOnTheWay = false
                        
                        self.riderRequest.deleteEventually()
                        
                        self.userLocation = nil;
                        self.mapView.removeAnnotations(self.mapView.annotations)
                        
                    } else {
                        Helpers.displayAlert("There was an error while issuing bill.", message: "There was an error while saving bill, please try again.", viewController: self)
                    }
                }
                
                
                
            }
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if manager.location?.coordinate != nil {
            
            let userlocation: CLLocationCoordinate2D = (manager.location?.coordinate)!
            latitude = userlocation.latitude
            longitude = userlocation.longitude
            
            if let currentUserUsername = PFUser.currentUser()?.username {
                let query = PFQuery(className: "RiderRequest")
                query.whereKey("username", equalTo: currentUserUsername)
                query.findObjectsInBackgroundWithBlock({ (requests, error) -> Void in
                    
                    if error != nil {
                        return
                    }
                    
                    if let requests = requests {
                        
                        for request in requests {
                            if let driverUsername = request["driverResponded"] {
                                self.currentDriver = driverUsername as! String;
                                
                                let query = PFQuery(className: "DriverLocation")
                                query.whereKey("username", equalTo: driverUsername)
                                query.findObjectsInBackgroundWithBlock({ (driverLocations, error) -> Void in
                                    
                                    if error != nil {
                                        return
                                    }
                                    
                                    if let driverLocations = driverLocations {
                                        for driverLocation in driverLocations {
                                            if let driverLocation = driverLocation["driverLocation"] as? PFGeoPoint {
                                                
                                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                let userCLLocation = CLLocation(latitude: userlocation.latitude, longitude: userlocation.longitude)
                                                self.updateDriverLocation(driverCLLocation, userLocation: userCLLocation)
                                            }
                                        }
                                    }
                                    
                                })
                            }
                        }
                    }
                })
            }
            
            if driverOnTheWay == false && self.userLocation == nil {
                
                let center = CLLocationCoordinate2D(latitude: userlocation.latitude, longitude: userlocation.longitude)
                self.userLocation = CLLocation(latitude: userlocation.latitude, longitude: userlocation.longitude);
                print("Latitude \(userlocation.latitude) and Longitude \(userlocation.longitude)")

                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                self.mapView.setRegion(region, animated: true)
                print("region set");
                
                self.mapView.removeAnnotations(mapView.annotations)
            }
        }
    }
    
    func updateDriverLocation(driverLocation:CLLocation, userLocation:CLLocation) {
        
        let distanceMeters = userLocation.distanceFromLocation(driverLocation)
        let distanceKM = distanceMeters / 1000
        let roudedTwoDigitsDistance = Double(round(distanceKM * 100) / 100)
        
        self.callUberButton.setTitle("Got my coffee, Thanks!" , forState: UIControlState.Normal)
        self.lblStatus.text = "Driver is \(roudedTwoDigitsDistance) km away."
        
        self.driverOnTheWay = true
        
        let latDiff = driverLocation.coordinate.latitude - userLocation.coordinate.latitude;
        let lonDiff = driverLocation.coordinate.longitude - userLocation.coordinate.longitude;
        
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude + (latDiff)*0.5, longitude: userLocation.coordinate.longitude + (lonDiff)*0.5)
        
        let latDelta = (abs(latDiff) + 0.01)
        let longDelta = (abs(lonDiff) + 0.01)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta))
        
        self.mapView.setRegion(region, animated: true)
        
        // remove annotations
//        self.mapView.removeAnnotations(self.mapView.annotations)
        
        var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude)
        
        // add coffee shop pin
        var objectAnnotation = MKPointAnnotation()
        if self.coffeeshop != nil {
            if let clocation = self.coffeeshop["location"] as? PFGeoPoint {
                objectAnnotation.coordinate = CLLocationCoordinate2D(latitude: clocation.latitude, longitude: clocation.latitude)
            }
            objectAnnotation.title = self.coffeeshop["name"] as? String
            objectAnnotation.subtitle = self.coffeeshop["id"] as? String
            
            self.mapView.addAnnotation(objectAnnotation)
            self.mapView.selectAnnotation(objectAnnotation, animated: false)
        }
        
        // add the driver icon
        pinLocation = CLLocationCoordinate2DMake(driverLocation.coordinate.latitude, driverLocation.coordinate.longitude)
        objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = pinLocation
        objectAnnotation.title = self.driverAnnotationTitle
        self.mapView.addAnnotation(objectAnnotation)
    }
    
    func fetchCafesAroundLocation(center:CLLocation){
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations( annotationsToRemove );
        
        // add nearby coffee places
        print("fetching nearby coffee places...")
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = "Coffee"
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.startWithCompletionHandler ({(response, error) -> Void in
            
            if error != nil {
                print("Error occured in search: \(error!.localizedDescription)")
            } else if response!.mapItems.count == 0 {
//                print("No matches found")
            } else {
//                print("Matches found")
                
                for item in response!.mapItems {
                    if item.phoneNumber != nil {
//                        print("Name = \(item.name)")
//                        print("Phone = \(item.phoneNumber)")
                        
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = item.placemark.coordinate
                        annotation.title    = item.name
                        annotation.subtitle = item.phoneNumber
                        self.mapView.addAnnotation(annotation)
                    }
                }
            }
        })

        
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool){
//        print("region did change");
        if driverOnTheWay == true {
            return
        }
        
        let centre = mapView.centerCoordinate as CLLocationCoordinate2D
        
        let getLat: CLLocationDegrees = centre.latitude
        let getLon: CLLocationDegrees = centre.longitude
        print("Latitude \(getLat) and Longitude \(getLon)")
       
        
        let getMovedMapCenter: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
        
        if self.lastLocation != nil {
            let distanceMapMoved = self.lastLocation.distanceFromLocation(getMovedMapCenter)
            print("moved this much: \(distanceMapMoved)")
            if distanceMapMoved < 80 {
                return
            }
        }
        self.lastLocation = getMovedMapCenter
        
        let deltaLatitude = self.mapView.region.span.latitudeDelta;
        let deltaLongitude = self.mapView.region.span.longitudeDelta;
        let regionSize = deltaLatitude * deltaLongitude;
        
        if (regionSize < 0.003) {
            self.fetchCafesAroundLocation(getMovedMapCenter)
        } else if (regionSize > 1) {
            // reset region size, we do not allow
            if (self.userLocation != nil) {
                let lat = self.userLocation!.coordinate.latitude;
                let lon = self.userLocation!.coordinate.longitude;
                let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                 print("WARN: Latitude \(lat) and Longitude \(lon)")
                
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                self.mapView.setRegion(region, animated: true)
                print("region set");

            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "logOutRider" {
            PFUser.logOut()
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        print("creating annotation views")
        if annotation.isEqual(mapView.userLocation) {
            return nil;
        }
        
        let pinView:MKPinAnnotationView = MKPinAnnotationView()
        pinView.annotation = annotation
        if (annotation.title! == userAnnotationTitle) {
            pinView.pinTintColor = UIColor.blueColor()
            pinView.animatesDrop = false
        } else if (annotation.title! == driverAnnotationTitle) {
            
            let reuseId = "driver"
            
            var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            if anView == nil {
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                anView!.image = UIImage(named:"coffeethumb")
                anView!.canShowCallout = true
            }
            else {
                //we are re-using a view, update its annotation reference...
                anView!.annotation = annotation
            }
            
            return anView
        } else {
            pinView.pinTintColor = UIColor.redColor()
            pinView.animatesDrop = false
        }
        
        pinView.canShowCallout = true
        
        return pinView

    }
    
    
}
