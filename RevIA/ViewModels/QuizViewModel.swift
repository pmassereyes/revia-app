//
//  QuizViewModel.swift
//  RevIA
//

import Foundation
import Observation
import SwiftData

/// Un quiz, question par question. Chaque réponse met aussitôt à jour la boîte de Leitner de la question,
/// ce qui garde le suivi même si l'utilisateur quitte le quiz avant la fin.
@Observable
final class QuizViewModel {
    struct Reponse {
        let question: QuestionQCM
        let choix: Int
        var correcte: Bool { choix == question.indexBonneReponse }
    }

    let questions: [QuestionQCM]
    let perimetre: PerimetreSession
    let titre: String
    private(set) var index = 0
    private(set) var reponses: [Reponse] = []
    private(set) var termine = false

    private let maintenant: () -> Date
    private let calendrier: Calendar

    init(
        questions: [QuestionQCM],
        perimetre: PerimetreSession,
        titre: String,
        maintenant: @escaping () -> Date = { .now },
        calendrier: Calendar = .current
    ) {
        self.questions = questions
        self.perimetre = perimetre
        self.titre = titre
        self.maintenant = maintenant
        self.calendrier = calendrier
        termine = questions.isEmpty
    }

    var questionCourante: QuestionQCM? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    /// Réponse donnée à la question courante, une fois corrigée.
    var reponseCourante: Reponse? {
        reponses.indices.contains(index) ? reponses[index] : nil
    }

    var estDerniereQuestion: Bool {
        index == questions.count - 1
    }

    var score: Int {
        reponses.filter(\.correcte).count
    }

    var erreurs: [Reponse] {
        reponses.filter { !$0.correcte }
    }

    /// Une seule réponse par question : la première est corrigée tout de suite.
    func repondre(_ choix: Int, contexte: ModelContext) {
        guard let question = questionCourante, reponseCourante == nil,
              question.propositions.indices.contains(choix) else { return }
        let reponse = Reponse(question: question, choix: choix)
        reponses.append(reponse)
        question.enregistrerReponse(correcte: reponse.correcte, le: maintenant(), calendrier: calendrier)
        try? contexte.save()
    }

    /// Passe à la question suivante, ou termine le quiz et enregistre la session.
    func continuer(contexte: ModelContext) {
        guard reponseCourante != nil, !termine else { return }
        if estDerniereQuestion {
            terminer(contexte: contexte)
        } else {
            index += 1
        }
    }

    private func terminer(contexte: ModelContext) {
        termine = true
        let detail = reponses.map {
            ReponseSession(theme: $0.question.theme, nomUE: $0.question.cours?.ue?.nom ?? "", correcte: $0.correcte)
        }
        contexte.insert(SessionRevision(date: maintenant(), perimetre: perimetre, titre: titre, reponses: detail))
        try? contexte.save()
    }
}
