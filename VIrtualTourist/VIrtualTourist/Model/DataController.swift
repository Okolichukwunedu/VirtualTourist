//
//  DataController.swift
//  VIrtualTourist
//
//  Created by Okoli-Chinedu on 29/10/2022.
//  Copyright © 2022 Okoli-Chinedu. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String){
        persistentContainer = NSPersistentContainer (name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else{
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext(interval: 5)
            completion?()
        }
    }
}

extension DataController {
    //MARK: Auto Save
    func autoSaveViewContext (interval: TimeInterval = 30){
        guard interval > 0 else {
            print("cannot save at negative time interval")
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval){
            self.autoSaveViewContext(interval: interval)
        }
    }
}
