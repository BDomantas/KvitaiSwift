//
//  kvitaiApp.swift
//  kvitai
//
//  Created by Domantas Bernatavicius on 2022-06-21.
//

import SwiftUI

@main
struct kvitaiApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
