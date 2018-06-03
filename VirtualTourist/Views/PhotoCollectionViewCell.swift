//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/20/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import UIKit

protocol PhotoCellDelegate: class {
  func delete(cell: PhotoCollectionViewCell)
}

class PhotoCollectionViewCell: UICollectionViewCell {
    
  @IBOutlet weak var photoImageView: UIImageView!
  
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  @IBOutlet weak var deleteView: UIVisualEffectView!
  
  var photo: Photo? {
    didSet {
      if let photo = photo {
      photoImageView.image = UIImage(data: photo.imageData!)
      photoImageView.contentMode = .scaleAspectFill
      photoImageView.clipsToBounds = true
      photoImageView.layer.cornerRadius = 2
      toggleSpinner(false)
      }
    }
  }
  
  weak var delegate: PhotoCellDelegate?
  
//  var isEditing: Bool = false {
//    didSet {
//      deleteView.isHidden = !isEditing
//    }
//  }
  
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
  
  override func awakeFromNib() {
    super.awakeFromNib()
    deleteView.layer.cornerRadius = deleteView.bounds.width / 2
    deleteView.layer.masksToBounds = true
  }
  
  @IBAction func deleteButtonTapped(_ sender: UIButton) {
    delegate?.delete(cell: self)
  }
  
}
