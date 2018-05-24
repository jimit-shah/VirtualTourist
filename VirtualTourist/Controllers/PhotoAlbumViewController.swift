//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 12/1/17.
//  Copyright © 2017 Jimit Shah. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {
  
  
  // MARK: Properties
  
  var photos = [Data]()
  let regionRadius: CLLocationDistance = 1000
  var selectedAnnotation: MKAnnotation? {
    didSet {
      print("selectedAnnotation: \(selectedAnnotation!.coordinate)")
    }
  }
  
  let inset: CGFloat = 8.0
  let spacing: CGFloat = 8.0
  let lineSpacing: CGFloat = 8.0
  
  // MARK: Outlets
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
  
  // MARK: Actions
  
  @IBAction func getNewCollection(_ sender: UIBarButtonItem) {
    
  }
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
    
    // load annotation on map and set region
    mapView.addAnnotation(selectedAnnotation!)
    centerMapOnLocation(annotation: selectedAnnotation!)
    
    // get photos from flickr
    getPhotos()
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
          let imageURL = URL(string: imageURLString)
          print("Photo URL: ---- \(imageURLString)")
          
          let imageData = try? Data(contentsOf: imageURL!)
          if let data = imageData {
            self.photos.append(data)
          }
         
        }
        
        performUIUpdatesOnMain {
          self.collectionView.reloadData()
        }
      }
      
    }
  }
  
}

// MARK: CollectionView Data Source Methods

extension PhotoAlbumViewController: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    //let photo = photos[indexPath.item]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
    
    
    configurePhotoCell(cell, cellForItemAt: indexPath)
    //cell.photoImageView.image = photo
    
    return cell
  }
  
  // MARK: Configure Cell
  
  func configurePhotoCell(_ cell: PhotoCollectionViewCell, cellForItemAt indexPath: IndexPath) {
    
    let imageData = photos[indexPath.row]
    
    cell.toggleSpinner(true)
    
    let image = UIImage(data: imageData)
    
    performUIUpdatesOnMain {
      cell.photoImageView.image = image
      cell.toggleSpinner(false)
    }
    
  }
  
}



// MARK: CollectionView Delegate Methods

extension PhotoAlbumViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
  }
}


// MARK: - UICollectionViewDelegateFlowLayout

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let columns: CGFloat = collectionView.frame.width > collectionView.frame.height ? 5.0 : 3.0
    
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
