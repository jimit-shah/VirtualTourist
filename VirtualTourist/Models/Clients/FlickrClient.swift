//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/10/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import Foundation

class FlickrClient {
  
  
  fileprivate init() {}
  
  // MARK:- Shared Instance

  class func sharedInstance() -> FlickrClient {
    struct Singleton {
      static let sharedInstance = FlickrClient()
    }
    return Singleton.sharedInstance
  }
  
  // MARK: - Properties
  
  // shared session
  var session = URLSession.shared
  
  
  // MARK: HTTP Methods
  
  // MARK: GET
  
  func taskForGETMethod(_ method: String, parameters: [String: Any], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
    
    // 1. Set the parameters
    var parametersWithKeys = parameters
    
    // 2/3. Build the URL, Configure the request
    let request = NSMutableURLRequest(url: urlFromParameters(parametersWithKeys, withPathExtension: method))
    //request.addValue(Constants.ApiKey, forHTTPHeaderField: ParameterKeys.ApiKey)
    //request.addValue(Constants.ApplicationID, forHTTPHeaderField: ParameterKeys.ApplicationID)
    
    // 4. Make the requeset
    let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
      
      func sendError(_ error: String) {
        var userInfo = [String: Any]()
        
        userInfo[NSLocalizedDescriptionKey] = error
        userInfo[NSUnderlyingErrorKey] = error
        userInfo["http_response"] = response
        
        completionHandlerForGET(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
      }
      
      // GUARD: Was there an error?
      guard (error == nil) else {
        sendError("There was an error: \(error!.localizedDescription)")
        return
      }
      
      // GUARD: Did we get a successful 2XX response?
      guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
        sendError("Your request returned a status code other than 2xx!")
        return
      }
      
      
      // GUARD: Was there any data returned?
      guard let data = data else {
        sendError("No data was returned by the GET request!")
        return
      }
      
      // 5/6. Parse the data and use the data (happens in completion handler)
      self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
    }
    
    // 7. Start the request
    task.resume()
    return task
  }
  
  // MARK: - Helper Methods
  
  // substitute the key for the value that is contained within the method name
  func subtituteKeyInMethod(_ method: String, key: String, value: String) -> String? {
    if method.range(of: "{\(key)}") != nil {
      return method.replacingOccurrences(of: "{\(key)}", with: value)
    } else {
      return nil
    }
  }
  
  // given a Dictionary, return a JSON String
  fileprivate func convertObjectToJSONData(_ object: AnyObject) -> Data{
    
    var parsedResult: Any!
    do {
      parsedResult = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: 0))
    }
    catch {
      return Data()
    }
    
    return parsedResult as! Data
  }
  
  // given raw JSON, return a usable Foundation object
  private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
    
    var parsedResult: AnyObject! = nil
    do {
      parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
    } catch {
      let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]
      completionHandlerForConvertData(nil, NSError(domain: "converDataWithCompletionHandler", code: 1, userInfo: userInfo))
    }
    
    completionHandlerForConvertData(parsedResult, nil)
  }
  
  
  // create a URL from parameters
  private func urlFromParameters(_ parameters: [String:Any], withPathExtension: String? = nil) -> URL {
    var components = URLComponents()
    components.scheme = Constants.ApiScheme
    components.host = Constants.ApiHost
    components.path = Constants.ApiPath + (withPathExtension ?? "")
    components.queryItems = [URLQueryItem]()
    
    for (key, value) in parameters {
      let queryItem = URLQueryItem(name: key, value: "\(value)")
      components.queryItems!.append(queryItem)
    }
    print("\(components.url!)")
    return components.url!
    
  }

}
