//
//  AjoutUEView.swift
//  RevIA
//

import SwiftData
import SwiftUI

/// Création d'une UE : nom et couleur.
struct AjoutUEView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var contexte
    let viewModel: BibliothequeViewModel
    @State private var nom = ""
    @State private var couleur: CouleurUE = .bleu

    var body: some View {
        NavigationStack {
            Form {
                Section("Nom") {
                    TextField("Nom de l'UE", text: $nom, prompt: Text("Ex. : Réseaux et protocoles"))
                }
                Section("Couleur") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(CouleurUE.allCases) { choix in
                            Button {
                                couleur = choix
                            } label: {
                                Circle()
                                    .fill(choix.valeur)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if choix == couleur {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(choix.nom)
                            .accessibilityAddTraits(choix == couleur ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                if let message = viewModel.messageErreur {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Nouvelle UE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        if viewModel.ajouterUE(nom: nom, couleur: couleur, contexte: contexte) != nil {
                            dismiss()
                        }
                    }
                    .disabled(nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { viewModel.effacerErreur() }
        }
    }
}
