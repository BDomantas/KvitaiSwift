//
//  ScanData.swift
//  kvitai
//
//  Created by Domantas Bernatavicius on 2022-07-02.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Receipts")

    init() {
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load \(error.localizedDescription)")
            }
        }
    }
}
