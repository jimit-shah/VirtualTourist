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
  
  let persistentContainer: NSPersistentContainer
  
  var viewContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
  
  var backgroundContext: NSManagedObjectContext!
  
  init(modelName:String) {
    persistentContainer = NSPersistentContainer(name: modelName)
 
    backgroundContext = persistentContainer.newBackgroundContext()
  }
  
  func configureContexts() {
    
    viewContext.automaticallyMergesChangesFromParent = true
    backgroundContext.automaticallyMergesChangesFromParent = true
    
    backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    
  }
  
  func load(completion: (() -> Void)? = nil) {
    persistentContainer.loadPersistentStores { storeDescription, error in
      guard error == nil else {
        fatalError(error!.localizedDescription)
      }
      
      self.autoSaveViewContext()
      self.configureContexts()
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
