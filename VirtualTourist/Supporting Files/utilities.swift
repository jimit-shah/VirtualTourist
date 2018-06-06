//
//  utilities.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/24/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import UIKit


// MARK: - ImageView Extension to download images.

extension UIImageView {
  func downloadedFrom(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
    contentMode = mode
    URLSession.shared.dataTask(with: url) { data, response, error in
      guard
        let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
        let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
        let data = data, error == nil,
        let image = UIImage(data: data)
        else { return }
      DispatchQueue.main.async() {
        self.image = image
      }
      }.resume()
  }
  func downloadedFrom(link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
    guard let url = URL(string: link) else { return }
    downloadedFrom(url: url, contentMode: mode)
  }
  
}

