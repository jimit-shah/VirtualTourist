//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 12/1/17.
//  Copyright © 2017 Jimit Shah. All rights reserved.
//

import UIKit
import MapKit

// MARK: - TravelLocationsViewController: UIViewController

class TravelLocationsViewController: UIViewController {
  
  // MARK: Properties
  
  var annotations = [MKPointAnnotation]()

  var feedbackGenerator: UIImpactFeedbackGenerator? = nil
  
  
  // MARK: Outlets
  
  @IBOutlet weak var mapView: MKMapView!
  
  
  // MARK: Actions
  
  @IBAction func handleLongPress(_ sender: UILongPressGestureRecognizer) {
    
    switch sender.state {
    case .began:
      
      // Instantiate a feedback generator.
      feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
      
      // Prepare the generator when the gesture begins.
      feedbackGenerator?.prepare()
      
      addPin(at: sender.location(in: mapView))
      
      // refactor to setup pin and draggable
      break
    case .changed:
      // have pin track user touch location
      break
    case .ended:
      // drop pin at last touchpoint
      break
    default:
      break
    }
    
  }
  
  
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
  
  
  func addPin(at touchPoint: CGPoint) {
    
    let mapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    let annotation = MKPointAnnotation()
    annotation.coordinate = mapCoordinate
    
    mapView.addAnnotation(annotation)
    mapView.selectAnnotation(annotation, animated: true)
    
    // generate heptic feedback
    feedbackGenerator?.impactOccurred()
  }
  
}

// MARK: - TravelLocationsViewController: MKMapViewDelegate

extension TravelLocationsViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
  
    saveMapViewRegion(mapView.region)
  
  }
}

