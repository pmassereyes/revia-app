//
//  QuizView.swift
//  RevIA
//

import SwiftData
import SwiftUI

/// Quiz plein écran : une question à la fois, puis les résultats.
struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var contexte
    @State private var viewModel: QuizViewModel

    init(viewModel: QuizViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.termine {
                    ResultatsView(viewModel: viewModel) { dismiss() }
                } else if let question = viewModel.questionCourante {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            progression
                            QuestionCardView(question: question, reponse: viewModel.reponseCourante) { choix in
                                viewModel.repondre(choix, contexte: contexte)
                            }
                            if viewModel.reponseCourante != nil {
                                Button(viewModel.estDerniereQuestion ? "Voir les résultats" : "Question suivante") {
                                    withAnimation { viewModel.continuer(contexte: contexte) }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(viewModel.titre)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.termine {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Quitter") { dismiss() }
                    }
                }
            }
        }
    }

    private var progression: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Question \(viewModel.index + 1) sur \(viewModel.questions.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: Double(viewModel.index + 1), total: Double(viewModel.questions.count))
        }
    }
}
