//
//  RevIAApp.swift
//  RevIA
//

import SwiftData
import SwiftUI

@main
struct RevIAApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: StockageDonnees.modeles)
    }
}
