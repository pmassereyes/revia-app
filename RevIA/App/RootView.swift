//
//  RootView.swift
//  RevIA
//

import SwiftUI

/// Vue racine : un onglet par grande fonction de l'app.
struct RootView: View {
    @State private var reglages = ReglagesViewModel(reglages: .standard)

    var body: some View {
        TabView {
            ContentUnavailableView(
                "Bibliothèque",
                systemImage: "books.vertical",
                description: Text("En construction")
            )
            .tabItem { Label("Bibliothèque", systemImage: "books.vertical") }

            ReglagesView(viewModel: reglages)
                .tabItem { Label("Réglages", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
}
