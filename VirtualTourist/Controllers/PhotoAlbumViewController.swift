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
  
  let regionRadius: CLLocationDistance = 50000
  var selectedAnnotation: MKAnnotation? {
    didSet {
      print("selectedAnnotation: \(selectedAnnotation!.coordinate)")
    }
  }
  var pin: Pin!
  var dataController: DataController!
  var photosToRemove = [Photo]()
  var editingMode: Bool = false
  var photo: Photo!
  
  var fetchedResultsController: NSFetchedResultsController<Photo>!
  //  var numberOfPhotos: Int {
  //    return photos.count
  //  }
  
  var selectedIndexes = [IndexPath]()
  
  // Keep the changes. We will keep track of insertions, deletions, and updates.
  var insertedIndexPaths: [IndexPath]!
  var deletedIndexPaths: [IndexPath]!
  var updatedIndexPaths: [IndexPath]!
  
  
  // MARK: Outlets
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
  @IBOutlet weak var newCollectionButton: UIBarButtonItem!
  
  // MARK: Actions
  
  @IBAction func getNewCollection(_ sender: UIBarButtonItem) {
    deleteAllPhotos()
    collectionView.reloadData()
    getPhotos()
  }
  
  
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
    
    navigationItem.rightBarButtonItem = editButtonItem
    
    // load annotation on map and set region
    mapView.addAnnotation(selectedAnnotation!)
    centerMapOnLocation(annotation: selectedAnnotation!)
    
    // load data using fetch request
    setupFetchResultsController()
    
    //    let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
    //    let predicate = NSPredicate(format: "pin == %@", pin)
    //    fetchRequest.predicate = predicate
    //    fetchRequest.sortDescriptors = []
    
    updateEditButtonState()
    
    // get photos from flickr
    if fetchedResultsController.sections?.count == 0 {
      getPhotos()
    } else {
      newCollectionButton.isEnabled = true
    }
    
    
  }
  
  // MARK: Helper Methods
  
  fileprivate func setupFetchResultsController() {
    let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
    let predicate = NSPredicate(format: "pin == %@", pin)
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = []
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    fetchedResultsController.delegate = self
    
    do {
      try fetchedResultsController.performFetch()
    } catch {
      fatalError("The fetch could not perform: \(error.localizedDescription)")
    }
  }
  
  func centerMapOnLocation(annotation: MKAnnotation) {
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionRadius, regionRadius)
    mapView.setRegion(coordinateRegion, animated: true)
  }
  
  func generateRandomNumber(_ upper: Int, _ lower: Int = 0) -> Int {
    return Int(arc4random_uniform(UInt32(upper - lower + 1))) + lower
  }
  
  // MARK: Get Photos Method
  
  func getPhotos() {
    
    newCollectionButton.isEnabled = false
    
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
        
        for result in photoResults {
          let imageURLString = result[FlickrClient.Photo.MediumURL] as! String
          //self.photos.append(imageURLString)
          self.addPhoto(with: imageURLString)
        }
        
        performUIUpdatesOnMain {
          self.collectionView.reloadData()
          self.newCollectionButton.isEnabled = true
          self.updateEditButtonState()
        }
        
      }
      
    }
  }
  
  func updateEditButtonState() {
    if let sections = fetchedResultsController.sections {
      navigationItem.rightBarButtonItem?.isEnabled = sections[0].numberOfObjects > 0
    }
  }
  
  func addPhoto(with urlString: String) {
    let photo = Photo(context: dataController.viewContext)
    photo.imageURLString = urlString
    photo.pin = pin
    
    let url = URL(string: urlString)
    
    if let data = try? Data(contentsOf: url!) {
      photo.imageData = data
    }
    
    try? dataController.viewContext.save()
  }
  
  func deletePhoto(at indexPath: IndexPath) {
    let photoToDelete = fetchedResultsController.object(at: indexPath)
    dataController.viewContext.delete(photoToDelete)
    try? dataController.viewContext.save()
  }
  
  
  func deleteAllPhotos() {
    for object in self.fetchedResultsController.fetchedObjects! {
      dataController.viewContext.delete(object)
    }
    try? dataController.viewContext.save()
    
    setEditing(false, animated: true)
  }
  
}

// MARK: CollectionView Data Source Methods

extension PhotoAlbumViewController: UICollectionViewDataSource {
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return fetchedResultsController.sections?.count ?? 1
  }
  
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    //return photos.count == 0 ? 30 : numberOfPhotos
    return  fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
    
    configurePhotoCell(cell, cellForItemAt: indexPath)
    
    return cell
  }
  
  // MARK: Configure Cell
  
  func configurePhotoCell(_ cell: PhotoCollectionViewCell, cellForItemAt indexPath: IndexPath) {
    
    if let numberOfPhotos = fetchedResultsController.fetchedObjects?.count, numberOfPhotos < 30 {
      cell.photoImageView.image = nil
      cell.toggleSpinner(true)
      cell.deleteView.isHidden = true
      return
    }
    
    let aPhoto = fetchedResultsController.object(at: indexPath)
    
    performUIUpdatesOnMain {
      cell.photo = aPhoto
      cell.delegate = self
      if self.editingMode {
        cell.deleteView.isHidden = false
      } else {
        cell.deleteView.isHidden = true
      }
      
    }
    
  }
  
}


// MARK: CollectionView Delegate Methods

extension PhotoAlbumViewController: UICollectionViewDelegate {
  
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
  }
  
  
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
      // delete photo from datasource
      //      photos.remove(at: indexPath.item)
      // delete photo from collectionview at the indexpath.
      //      collectionView.deleteItems(at: [indexPath])
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
    
    let numberOfStaticCells = 1
    switch type {
    case .insert:
      let newIndexPathAdjusted = IndexPath(item: (newIndexPath! as NSIndexPath).item + numberOfStaticCells, section: 0)
      insertedIndexPaths.append(newIndexPathAdjusted)
    case .delete:
      let indexPathAdjusted = IndexPath(item: (indexPath! as NSIndexPath).item + numberOfStaticCells, section: 0)
      deletedIndexPaths.append(indexPathAdjusted)
    case .update:
      let indexPathAdjusted = IndexPath(item: (indexPath! as NSIndexPath).item + numberOfStaticCells, section: 0)
      updatedIndexPaths.append(indexPathAdjusted)
    case .move:
      fallthrough
    default:
      break
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    
    self.collectionView.performBatchUpdates(
      { () -> Void in
        
        for indexPath in self.insertedIndexPaths {
          self.collectionView.insertItems(at: [indexPath])
        }
        
        for indexPath in self.deletedIndexPaths {
          self.collectionView.deleteItems(at: [indexPath])
        }
        
        for indexPath in self.updatedIndexPaths {
          self.collectionView.reloadItems(at: [indexPath])
        }
    },
      completion: { (success) in
        if !self.getPhotoDownloadStatus().completed {
          self.downloadAnImage()
        }
    }
    )
    
    let (state, remaining) = getPhotoDownloadStatus()
    enableNewCollectionButton(state, remaining: remaining)
  }
}
