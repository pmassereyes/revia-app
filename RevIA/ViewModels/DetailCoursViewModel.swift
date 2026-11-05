//
//  DetailCoursViewModel.swift
//  RevIA
//

import Foundation
import Observation
import SwiftData

@Observable
final class DetailCoursViewModel {
    static let plageNbQuestions = 1...30
    static let nbQuestionsParDefaut = 10
    static let messageSansConfiguration = "Renseignez l'adresse de l'API et le jeton dans Réglages."
    static let messagePDFIntrouvable = "Le PDF de ce cours est introuvable. Supprimez le cours, puis importez-le de nouveau."

    let cours: Cours
    var nbQuestions = nbQuestionsParDefaut
    private(set) var generationEnCours = false

    private let stockage: StockagePDF
    /// `nil` tant que l'adresse de l'API ou le jeton manquent.
    private let fabriqueGenerateur: () -> (any GenerateurQCM)?

    init(
        cours: Cours,
        stockage: StockagePDF = .standard,
        fabriqueGenerateur: @escaping () -> (any GenerateurQCM)? = {
            ReglagesAPI.standard.configuration.map { APIGenerateur(configuration: $0) }
        }
    ) {
        self.cours = cours
        self.stockage = stockage
        self.fabriqueGenerateur = fabriqueGenerateur
    }

    var peutGenerer: Bool {
        !generationEnCours && cours.statut != .enCours
    }

    /// Régénérer remplace les questions et leur suivi de révision : l'utilisateur doit confirmer.
    var regenerationAConfirmer: Bool {
        !cours.questions.isEmpty
    }

    var urlDuPDF: URL? {
        cours.nomFichier.map(stockage.url(de:))
    }

    /// Thèmes du QCM, avec leur nombre de questions, par ordre d'apparition.
    var themes: [(theme: String, nombre: Int)] {
        var ordre: [String] = []
        var nombres: [String: Int] = [:]
        for question in cours.questionsOrdonnees {
            if nombres[question.theme] == nil { ordre.append(question.theme) }
            nombres[question.theme, default: 0] += 1
        }
        return ordre.map { ($0, nombres[$0] ?? 0) }
    }

    /// Ne part que d'une action explicite de l'utilisateur.
    func generer(contexte: ModelContext) async {
        guard peutGenerer else { return }
        guard let generateur = fabriqueGenerateur() else {
            echouer(code: "configuration", message: Self.messageSansConfiguration, contexte: contexte)
            return
        }
        guard let nom = cours.nomFichier, let pdf = try? stockage.donnees(de: nom) else {
            echouer(code: "pdf_introuvable", message: Self.messagePDFIntrouvable, contexte: contexte)
            return
        }

        generationEnCours = true
        cours.statut = .enCours
        try? contexte.save()
        let execution = ExecutionProlongee()
        execution.commencer("Génération du QCM")
        defer {
            execution.terminer()
            generationEnCours = false
        }

        do {
            let reponse = try await generateur.generer(pdf: pdf, nbQuestions: nbQuestions)
            cours.remplacerQuestions(par: reponse, dans: contexte)
            try? contexte.save()
        } catch {
            echouer(code: error.code, message: error.messagePourUtilisateur, contexte: contexte)
        }
    }

    private func echouer(code: String, message: String, contexte: ModelContext) {
        cours.statut = .echec
        cours.codeErreur = code
        cours.messageErreur = message
        try? contexte.save()
    }
}
