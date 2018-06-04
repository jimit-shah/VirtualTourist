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
  
  var photos = [Photo]()
  let regionRadius: CLLocationDistance = 10000
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
  
  var numberOfPhotos: Int {
    return photos.count
  }

  // MARK: Outlets
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
  @IBOutlet weak var newCollectionButton: UIBarButtonItem!
  
  // MARK: Actions
  
  @IBAction func getNewCollection(_ sender: UIBarButtonItem) {
    photos.removeAll()
    deleteAllPhotos()
    collectionView.reloadData()
    getPhotos()
  }
  
  
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
    
    // load annotation on map and set region
    mapView.addAnnotation(selectedAnnotation!)
    centerMapOnLocation(annotation: selectedAnnotation!)
    
    // load data using fetch request
    let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
    let predicate = NSPredicate(format: "pin == %@", pin)
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = []
    
    if let result = try? dataController.viewContext.fetch(fetchRequest) {
      photos = result
    }
    
    // get photos from flickr
    if photos.count == 0 {
      getPhotos()
    } else {
      newCollectionButton.isEnabled = true
    }
    
    navigationItem.rightBarButtonItem = editButtonItem
  }
  
  // MARK: Helper Methods
  
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
//          let insertedIndexPath = IndexPath(item: self.photos.count, section: 0)
//          self.collectionView.insertItems(at: [insertedIndexPath])
          self.newCollectionButton.isEnabled = true
        }
        
      }
      
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
    self.photos.insert(photo, at: 0)
    updateEditButtonState()
  }
  
  func deletePhoto(at indexPath: IndexPath) {
    //let photoToDelete = fetchedResultsController.object(at: indexPath)
    let photoToDelete = photos[indexPath.item]
    dataController.viewContext.delete(photoToDelete)
    try? dataController.viewContext.save()
    
    photos.remove(at: indexPath.item)
    // delete photo from collectionview at the indexpath.
    collectionView.deleteItems(at: [indexPath])
    
    updateEditButtonState()
  }
  
  
  func deleteAllPhotos() {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
    let predicate = NSPredicate(format: "pin == %@", pin)
    fetchRequest.predicate = predicate
    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    do {
      let batchDeleteResult = try dataController.viewContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
      print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
    } catch {
      let updateError = error as NSError
      print("\(updateError), \(updateError.userInfo)")
    }
    
    updateEditButtonState()
  }
  
  func updateEditButtonState() {
    navigationItem.rightBarButtonItem?.isEnabled = photos.count > 0
  }
}

// MARK: CollectionView Data Source Methods

extension PhotoAlbumViewController: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count == 0 ? 30 : numberOfPhotos
  }
  
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
    
    configurePhotoCell(cell, cellForItemAt: indexPath)
    
    return cell
  }
  
  // MARK: Configure Cell
  
  func configurePhotoCell(_ cell: PhotoCollectionViewCell, cellForItemAt indexPath: IndexPath) {
    
    
    
    if photos.count < 30 {
      cell.photoImageView.image = nil
      cell.toggleSpinner(true)
      cell.deleteView.isHidden = true
      return
    }
    
    
    let photo = photos[indexPath.item]
    
    performUIUpdatesOnMain {
      cell.photo = photo
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
    //collectionView.deselectItem(at: indexPath, animated: true)
    
    //    collectionView.cellForItemAtIndexPath(indexPath)?.backgroundColor = UIColor.grayColor()
    
    //let selectedPhoto = photos[indexPath.row]
    //if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
    //cell.contentView.backgroundColor = UIColor.init(white: 1.0, alpha: 1 )
    //cell.photoImageView.alpha = 0.5
    //  photosToRemove.append(selectedPhoto)
    //}
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
