//
//  CoreDataWrapper.swift
//  CoreDataWrapper
//
//  Created by 1002220 on 2016. 12. 1..
//  Copyright © 2016년 n29. All rights reserved.
//

import UIKit
import CoreData

class CoreDataWrapper: NSObject {
    fileprivate let storageManagedObjectContext : NSManagedObjectContext
    fileprivate let mainManagedObjectContext : NSManagedObjectContext
    
    required init( name : String, completion : @escaping () -> () ) {
        guard let modelUrl = Bundle.main.url(forResource: name, withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        
        guard let mom = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Error initializing mom from: \(modelUrl)")
        }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        storageManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        storageManagedObjectContext.persistentStoreCoordinator = psc
        
        mainManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainManagedObjectContext.parent = storageManagedObjectContext
        
        DispatchQueue.global().async {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let docUrl = urls[urls.endIndex-1]
            /* The directory the application uses to store the Core Data store file.
             This code uses a file named "DataModel.sqlite" in the application's documents directory.
             */
            
            let storeURL = docUrl.appendingPathComponent(name + ".sqlite")
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
            
            completion()
        }
    }
}

extension CoreDataWrapper {
//    func fetch( entity : String )
}

extension CoreDataWrapper {
    func save() {
        var tempMOC : NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        tempMOC .perform { 
            try! tempMOC.save()
        }
        
        mainManagedObjectContext.perform {
            try! self.mainManagedObjectContext.save()
            
            storageManagedObjectContext.perform {
                try! self.storageManagedObjectContext.save()
            }
        }
    }
}
