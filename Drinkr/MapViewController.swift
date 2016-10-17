//
//  MapViewController.swift
//  Drinkr
//
//  Created by Dustin Allen on 10/5/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SWRevealViewController
import Firebase
import SDWebImage
import UIActivityIndicator_for_SDWebImage

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource
{
    
    @IBOutlet var menu: UIBarButtonItem!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var drinkrLogo: UILabel!
    @IBOutlet var btnMenu: UIButton!
    
    @IBOutlet weak var cvBars: UICollectionView!
    
    
    
    var ref:FIRDatabaseReference!
    var user: FIRUser!
    var userArry: [UserData] = []
    var filtered:[UserData] = []
    var isRefreshingData = false
    var venueName:String = ""
    
    let geocoder: CLGeocoder = CLGeocoder()
    //var coordinate = CLLocationCoordinate2D()
    var locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var selectedLocation: CLLocation?
    var getCurrentLocation: Bool = true
    
    
    private var currentPage: Int = 1
    private var pageSize: CGSize {
        let layout = self.cvBars.collectionViewLayout as! PDCarouselFlowLayout
        let pageSize = layout.itemSize
//        if layout.scrollDirection == .Horizontal {
//            pageSize.width += layout.minimumLineSpacing
//        } else {
//            pageSize.height += layout.minimumLineSpacing
//        }
        return pageSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        
        self.cvBars.showsHorizontalScrollIndicator = false
        let layout = self.cvBars.collectionViewLayout as! PDCarouselFlowLayout
        //layout.spacingMode = PDCarouselFlowLayoutSpacingMode.overlap(visibleOffset: 100)
        layout.spacingMode = PDCarouselFlowLayoutSpacingMode.fixed(spacing: 20)
        layout.scrollDirection = .Horizontal
        
        refreshData()
        
        // Init menu button action for menu
        if let revealVC = self.revealViewController() {
            self.btnMenu?.addTarget(revealVC, action: #selector(revealVC.revealToggle(_:)), forControlEvents: .TouchUpInside)
//            self.view.addGestureRecognizer(revealVC.panGestureRecognizer());
//            self.navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func menuButton(sender: AnyObject) {
        //performSegueWithIdentifier("sw_rear", sender: sender)
        //self.performSegueWithIdentifier("sw_rear", sender: self)
    }
    
    @IBAction func searchButton(sender: AnyObject) {
        
    }
    
    
    // MARK: -  Get Location
    func locationManagerFunc(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation: CLLocation = locations[locations.count - 1]
        
        print(String(format: "%.6f", lastLocation.coordinate.latitude))
        print(String(format: "%.6f", lastLocation.coordinate.longitude))
        
        animateMap(lastLocation)
        
    }
    
    func animateMap(location: CLLocation) {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 10, 10)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        currentLocation = userLocation
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.05
        let lonDelta: CLLocationDegrees = 0.05
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        self.mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: -  Get Data
    //*
    func refreshData()
    {
        let userID = FIRAuth.auth()?.currentUser?.uid
//        ref.child("venues").observeEventType(FIRDataEventType.Value, withBlock: { snapshot in
//            
//            for childSnap in snapshot.children.allObjects {
//                let snap = childSnap as! FIRDataSnapshot
//                if userID != snap.key {
//                    let approvalStatus = snap.value!["approvalStatus"] as! String!
//                    if approvalStatus == "Approved"
//                    {
//                        self.venueName = snap.value!["venueName"] as! String!
//                        let lat = snap.value!["lat"] as! Double!
//                        let long = snap.value!["long"] as! Double!
//                        let openUntil = snap.value!["venueOpenUntil"] as! String!
//                        let drinkForLike = snap.value!["drinkForLike"] as! String!
//                        let drinkForCheckIn = snap.value!["drinkForCheckIn"] as! String!
//                        
//                        let coordinatePoints = CLLocationCoordinate2DMake(lat, long)
//                        let dropPin = MKPointAnnotation()
//                        dropPin.coordinate = coordinatePoints
//                        dropPin.title = self.venueName
//                        dropPin.subtitle = openUntil
//                        dropPin.subtitle = drinkForLike
//                        dropPin.subtitle = drinkForCheckIn
//                        
//                        self.mapView.addAnnotations([dropPin])
//                    }
//                }
//            }
//        })
        
        // /*
        if isRefreshingData == true {
            return
        }
        
        isRefreshingData = true
        let myGroup = dispatch_group_create()
        
        CommonUtils.sharedUtils.showProgress(self.view, label: "Getting list of bars..")
        
        dispatch_group_enter(myGroup)
        
        ref.child("venues").observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            
                bars.removeAll()
                
                print("\(NSDate().timeIntervalSince1970)")
                //self.tblGroups.reloadData()
                for child in snapshot.children {
                    
                    var placeDict = Dictionary<String,AnyObject>()
                    let childDict = child.valueInExportFormat() as! NSDictionary
                    //print(childDict)
                    
                    let snap = child as! FIRDataSnapshot
                    if userID != snap.key {
                        let approvalStatus = snap.value!["approvalStatus"] as! String!
                        if approvalStatus == "Approved"
                        {
                            self.venueName = snap.value!["venueName"] as! String!
                            let lat = snap.value!["lat"] as! Double!
                            let long = snap.value!["long"] as! Double!
                            let openUntil = snap.value!["venueOpenUntil"] as! String!
                            let drinkForLike = snap.value!["drinkForLike"] as! String!
                            let drinkForCheckIn = snap.value!["drinkForCheckIn"] as! String!
                            
                            let coordinatePoints = CLLocationCoordinate2DMake(lat, long)
                            let dropPin = MKPointAnnotation()
                            dropPin.coordinate = coordinatePoints
                            dropPin.title = self.venueName
                            dropPin.subtitle = openUntil
                            dropPin.subtitle = drinkForLike
                            dropPin.subtitle = drinkForCheckIn
                            
                            self.mapView.addAnnotations([dropPin])
                        }
                    }
                    
                    //let jsonDic = NSJSONSerialization.JSONObjectWithData(childDict, options: NSJSONReadingOptions.MutableContainers, error: &error) as Dictionary<String, AnyObject>;
                    for key : AnyObject in childDict.allKeys {
                        let stringKey = key as! String
                        if let keyValue = childDict.valueForKey(stringKey) as? String {
                            placeDict[stringKey] = keyValue
                        } else if let keyValue = childDict.valueForKey(stringKey) as? Double {
                            placeDict[stringKey] = "\(keyValue)"
                        }
                        else if let keyValue = childDict.valueForKey(stringKey) as? Dictionary<String,AnyObject> {
                            placeDict[stringKey] = keyValue
                        }
                        else if let keyValue = childDict.valueForKey(stringKey) as? NSDictionary {
                            placeDict[stringKey] = keyValue
                        }
                        
                    }
                    placeDict["key"] = child.key
                    
                    bars.append(placeDict)
                    //print(placeDict)
                }
                dispatch_group_leave(myGroup)
            })
        dispatch_group_notify(myGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                // update UI
                CommonUtils.sharedUtils.hideProgress()
                self.isRefreshingData = false
                self.filterData()
                self.ShowFilteredGamePlace()
                print(bars)
            }
        }
        //*/
    }
    
    ///*
    func filterData()
    {
        //Sort Data
        if currentLocation != nil && bars.count > 0 {
            filteredBars = bars.sort({ (bar1:[String : AnyObject], bar2:[String : AnyObject]) -> Bool in
                if let lat1 = (bar1["lat"] as? String)?.toDouble(),
                    long1 = (bar1["long"] as? String)?.toDouble(),
                    lat2 = (bar2["lat"] as? String)?.toDouble(),
                    long2 = (bar2["long"] as? String)?.toDouble()
                {
                    let loc1 = CLLocation(latitude: lat1, longitude: long1)
                    let loc2 = CLLocation(latitude: lat2, longitude: long2)
                    let distanceInMeters1 = currentLocation?.distanceFromLocation(loc1) ?? 0
                    let distanceInMeters2 = currentLocation?.distanceFromLocation(loc2) ?? 0
                    //print((distanceInMeters1 < distanceInMeters2))
                    return (distanceInMeters1 < distanceInMeters2)
                }
                return false
            })
        }
        
        cvBars.reloadData()
    }
    
    func ShowFilteredGamePlace(LatLongDelta:CLLocationDegrees = 0.05)
    {
        mapView.removeAnnotations(mapView.annotations)
        
        for (index, element) in filteredBars.enumerate()
        {
            //print("Item \(index): \(element)")
            let latitude = NSString(string: element["lat"] as? String ?? "0").doubleValue
            let longitude = NSString(string: element["long"] as? String ?? "0").doubleValue
            let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = element["venueName"] as? String ?? ""    //venueAddress
            self.mapView.addAnnotation(annotation)
        }
        
//        let latDelta:CLLocationDegrees = 0.05
//        let lonDelta:CLLocationDegrees = 0.05
//        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
//        let region:MKCoordinateRegion = MKCoordinateRegionMake(CLocation.coordinate, span)
//        self.mapView.setRegion(region, animated: false)
    }
    //*/
    
    // MARK: - Card Collection Delegate & DataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Set Static values 5 here for test purpose
        return filteredBars.count
        //return 10
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(BarNearbyMeCollectionViewCell.identifier, forIndexPath: indexPath) as! BarNearbyMeCollectionViewCell
        
        
        let bar = filteredBars[indexPath.row]
        //print(bar)
        //cell.image.layer.cornerRadius = max(cell.image.frame.size.width, cell.image.frame.size.height) / 2
        //cell.image.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1).CGColor
        
        if let base64String = bar["image"] as? String {
            if let decodedData = NSData(base64EncodedString: base64String, options: NSDataBase64DecodingOptions()) {
                let decodedimage = UIImage(data: decodedData)
                cell.imgBar.image = decodedimage
            }
        }
        
        cell.lblBarTitle.text = bar["venueName"] as? String ?? ""
        cell.lblDealDetail.text = bar["drinkForLike"] as? String ?? ""
        cell.lblTime.text = bar["venueOpenUntil"] as? String ?? ""
        
        
        if let cLocation = currentLocation
        {
            let latitude = NSString(string: bar["lat"] as? String ?? "0").doubleValue
            let longitude = NSString(string: bar["long"] as? String ?? "0").doubleValue
            let loc2 = CLLocation(latitude: latitude, longitude: longitude)
            let distanceInMeters1 = cLocation.distanceFromLocation(loc2) ?? 0
            let km = NSString(format: "%0.2F",(distanceInMeters1/1000))
            cell.lblDistance.text = "\(km) km"   //This is in meter
        }
        
        cell.selectedBackgroundView = nil
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        let bar = filteredBars[indexPath.row]
        let latitude = NSString(string: bar["lat"] as? String ?? "0").doubleValue
        let longitude = NSString(string: bar["long"] as? String ?? "0").doubleValue
        let loc = CLLocation(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        self.mapView.setRegion(region, animated: true)
        //selectedBar = filteredBars[indexPath.row]
    }
    
    func loadUserImageToImageView(imgUser:UIImageView,uid:String) {
        ref.child("users").child(uid).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            if let userProfile = snapshot.value!["userProfile"] as? String {
                let userProfileNSURL = NSURL(string: "\(userProfile)")
                imgUser.setImageWithURL(userProfileNSURL, placeholderImage: UIImage(named: "placeholder"), options: SDWebImageOptions.AllowInvalidSSLCertificates, usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            }
            else if let facebookData = snapshot.value!["facebookData"] as? NSDictionary
                where facebookData["profilePhotoURL"] != nil
            {
                let userProfileNSURL = NSURL(string: "\(facebookData["profilePhotoURL"] as? String ?? "")")
                imgUser.setImageWithURL(userProfileNSURL, placeholderImage: UIImage(named: "placeholder"), options: SDWebImageOptions.AllowInvalidSSLCertificates, usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            }
            else {
                //print("No Profile Picture")
            }
            })
        { (error) in
            print(error.localizedDescription)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        let layout = self.cvBars.collectionViewLayout as! PDCarouselFlowLayout
        let pageSide = (layout.scrollDirection == .Horizontal) ? self.pageSize.width : self.pageSize.height
        let offset = (layout.scrollDirection == .Horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
        
        currentPage = Int(floor((offset - pageSide / 2) / pageSide) + 1)
        print("currentPage = \(currentPage)")
        
//        let bar = filteredBars[currentPage]
//        let lat = Double(bar["lat"] as? String ?? "1") ?? 0
//        let long = Double(bar["long"] as? String ?? "1") ?? 0
//        
//        let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
//        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
//        self.mvLocation.setRegion(region, animated: true)
    }
}
