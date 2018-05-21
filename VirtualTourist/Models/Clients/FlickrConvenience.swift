//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/20/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import Foundation

extension FlickrClient {
  
  // MARK: - Convenience Methods
  
  func searchByLocation(latitude lat: Double, longitude lon: Double, page: Int = 1, completion: @escaping (_ results: [String: AnyObject]?, _ error: NSError?) -> Void) -> URLSessionDataTask {
    
    // Define BBox parameter value.
    let minLon = max(lon - Config.SearchBBoxHalfWidth, Config.SearchLonRange.0)
    let minLat = max(lat - Config.SearchBBoxHalfHeight, Config.SearchLatRange.0)
    let maxLon = min(lon + Config.SearchBBoxHalfWidth, Config.SearchLonRange.1)
    let maxLat = min(lat + Config.SearchBBoxHalfHeight, Config.SearchLatRange.1)
    let boundingBoxString = "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    
    var parametersWithKeys = [String:Any]()
  
    let parameters: [String: Any] = [
      ParameterKeys.APIKey: Constants.ApiKey,
      ParameterKeys.BoundingBox: boundingBoxString,
      ParameterKeys.Extras: ParameterValues.MediumURL,
      ParameterKeys.Format: ParameterValues.ResponseFormat,
      ParameterKeys.HasGeo: ParameterValues.IsGeoTagged,
      ParameterKeys.Method: Methods.PhotoSearch,
      ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback,
      ParameterKeys.SafeSearch: ParameterValues.UseSafeSearch,
      ParameterKeys.PerPage: ParameterValues.PerPage,
      ParameterKeys.Page: page,
      ParameterKeys.Radius: Config.SearchRadius,
      ParameterKeys.GeoContext: ParameterValues.GeoContext
    ]
    
    let task = taskForGETMethod("/", parameters: parameters) { (results, error) in
      
      // Custom error function
      func sendError(_ code: Int, errorString: String) {
        var userInfo = [String: Any]()
        
        userInfo[NSLocalizedDescriptionKey] = errorString
        userInfo[NSUnderlyingErrorKey] = error
        userInfo["results"] = results
        
        completion(nil, NSError(domain: "searchByLocation", code: code, userInfo: userInfo))
      }
      
      if let error = error {
        sendError(error.code, errorString: error.localizedDescription)
        return
      }
      
      let results = results as! [String: AnyObject]
      
      /* GUARD: Did API return an error (stat != ok)? */
      guard let stat = results[JSONResponseKeys.StatusCode] as? String , stat == JSONResponseKeys.OkStatus else {
        sendError(1, errorString: "Flickr API request returned an error.")
        return
      }
      
      completion(results, nil)
    }
    
    return task
  }
  
}
