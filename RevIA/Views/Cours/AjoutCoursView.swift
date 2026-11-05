//
//  AjoutCoursView.swift
//  RevIA
//

import SwiftUI

/// Titre et date d'un cours dont le PDF vient d'être importé.
struct AjoutCoursView: View {
    @Environment(\.dismiss) private var dismiss
    let titreInitial: String
    let ajouter: (_ titre: String, _ date: Date) -> Void
    let annuler: () -> Void
    @State private var titre = ""
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Section("Titre") {
                    TextField("Titre du cours", text: $titre, prompt: Text(titreInitial))
                }
                Section {
                    DatePicker("Date du cours", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Nouveau cours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        annuler()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        ajouter(titre, date)
                        dismiss()
                    }
                }
            }
            .onAppear { titre = titreInitial }
        }
    }
}
