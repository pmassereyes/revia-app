//
//  Cours.swift
//  RevIA
//

import Foundation
import SwiftData

/// Un PDF de cours, rattaché à une UE, et le QCM qui en a été tiré.
@Model
final class Cours {
    var titre: String
    var date: Date
    /// Nom du PDF dans le dossier des cours de l'app.
    var nomFichier: String?
    /// Valeur brute de `StatutGeneration`.
    var statutBrut: String
    /// Code d'erreur de l'API (ou `reseau`, `pdf_trop_volumineux`) de la dernière génération échouée.
    var codeErreur: String?
    /// Message à afficher après un échec.
    var messageErreur: String?
    /// Phrase renvoyée par l'API quand elle n'a pas pu produire le nombre de questions demandé.
    var avertissement: String?
    var ue: UE?

    @Relationship(deleteRule: .cascade, inverse: \QuestionQCM.cours)
    var questions: [QuestionQCM] = []

    init(titre: String, date: Date = .now, nomFichier: String? = nil, ue: UE? = nil) {
        self.titre = titre
        self.date = date
        self.nomFichier = nomFichier
        self.statutBrut = StatutGeneration.jamaisGeneree.rawValue
        self.ue = ue
    }

    var statut: StatutGeneration {
        get { StatutGeneration(rawValue: statutBrut) ?? .jamaisGeneree }
        set { statutBrut = newValue.rawValue }
    }

    /// Les questions dans l'ordre du QCM, que la relation SwiftData ne conserve pas.
    var questionsOrdonnees: [QuestionQCM] {
        questions.sorted { $0.ordre < $1.ordre }
    }

    /// Remplace les questions du cours par celles reçues de l'API.
    /// Chaque nouvelle question entre en boîte 1, à revoir le lendemain.
    func remplacerQuestions(
        par reponse: ReponseQCM,
        dans contexte: ModelContext,
        maintenant: Date = .now,
        calendrier: Calendar = .current
    ) {
        for ancienne in questions {
            contexte.delete(ancienne)
        }
        let revision = Leitner.prochaineRevision(boite: Leitner.premiereBoite, depuis: maintenant, calendrier: calendrier)
        questions = reponse.qcm.enumerated().map { ordre, qcm in
            QuestionQCM(qcm: qcm, ordre: ordre, prochaineRevision: revision)
        }
        avertissement = reponse.avertissement
        statut = .terminee
        codeErreur = nil
        messageErreur = nil
    }
}
