//
//  DetailCoursView.swift
//  RevIA
//

import QuickLook
import SwiftData
import SwiftUI

/// Un cours, son PDF et son QCM : génération, régénération, thèmes.
struct DetailCoursView: View {
    @Environment(\.modelContext) private var contexte
    @State private var viewModel: DetailCoursViewModel
    @State private var regenerationAConfirmer = false
    @State private var pdfAffiche: URL?
    @State private var quiz: QuizViewModel?

    init(cours: Cours) {
        _viewModel = State(initialValue: DetailCoursViewModel(cours: cours))
    }

    private var cours: Cours { viewModel.cours }

    var body: some View {
        List {
            Section {
                if let ue = cours.ue {
                    LabeledContent("UE", value: ue.nom)
                }
                LabeledContent("Date") {
                    Text(cours.date, format: .dateTime.day().month(.wide).year())
                }
                if let url = viewModel.urlDuPDF {
                    Button("Voir le PDF", systemImage: "doc.richtext") { pdfAffiche = url }
                }
            }

            Section("QCM") {
                etat
                if !cours.questions.isEmpty && !viewModel.generationEnCours {
                    Button("Commencer le quiz", systemImage: "play.fill") {
                        quiz = QuizViewModel(questions: cours.questionsOrdonnees, perimetre: .cours, titre: cours.titre)
                    }
                        .font(.headline)
                }
                if viewModel.peutGenerer {
                    Stepper(
                        libelleQuestions(viewModel.nbQuestions),
                        value: $viewModel.nbQuestions,
                        in: DetailCoursViewModel.plageNbQuestions
                    )
                    Button(cours.questions.isEmpty ? "Générer le QCM" : "Régénérer le QCM", systemImage: "sparkles") {
                        if viewModel.regenerationAConfirmer {
                            regenerationAConfirmer = true
                        } else {
                            lancerGeneration()
                        }
                    }
                }
            }

            if !cours.questions.isEmpty {
                Section("Thèmes") {
                    ForEach(viewModel.themes, id: \.theme) { theme in
                        LabeledContent(theme.theme, value: "\(theme.nombre)")
                    }
                }
            }
        }
        .navigationTitle(cours.titre)
        .navigationBarTitleDisplayMode(.inline)
        .quickLookPreview($pdfAffiche)
        .fullScreenCover(item: $quiz) { QuizView(viewModel: $0) }
        .confirmationDialog(
            "Régénérer le QCM ?",
            isPresented: $regenerationAConfirmer,
            titleVisibility: .visible
        ) {
            Button("Régénérer", role: .destructive) { lancerGeneration() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Le QCM actuel (\(libelleQuestions(cours.questions.count))) et son suivi de révision seront remplacés.")
        }
    }

    @ViewBuilder
    private var etat: some View {
        switch cours.statut {
        case .jamaisGeneree:
            Label("Aucun QCM pour l'instant.", systemImage: "doc.questionmark")
                .foregroundStyle(.secondary)
        case .enCours:
            HStack(spacing: 12) {
                ProgressView()
                VStack(alignment: .leading) {
                    Text("Génération en cours…")
                    Text("Comptez de 20 à 45 secondes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        case .terminee:
            Label(libelleQuestions(cours.questions.count), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            if let avertissement = cours.avertissement {
                Label(avertissement, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        case .echec:
            Label(cours.messageErreur ?? "La génération a échoué.", systemImage: "xmark.octagon")
                .foregroundStyle(.red)
        }
    }

    private func lancerGeneration() {
        Task { await viewModel.generer(contexte: contexte) }
    }
}
