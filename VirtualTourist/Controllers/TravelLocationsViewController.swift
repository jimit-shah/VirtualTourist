//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 12/1/17.
//  Copyright © 2017 Jimit Shah. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// MARK: - TravelLocationsViewController: UIViewController

class TravelLocationsViewController: UIViewController {
  
  // MARK: Properties
  
  //var annotations = [MKPointAnnotation]()
  
  var pins = [Pin]()
  
  var feedbackGenerator: UIImpactFeedbackGenerator? = nil
  
  var dataController: DataController!
  
  var editingPins: Bool = false
  
  // MARK: Outlets
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var editButton: UIBarButtonItem!
  @IBOutlet weak var alertView: UIView!
  @IBOutlet weak var alertViewHeightConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var messageLabel: UILabel!
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
  
  @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
    editingPins = !editingPins
    alertViewHeightConstraint.constant = editingPins ? 50 : 0
    messageLabel.isHidden = !editingPins
    sender.title = editingPins ? "Done": "Edit"
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
    
    let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
    fetchRequest.sortDescriptors = []
    
    if let result = try? dataController.viewContext.fetch(fetchRequest) {
      pins = result
      
      for pin in pins {
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude as! CLLocationDegrees, longitude: pin.longitude as! CLLocationDegrees)
        annotation.coordinate = coordinate
        //annotations.append(annotation)
        mapView.addAnnotation(annotation)
      }
      
    }
    
    configureUI()
  }
  
  
  
  // MARK: Helper Methods
  func configureUI() {
    alertViewHeightConstraint.constant = 0
  }
  
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
  
  // MARK: Method to add Pin
  func addPin(at touchPoint: CGPoint) {
    
    let mapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    
    // save coordinates to data controller
    
    let pin = Pin(context: dataController.viewContext)
    pin.latitude = mapCoordinate.latitude as NSNumber
    pin.longitude = mapCoordinate.longitude as NSNumber
    
    try? dataController.viewContext.save()
    pins.insert(pin, at: 0)
    
    // add pin to mapView
    
    let annotation = MKPointAnnotation()
    annotation.coordinate = mapCoordinate
    mapView.addAnnotation(annotation)
    
    // generate heptic feedback
    feedbackGenerator?.impactOccurred()
  }
  
  
  func removePin(with annotation: MKAnnotation) {
    
    // remove selected pin
    mapView.removeAnnotation(annotation)
    
    let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
    
    let lat = annotation.coordinate.latitude as NSNumber
    let lon = annotation.coordinate.longitude as NSNumber
    
    fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lat, lon)
    if let result = try? dataController.viewContext.fetch(fetchRequest) {
      
      for managedObject in result
      {
        let managedObjectData = managedObject as NSManagedObject
        dataController.viewContext.delete(managedObjectData)
      }
    }
    
    // save context
    try? dataController.viewContext.save()
    
  }
  
}

// MARK: - TravelLocationsViewController: MKMapViewDelegate

extension TravelLocationsViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    
    saveMapViewRegion(mapView.region)
    
  }
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    
    view.setSelected(true, animated: true)
    
    guard !editingPins
      else {
        removePin(with: view.annotation!)
        return
    }
    
    let vc = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumVC") as! PhotoAlbumViewController
    print("passing annotation: \(view.annotation!.coordinate)")
    vc.selectedAnnotation = view.annotation
    
    navigationController!.pushViewController(vc, animated: true)
    
    // deselect annotation
    mapView.deselectAnnotation(view.annotation, animated: true)
    
  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    var annotationView: MKAnnotationView
    
    if #available(iOS 11.0, *) {
      annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
    } else {
      annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
    }
    
    annotationView.isDraggable = true
    //annotationView.canShowCallout = true
    return annotationView
    
  }
  
}


