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
  
  var selectedAnnotation: PinAnnotation? {
    didSet {
      print("selectedAnnotation: \(selectedAnnotation!.coordinate)")
    }
  }
  var photos = [UIImage]()
  
  // MARK: Outlets
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  
  // MARK: Actions
  
  @IBAction func getNewCollection(_ sender: UIBarButtonItem) {
    
  }
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
    
    
    // get photos from flickr
    getPhotos()
  }
  
  // MARK: Helper Methods
  
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
          
          if let photo = UIImage(data: imageData!) {
            self.photos.append(photo)
          }
        }
        
        // assign all photos to pin
        self.selectedAnnotation?.pin.photos = self.photos
        
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
    let photo = photos[indexPath.item]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
    cell.photoImageView.image = photo
    return cell
  }
  
}

// MARK: CollectionView Delegate Methods

extension PhotoAlbumViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
  }
}
