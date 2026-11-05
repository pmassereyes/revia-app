//
//  ResultatsView.swift
//  RevIA
//

import SwiftData
import SwiftUI

/// Score du quiz et liste des erreurs, avec la bonne réponse et l'explication.
struct ResultatsView: View {
    let viewModel: QuizViewModel
    let terminer: () -> Void

    private var total: Int { viewModel.reponses.count }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Text("\(viewModel.score) / \(total)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                    Text(appreciation)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            if viewModel.erreurs.isEmpty {
                Section {
                    Label("Aucune erreur.", systemImage: "star.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Section("À retravailler") {
                    ForEach(viewModel.erreurs, id: \.question.persistentModelID) { erreur in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(erreur.question.question)
                                .font(.headline)
                            Label(erreur.question.propositions[erreur.choix], systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Label(erreur.question.bonneReponse, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(erreur.question.explication)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button("Terminer", action: terminer)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var appreciation: String {
        guard total > 0 else { return "" }
        switch Double(viewModel.score) / Double(total) {
        case 1: return "Parfait !"
        case 0.7...: return "Bien joué. Les questions ratées reviendront demain."
        default: return "Les questions ratées reviendront dès demain."
        }
    }
}
