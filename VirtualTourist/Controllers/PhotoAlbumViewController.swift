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
  var selectedAnnotation: MKAnnotation? {
    didSet {
      
    }
  }
  
    override func viewDidLoad() {
        super.viewDidLoad()
      print("selectedAnnotation: \(selectedAnnotation!.coordinate)")
    }

  
}
