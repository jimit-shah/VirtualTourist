//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/20/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
  @IBOutlet weak var photoImageView: UIImageView!
  
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  func toggleSpinner(_ show: Bool) {
    if show {
      activityIndicator.startAnimating()
      activityIndicator.isHidden = false
    } else {
      if activityIndicator.isAnimating {
        activityIndicator.stopAnimating()
      }
    }
  }
}
