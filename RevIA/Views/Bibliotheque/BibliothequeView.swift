//
//  BibliothequeView.swift
//  RevIA
//

import SwiftData
import SwiftUI

/// Liste des UE.
struct BibliothequeView: View {
    @Environment(\.modelContext) private var contexte
    @Query(sort: \UE.nom) private var ues: [UE]
    @State private var viewModel = BibliothequeViewModel()
    @State private var ajoutAffiche = false
    @State private var ueASupprimer: UE?

    var body: some View {
        NavigationStack {
            Group {
                if ues.isEmpty {
                    ContentUnavailableView {
                        Label("Aucune UE", systemImage: "books.vertical")
                    } description: {
                        Text("Ajoutez une unité d'enseignement pour y ranger vos cours.")
                    } actions: {
                        Button("Ajouter une UE") { ajoutAffiche = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(ues) { ue in
                        NavigationLink(value: ue) {
                            LigneUE(ue: ue)
                        }
                        .swipeActions {
                            Button("Supprimer", systemImage: "trash", role: .destructive) { ueASupprimer = ue }
                        }
                    }
                }
            }
            .navigationTitle("Bibliothèque")
            .navigationDestination(for: UE.self) { UEDetailView(ue: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Ajouter une UE", systemImage: "plus") { ajoutAffiche = true }
                }
            }
            .sheet(isPresented: $ajoutAffiche) {
                AjoutUEView(viewModel: viewModel)
            }
            .alert(
                "Supprimer l'UE ?",
                isPresented: Binding(get: { ueASupprimer != nil }, set: { if !$0 { ueASupprimer = nil } }),
                presenting: ueASupprimer
            ) { ue in
                Button("Supprimer", role: .destructive) { viewModel.supprimer(ue, contexte: contexte) }
                Button("Annuler", role: .cancel) {}
            } message: { ue in
                Text("« \(ue.nom) » sera supprimée, avec ses cours (\(ue.cours.count)), leurs PDF et leurs questions.")
            }
        }
    }
}

private struct LigneUE: View {
    let ue: UE

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ue.couleur.valeur)
                .frame(width: 14, height: 14)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(ue.nom)
                    .font(.headline)
                Text("\(ue.cours.count) cours")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    BibliothequeView()
        .modelContainer(try! StockageDonnees.conteneur(enMemoire: true))
}
