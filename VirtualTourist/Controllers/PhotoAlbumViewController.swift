//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 12/1/17.
//  Copyright © 2017 Jimit Shah. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
  
  
  // MARK: Properties
  
  let inset: CGFloat = 4.0
  let spacing: CGFloat = 2.0
  let lineSpacing: CGFloat = 4.0
  
  let regionRadius: CLLocationDistance = 5000
  var selectedAnnotation: MKAnnotation? {
    didSet {
      print("selectedAnnotation: \(selectedAnnotation!.coordinate)")
    }
  }
  var pin: Pin!
  var dataController: DataController!
  var photosToRemove = [Photo]()
  var editingMode: Bool = false
  
  var photoFetchedResultsController: NSFetchedResultsController<Photo>!
  
  // Keep track of insertion, deletion, and update paths.
  var insertedIndexPaths = [IndexPath]()
  var deletedIndexPaths = [IndexPath]()
  var updatedIndexPaths = [IndexPath]()
  
  var saveObserverToken: Any?
  var downloadingPhotos: Bool = false {
    didSet {
      newCollectionButton.isEnabled = !downloadingPhotos
    }
  }
  
  // MARK: Outlets
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
  @IBOutlet weak var newCollectionButton: UIBarButtonItem!
  
  // MARK: Actions
  
  @IBAction func getNewCollection(_ sender: UIBarButtonItem) {
    deleteAllPhotos()
    getPhotos()
  }
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
    
    navigationItem.rightBarButtonItem = editButtonItem
    
    // load annotation on map and set region
    centerMapOnLocation(annotation: selectedAnnotation!)
    
    // load data using fetch request
    setupFetchedResultsController()
    updateEditButtonState()
    
    addSaveNotificationObserver()
    
    if photoFetchedResultsController.fetchedObjects?.count == 0 {
      // get photos from flickr
      getPhotos()
    } else {
      newCollectionButton.isEnabled = true
      updateEditButtonState()
    }
    
  }
  
  deinit {
    removeSaveNotificationOberserver()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if photoFetchedResultsController == nil {
      setupFetchedResultsController()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    photoFetchedResultsController = nil
  }
  
  // MARK: Helper Methods
  
  // Setup Fetched Results Controller
  fileprivate func setupFetchedResultsController() {
    let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
    let predicate = NSPredicate(format: "pin == %@", pin)
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = []
    
    photoFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    photoFetchedResultsController.delegate = self
    
    do {
      try photoFetchedResultsController.performFetch()
    } catch {
      fatalError("The fetch could not perform: \(error.localizedDescription)")
    }
    print("fetched objects: \(photoFetchedResultsController.fetchedObjects!.count)")
  }
  
  func centerMapOnLocation(annotation: MKAnnotation) {
    let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionRadius, regionRadius)
    mapView.setRegion(region, animated: true)
    mapView.addAnnotation(annotation)
  }
  
  func generateRandomNumber(_ upper: Int, _ lower: Int = 0) -> Int {
    return Int(arc4random_uniform(UInt32(upper - lower + 1))) + lower
  }
  
  
  // MARK: Get Photos Method
  
  func getPhotos() {
    
    downloadingPhotos = true
    
    var lat: Double!
    var lon: Double!
    
    lat = selectedAnnotation?.coordinate.latitude
    lon = selectedAnnotation?.coordinate.longitude
    
    
    let _ = FlickrClient.sharedInstance().searchByLocation(latitude: lat, longitude: lon) { (results, error) in
      
      guard (error == nil) else {
        print("Error: \(error!)")
        return
      }
      
      let data = results![FlickrClient.JSONResponseKeys.Photos] as! [String: AnyObject]
      let potentialPages = data[FlickrClient.Photos.Pages] as! Int
      
      // Flickr returns at most 4000 images, determine adjusted maximum number of pages.
      let maxPages = FlickrClient.Config.MaxPhotosReturned / FlickrClient.Config.PerPage
      let pages = min(potentialPages, maxPages)
      
      //let randomPage = random(pages, start:1)
      let randomPage = self.generateRandomNumber(pages, 1)
      
      let _ = FlickrClient.sharedInstance().searchByLocation(latitude: lat, longitude: lon, page: randomPage) { (results, error) in
        
        guard (error == nil) else {
          print("Error: \(error!)")
          return
        }
        
        guard let photoResults = results![FlickrClient.JSONResponseKeys.Photos]?[FlickrClient.Photos.Photo] as? [[String:Any]] else {
          print("Cannot find photo list in Photos.")
          return
        }
        
        let backgroundContext: NSManagedObjectContext! = self.dataController.backgroundContext
        let pinID = self.pin.objectID
        
        var rowCount = 0
        
        backgroundContext.perform {
          
          let backgroundPin = backgroundContext.object(with: pinID) as! Pin
          
          for result in photoResults {
            
            let imageURLString = result[FlickrClient.Photo.MediumURL] as! String
            
            let photo = Photo(context: backgroundContext)
            photo.imageURLString = imageURLString
            photo.pin = backgroundPin
            
            rowCount += 1
          }
          
          print("Photos url downloaded: \(rowCount)")
          
          try? backgroundContext.save()
          
          performUIUpdatesOnMain {
            self.downloadingPhotos = false
          }
          
        }
      }
      
    }
    
  }
  
  // MARK: Update edit button state
  func updateEditButtonState() {
    let numberOfObjects = photoFetchedResultsController.fetchedObjects?.count ?? 0
    navigationItem.rightBarButtonItem?.isEnabled = numberOfObjects > 0
  }
  
  
  // MARK: delete photo
  func deletePhoto(at indexPath: IndexPath) {
    let photoToDelete = photoFetchedResultsController.object(at: indexPath)
    dataController.viewContext.delete(photoToDelete)
    try? dataController.viewContext.save()
  }
  
  // MARK: delete all photos from album.
  func deleteAllPhotos() {
    for object in self.photoFetchedResultsController.fetchedObjects! {
      dataController.viewContext.delete(object)
    }
    try? dataController.viewContext.save()
    setEditing(false, animated: true)
  }
  
}

