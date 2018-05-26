//
//  Location.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/20/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import Foundation
import MapKit

class PinAnnotation: NSObject, MKAnnotation {
  
  var coordinate: CLLocationCoordinate2D {
    get{
      return CLLocationCoordinate2D(
//        latitude: pin.latitude,
//        longitude: pin.longitude
      )
    }
    set {
//      pin.latitude = newValue.latitude as NSNumber
//      pin.longitude = newValue.longitude as NSNumber
    }
  }
  
  var pin: Pin
  var title: String?
  var subtitle: String?
  
  
  init(with pin: Pin, title: String? = nil, subtitle: String? = nil) {
    self.pin = pin
    self.title = title
    self.subtitle = subtitle
  }
}
