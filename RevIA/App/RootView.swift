//
//  RootView.swift
//  RevIA
//

import SwiftData
import SwiftUI

/// Vue racine : un onglet par grande fonction de l'app.
struct RootView: View {
    @Environment(\.modelContext) private var contexte
    @Environment(\.scenePhase) private var phase
    @Query private var questions: [QuestionQCM]
    @State private var reglages = ReglagesViewModel(reglages: .standard)
    /// Rafraîchie au retour au premier plan, pour suivre le changement de jour.
    @State private var aujourdHui = Date.now
    @AppStorage(CleRappel.actif) private var rappelActif = false
    @AppStorage(CleRappel.minutes) private var rappelMinutes = Notifications.heureParDefaut

    var body: some View {
        TabView {
            ARevoirView(aujourdHui: aujourdHui)
                .tabItem { Label("À revoir", systemImage: "rectangle.stack") }
                .badge(FileDeRevision.nombreARevoir(parmi: questions, le: aujourdHui))

            BibliothequeView()
                .tabItem { Label("Bibliothèque", systemImage: "books.vertical") }

            StatsView()
                .tabItem { Label("Statistiques", systemImage: "chart.bar") }

            ReglagesView(viewModel: reglages)
                .tabItem { Label("Réglages", systemImage: "gearshape") }
        }
        .task { StockageDonnees.reprendreGenerationsInterrompues(dans: contexte) }
        .onChange(of: phase) { _, nouvelle in
            if nouvelle == .active { aujourdHui = .now }
            // Les réponses du jour changent le nombre de questions des rappels à venir
            if nouvelle != .inactive {
                let revisions = questions.filter { $0.cours != nil }.map(\.prochaineRevision)
                Task { await Notifications.replanifier(revisions: revisions, actif: rappelActif, minutes: rappelMinutes) }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(try! StockageDonnees.conteneur(enMemoire: true))
}
