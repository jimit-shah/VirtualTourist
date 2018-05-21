//
//  Pin.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/20/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import UIKit

class Pin: NSObject {
  
  var latitude: Double
  var longitude: Double
  var photos: [UIImage]?
  
  init(latitude: Double, longitude: Double, photos: [UIImage]? = nil) {
    self.latitude = latitude
    self.longitude = longitude
    self.photos = photos
  }
}
