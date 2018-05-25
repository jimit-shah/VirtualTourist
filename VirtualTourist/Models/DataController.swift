//
//  DataController.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/24/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import UIKit
import CoreData

class DataController: NSObject {
  
  let persistentController: NSPersistentContainer
  
  var viewContext: NSManagedObjectContext {
    return persistentController.viewContext
  }
  
  init(modelName:String) {
    persistentController = NSPersistentContainer(name: modelName)
  }
  
  func load(completion: (() -> Void)? = nil) {
    persistentController.loadPersistentStores { storeDescription, error in
      guard error == nil else {
        fatalError(error!.localizedDescription)
      }
      
      completion?()
    }
  }
}
