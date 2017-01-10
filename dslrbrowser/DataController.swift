//
//  DataController.swift
//  dslrbrowser
//
//  Created by Andras Bekesi on 09/01/17.
//  Copyright © 2017 Andras Bekesi. All rights reserved.
//

import CoreData

class DataController : NSObject {
    var managedObjectContext: NSManagedObjectContext
    
    override init() {
        
        guard let modelURL = Bundle.main.url(forResource: "Model", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        print("Model ",modelURL.absoluteString, "opened")
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        
        let backgroundQueue = DispatchQueue(label: "hu.bikeonet.dslrbrowser.datacontroller.init", qos: .background)
        backgroundQueue.async {
            let docURL:URL = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
            let storeURL = docURL.appendingPathComponent("DataModel.sqlite")
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                print("Database ",storeURL.absoluteString, "opened")
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
        
    }
    
    func waitUntilInitialized() {
        while(managedObjectContext.persistentStoreCoordinator?.persistentStores.count == 0) {
            print("waiting...")
            sleep(3)
        }
    }
    
    /*
     //initialize persistence controller
     let dataController:DataController = DataController()
     
     //create a new persistent entity
     let photoEntity:PhotoEntity = NSEntityDescription.insertNewObject(forEntityName: "PhotoEntity", into: dataController.managedObjectContext) as! PhotoEntity
     photoEntity.cameraKey = "cameraKey1"
     photoEntity.localIdentifier = "localIdentifier1"
     photoEntity.title = "title1"
     
     //wait until store is initialized
     while( dataController.managedObjectContext.persistentStoreCoordinator?.persistentStores.count == 0) {
     print("waiting...")
     }
     //check if store is initialized
     if ( (dataController.managedObjectContext.persistentStoreCoordinator?.persistentStores.count)! > 0) {
     do {
     //save entity
     try dataController.managedObjectContext.save()
     print("saved")
     } catch {
     fatalError("Failure to save context: \(error)")
     }
     }
     
     //query entities
     let photoEntityFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoEntity")
     let key:String="cameraKey1"
     let tit:String="title1"
     photoEntityFetchRequest.predicate = NSPredicate.init(format: "cameraKey == %@ and title == %@", key, tit)
     do {
     let fetchedPhotoEntities = try dataController.managedObjectContext.fetch(photoEntityFetchRequest) as! [PhotoEntity]
     for entity in fetchedPhotoEntities {
     print(entity.localIdentifier ?? "???")
     //delete entity
     dataController.managedObjectContext.delete(entity)
     }
     
     //persist deletion
     try dataController.managedObjectContext.save()
     
     } catch {
     fatalError("Failed to fetch photos: \(error)")
     }
     */
    
    
}