// MARK: CollectionView Data Source Methods

extension PhotoAlbumViewController: UICollectionViewDataSource {
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return photoFetchedResultsController.sections?.count ?? 1
  }
  
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    //return photos.count == 0 ? 30 : numberOfPhotos
    let numberOfPhotos = photoFetchedResultsController.sections?[section].numberOfObjects ?? 30
    return  numberOfPhotos
  }
  
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
    
    cell.photoImageView.image = nil
    cell.toggleSpinner(true)
    cell.deleteView.isHidden = true
    
    configurePhotoCell(cell, cellForItemAt: indexPath)
    
    return cell
  }
  
  // MARK: Configure Cell
  
  func configurePhotoCell(_ cell: PhotoCollectionViewCell, cellForItemAt indexPath: IndexPath) {
    
    
    guard let numberOfPhotos = photoFetchedResultsController.fetchedObjects?.count, numberOfPhotos > 0 else { return }
    
    let aPhoto = photoFetchedResultsController.object(at: indexPath)
    
    if (aPhoto.imageData == nil) {
      let backgroundContext: NSManagedObjectContext! = self.dataController.backgroundContext
      let photoID = aPhoto.objectID
      
      backgroundContext.perform {
        
        let backgroundPhoto = backgroundContext.object(with: photoID) as! Photo
        
        FlickrClient.sharedInstance().downloadImage(imagePath: aPhoto.imageURLString!) { (data, errorString) in
          guard (errorString == nil) else {
            print("Error downloading image: \(errorString!)")
            return
          }
          backgroundPhoto.imageData = data!
          
          performUIUpdatesOnMain {
            self.updatePhotoCell(cell, with: data!)
          }
          
        }
        try? backgroundContext.save()
      }
      
    } else {
      performUIUpdatesOnMain {
        self.updatePhotoCell(cell, with: aPhoto.imageData!)
      }
    }
    
  }
  
  // update photo cell
  fileprivate func updatePhotoCell(_ cell: PhotoCollectionViewCell, with dataImage: Data) {
    cell.photoImage = UIImage(data: dataImage)
    cell.delegate = self
    
    if self.editingMode {
      cell.deleteView.isHidden = false
    } else {
      cell.deleteView.isHidden = true
    }
  }
  
}

// MARK: CollectionView Delegate Methods

extension PhotoAlbumViewController: UICollectionViewDelegate {
  
  // MARK: Delete Items
  
  override func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    newCollectionButton.isEnabled = !editing
    editingMode = editing
    collectionView.reloadData()
  }
  
}


// MARK: - UICollectionViewDelegateFlowLayout

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let columns: CGFloat = collectionView.frame.width > collectionView.frame.height ? 4.0 : 3.0
    
    let dimension = Int((collectionView.frame.width / columns) - (inset + spacing))
    
    return CGSize(width: dimension, height: dimension)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return spacing
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return lineSpacing
  }
  
}

// Mark: - Photo Cell Delgates

extension PhotoAlbumViewController: PhotoCellDelegate {
  
  func delete(cell: PhotoCollectionViewCell) {
    if let indexPath = collectionView.indexPath(for: cell) {
      deletePhoto(at: indexPath)
    }
  }
  
}

// MARK: - Fetch results controller delegate methods

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    insertedIndexPaths = [IndexPath]()
    deletedIndexPaths = [IndexPath]()
    updatedIndexPaths = [IndexPath]()
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    
    switch type {
    case .insert:
      self.insertedIndexPaths.append(newIndexPath!)
      break
    case .delete:
      self.deletedIndexPaths.append(indexPath!)
      break
    case .update:
      self.updatedIndexPaths.append(newIndexPath!)
    default:
      break
    }
    
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    
    let indexSet = IndexSet(integer: sectionIndex)
    switch type {
    case .insert: collectionView.insertSections(indexSet)
    case .delete: collectionView.deleteSections(indexSet)
    case .update, .move:
      fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
    }
  }
  
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    
    // Perform batch updates
    self.collectionView.performBatchUpdates({ () -> Void in
      
      for indexPath in self.insertedIndexPaths {
        self.collectionView.insertItems(at: [indexPath])
      }
      
      for indexPath in self.deletedIndexPaths {
        self.collectionView.deleteItems(at: [indexPath])
      }
      
      for indexPath in self.updatedIndexPaths {
        self.collectionView.reloadItems(at: [indexPath])
      }
    }, completion: { success in
      
      self.updateEditButtonState()
    })
    
  }
}

// MARK: - Save Notification Observer Methods

extension PhotoAlbumViewController {
  func addSaveNotificationObserver() {
    removeSaveNotificationOberserver()
    saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange , object: dataController.viewContext, queue: nil, using: handleSaveNotification(notification:))
  }
  
  func removeSaveNotificationOberserver() {
    if let token = saveObserverToken{
      NotificationCenter.default.removeObserver(token)
    }
  }
  
  func handleSaveNotification(notification: Notification) {
    try? self.dataController.viewContext.save()
  }
}

