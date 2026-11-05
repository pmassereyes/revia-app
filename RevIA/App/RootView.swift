//
//  RootView.swift
//  RevIA
//

import SwiftUI

/// Vue racine. Elle accueillera les onglets Bibliothèque, À revoir, Statistiques et Réglages.
struct RootView: View {
    var body: some View {
        ContentUnavailableView(
            "RevIA",
            systemImage: "book.closed",
            description: Text("En construction")
        )
    }
}

#Preview {
    RootView()
}
