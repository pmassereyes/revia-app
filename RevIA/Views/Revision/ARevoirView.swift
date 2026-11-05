//
//  ARevoirView.swift
//  RevIA
//

import SwiftData
import SwiftUI

/// Les questions à revoir aujourd'hui, toutes UE confondues.
struct ARevoirView: View {
    @Query private var questions: [QuestionQCM]
    /// Date de référence, mise à jour quand l'app revient au premier plan (changement de jour).
    let aujourdHui: Date
    /// Figé au lancement : répondre fait sortir les questions de la liste, le quiz ne doit pas en dépendre.
    @State private var quiz: QuizViewModel?

    var body: some View {
        let aRevoir = FileDeRevision.questionsARevoir(parmi: questions, le: aujourdHui)
        NavigationStack {
            Group {
                if aRevoir.isEmpty {
                    ContentUnavailableView {
                        Label("Rien à revoir aujourd'hui", systemImage: "checkmark.seal")
                    } description: {
                        Text(prochaineRevision)
                    }
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(libelleQuestions(aRevoir.count))
                                    .font(.largeTitle.bold())
                                Text("à revoir aujourd'hui")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            Button("Commencer la révision", systemImage: "play.fill") {
                                quiz = QuizViewModel(questions: aRevoir, perimetre: .aRevoir, titre: "À revoir aujourd'hui")
                            }
                            .font(.headline)
                        }
                        Section("Par UE") {
                            ForEach(FileDeRevision.repartitionParUE(aRevoir), id: \.nom) { part in
                                HStack {
                                    Circle().fill(part.couleur.valeur).frame(width: 12, height: 12)
                                    Text(part.nom)
                                    Spacer()
                                    Text("\(part.nombre)").foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("À revoir")
        }
        .fullScreenCover(item: $quiz) { QuizView(viewModel: $0) }
    }

    private var prochaineRevision: String {
        guard let prochaine = FileDeRevision.prochaineRevision(parmi: questions, apres: aujourdHui) else {
            return "Générez le QCM d'un cours : ses questions reviendront ici, selon vos réponses."
        }
        return "Prochaine révision \(FileDeRevision.libelleJour(prochaine.jour, depuis: aujourdHui))  : \(libelleQuestions(prochaine.nombre))."
    }
}
