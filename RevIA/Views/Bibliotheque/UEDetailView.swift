//
//  UEDetailView.swift
//  RevIA
//

import SwiftData
import SwiftUI

/// Les cours d'une UE, du plus récent au plus ancien.
struct UEDetailView: View {
    let ue: UE

    private var coursTries: [Cours] {
        ue.cours.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if ue.cours.isEmpty {
                ContentUnavailableView(
                    "Aucun cours",
                    systemImage: "doc.text",
                    description: Text("Importez le PDF d'un cours pour en tirer un QCM.")
                )
            } else {
                List(coursTries) { cours in
                    LigneCours(cours: cours)
                }
            }
        }
        .navigationTitle(ue.nom)
    }
}

struct LigneCours: View {
    let cours: Cours

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cours.titre)
                .font(.headline)
            HStack {
                Text(cours.date, format: .dateTime.day().month().year())
                Text("·")
                statut
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statut: some View {
        switch cours.statut {
        case .jamaisGeneree:
            Text("QCM à générer")
        case .enCours:
            Text("Génération en cours…")
        case .terminee:
            Text("\(cours.questions.count) questions")
        case .echec:
            Text("Échec de la génération")
                .foregroundStyle(.red)
        }
    }
}
