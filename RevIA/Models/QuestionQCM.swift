//
//  QuestionQCM.swift
//  RevIA
//

import Foundation
import SwiftData

/// Une question enregistrée, avec son suivi de révision (Leitner).
@Model
final class QuestionQCM {
    /// Position dans le QCM du cours.
    var ordre: Int
    var question: String
    /// Dans l'ordre reçu de l'API, qui les a déjà mélangées.
    var propositions: [String]
    var indexBonneReponse: Int
    var explication: String
    var theme: String
    /// Boîte de Leitner, de 1 à 5.
    var boite: Int
    /// Début du jour où la question est à revoir.
    var prochaineRevision: Date
    var cours: Cours?

    init(qcm: QCM, ordre: Int, prochaineRevision: Date) {
        self.ordre = ordre
        self.question = qcm.question
        self.propositions = qcm.propositions
        self.indexBonneReponse = qcm.indexBonneReponse
        self.explication = qcm.explication
        self.theme = qcm.theme
        self.boite = Leitner.premiereBoite
        self.prochaineRevision = prochaineRevision
    }

    var bonneReponse: String {
        propositions.indices.contains(indexBonneReponse) ? propositions[indexBonneReponse] : ""
    }
}
