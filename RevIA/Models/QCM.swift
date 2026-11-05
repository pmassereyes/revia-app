//
//  QCM.swift
//  RevIA
//

import Foundation

/// Une question telle que l'API la renvoie. Elle est ensuite convertie en `QuestionQCM` pour être enregistrée.
nonisolated struct QCM: Codable, Sendable, Equatable {
    let question: String
    /// Déjà mélangées par l'API : ne pas changer leur ordre.
    let propositions: [String]
    let indexBonneReponse: Int
    let explication: String
    /// Libellé court partagé par les questions d'une même notion : clé des statistiques par thème.
    let theme: String
}

/// Corps d'une réponse réussie de `POST /v1/qcm`.
nonisolated struct ReponseQCM: Codable, Sendable, Equatable {
    /// Au moins une question.
    let qcm: [QCM]
    /// Phrase à afficher quand le document ne permet pas de produire le nombre de questions demandé.
    let avertissement: String?
}
