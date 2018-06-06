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
  
  var feedbackGenerator: UIImpactFeedbackGenerator? = nil
  
  var dataController: DataController!
  
  var editingPins: Bool = false
  
  var fetchedResultsController: NSFetchedResultsController<Pin>!
  
  
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
  
  fileprivate func setupFetchResultsController() {
    let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
    fetchRequest.sortDescriptors = []
    
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "Pins")
    fetchedResultsController.delegate = self
    
    do {
      try fetchedResultsController.performFetch()
    } catch {
      fatalError("The fetch could not perform: \(error.localizedDescription)")
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureUI()
    
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
    
    setupFetchResultsController()
    
    updateMapAnnotations()
  }
  
  
  // MARK: Helper Methods
  func configureUI() {
    alertViewHeightConstraint.constant = 0
  }
  
  let regionRadius: CLLocationDistance = 1000
  func centerMapOnLocation(location: CLLocation) {
    let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
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
    
    // add to map view
    let annotation = MKPointAnnotation()
    annotation.coordinate = mapCoordinate
    mapView.addAnnotation(annotation)
    
    feedbackGenerator?.impactOccurred()
  }
  
  func updateMapAnnotations() {
    let pins = fetchedResultsController.fetchedObjects!
    var annotations = [MKAnnotation]()
    
    for pin in pins {
      let annotation = MKPointAnnotation()
      let coordinate = CLLocationCoordinate2D(latitude: pin.latitude as! CLLocationDegrees, longitude: pin.longitude as! CLLocationDegrees)
      annotation.coordinate = coordinate
      annotations.append(annotation)
    }
    
    self.mapView.removeAnnotations(self.mapView.annotations)
    self.mapView.addAnnotations(annotations)
  }
  
  func fetchPin(with annotation: MKAnnotation) -> Pin? {
    let lat = annotation.coordinate.latitude as NSNumber
    let lon = annotation.coordinate.longitude as NSNumber
    var pin = Pin()
    
    if let pins = fetchedResultsController.fetchedObjects {
      for object in pins {
        if object.latitude == lat && object.longitude == lon {
          print("pin found")
          pin = object
        }
      }
    }
    print("Pin Tapped: ----- \(pin.latitude!) \(pin.longitude!)")
    return pin
    
  }
  
  func removePin(with annotation: MKAnnotation) {
    
    // remove selected pin from mapView
    mapView.removeAnnotation(annotation)

    // remove pin from context
    if let pin = fetchPin(with: annotation) {
      dataController.viewContext.delete(pin)
    }
    
  }
  
}

// MARK: - TravelLocationsViewController: MKMapViewDelegate

extension TravelLocationsViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    
    saveMapViewRegion(mapView.region)
    
  }
  
  // mapview did select view
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

    view.setSelected(true, animated: true)

    if editingPins {
      removePin(with: view.annotation!)
      return
    }
    
    let vc = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumVC") as! PhotoAlbumViewController
    print("passing annotation: \(view.annotation!.coordinate)")
    vc.selectedAnnotation = view.annotation
    vc.dataController = dataController
    
    if let pin = fetchPin(with: view.annotation!) {
      vc.pin = pin
    }
    navigationController!.pushViewController(vc, animated: true)
    
    // deselect annotation
    mapView.deselectAnnotation(view.annotation, animated: true)
    
  }
  
  // mapview view for annotation
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    var annotationView: MKAnnotationView
    
    if #available(iOS 11.0, *) {
      annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
    } else {
      annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
    }
    
    annotationView.isDraggable = true
    return annotationView
    
  }
  
}

// MARK: Fetch resutls controller delegate methods

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {
  
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updateMapAnnotations()
  }
}

