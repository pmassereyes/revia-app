//
//  RootView.swift
//  RevIA
//

import SwiftData
import SwiftUI

/// Vue racine : un onglet par grande fonction de l'app.
struct RootView: View {
    @Environment(\.modelContext) private var contexte
    @State private var reglages = ReglagesViewModel(reglages: .standard)

    var body: some View {
        TabView {
            BibliothequeView()
                .tabItem { Label("Bibliothèque", systemImage: "books.vertical") }

            ReglagesView(viewModel: reglages)
                .tabItem { Label("Réglages", systemImage: "gearshape") }
        }
        .task { StockageDonnees.reprendreGenerationsInterrompues(dans: contexte) }
    }
}

#Preview {
    RootView()
        .modelContainer(try! StockageDonnees.conteneur(enMemoire: true))
}
