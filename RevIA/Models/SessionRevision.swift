//
//  SessionRevision.swift
//  RevIA
//

import Foundation
import SwiftData

/// Un quiz terminé : son périmètre, son score et le détail des réponses, pour les statistiques.
@Model
final class SessionRevision {
    var date: Date
    /// Valeur brute de `PerimetreSession`.
    var perimetreBrut: String
    /// Titre du cours, ou « À revoir aujourd'hui ».
    var titre: String
    var nbQuestions: Int
    var nbBonnesReponses: Int
    var reponses: [ReponseSession]

    init(date: Date = .now, perimetre: PerimetreSession, titre: String, reponses: [ReponseSession]) {
        self.date = date
        self.perimetreBrut = perimetre.rawValue
        self.titre = titre
        self.reponses = reponses
        self.nbQuestions = reponses.count
        self.nbBonnesReponses = reponses.filter(\.correcte).count
    }

    var perimetre: PerimetreSession {
        PerimetreSession(rawValue: perimetreBrut) ?? .cours
    }
}

enum PerimetreSession: String {
    /// Toutes les questions d'un cours.
    case cours
    /// Les questions à revoir aujourd'hui, toutes UE confondues.
    case aRevoir
}

/// Une réponse d'une session, réduite à ce dont les statistiques ont besoin.
nonisolated struct ReponseSession: Codable, Hashable, Sendable {
    var theme: String
    var nomUE: String
    var correcte: Bool
}
