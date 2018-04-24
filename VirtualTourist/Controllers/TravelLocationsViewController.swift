//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 12/1/17.
//  Copyright © 2017 Jimit Shah. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController {

  // MARK: Properties
  var annotations = [MKPointAnnotation]()
  
  
  // MARK: Outlets
  
  @IBOutlet weak var mapView: MKMapView!
  
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // load region from user defaults.
    let savedRegion = UserDefaults.standard.object(forKey: AppDelegate.UserDefaultKeys.MapViewRegion) as! [String: Any]
    
    let region = MKCoordinateRegion(
      center: CLLocationCoordinate2DMake(
        savedRegion["latitude"] as! Double,
        savedRegion["longitude"] as! Double
      ),
      span: MKCoordinateSpan(
        latitudeDelta: savedRegion["latitudeDelta"] as! Double,
        longitudeDelta: savedRegion["longitudeDelta"] as! Double
      )
    )
    
    mapView.setRegion(region, animated: false)
    mapView.setCenter(region.center, animated: true)
    mapView.delegate = self
    
  }

  
  // MARK: Helper Methods
  
  let regionRadius: CLLocationDistance = 1000
  func centerMapOnLocation(location: CLLocation) {
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
    mapView.setRegion(coordinateRegion, animated: true)
  }
  
  func saveMapViewRegion(_ region: MKCoordinateRegion) {
    UserDefaults.standard.set([
      "latitude": region.center.latitude,
      "longitude": region.center.longitude,
      "latitudeDelta": region.span.latitudeDelta,
      "longitudeDelta": region.span.longitudeDelta
      ], forKey: AppDelegate.UserDefaultKeys.MapViewRegion)
  }
}

// MARK: - TravelLocationsViewController: MKMapViewDelegate

extension TravelLocationsViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    saveMapViewRegion(mapView.region)
    
  }
}

