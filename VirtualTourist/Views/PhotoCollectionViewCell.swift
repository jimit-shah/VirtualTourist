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
  
  var photoImage: UIImage? {
    didSet {
      if let image = photoImage {
        photoImageView.image = image
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = 2
        toggleSpinner(false)
      }
    }
  }
  
  weak var delegate: PhotoCellDelegate?
  
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
  
  override func layoutIfNeeded() {
    super.layoutIfNeeded()
  }
  
  @IBAction func deleteButtonTapped(_ sender: UIButton) {
    delegate?.delete(cell: self)
  }
  
}
