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
      
      self.autoSaveViewContext()
      completion?()
    }
  }
}


extension DataController {
  func autoSaveViewContext(interval: TimeInterval = 30) {
    print("Autosaving")
    guard interval > 0 else {
      print("cannot save negative autosave interval")
      return
    }
    if viewContext.hasChanges {
      try? viewContext.save()
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
      self.autoSaveViewContext(interval: interval)
    }
  }
}
