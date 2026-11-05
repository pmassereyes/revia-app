//
//  UE.swift
//  RevIA
//

import Foundation
import SwiftData
import SwiftUI

/// Unité d'enseignement : regroupe des cours.
@Model
final class UE {
    var nom: String
    /// Valeur brute de `CouleurUE`.
    var couleurBrute: String
    var dateCreation: Date

    /// Supprimer une UE supprime ses cours, et donc leurs questions.
    @Relationship(deleteRule: .cascade, inverse: \Cours.ue)
    var cours: [Cours] = []

    init(nom: String, couleur: CouleurUE = .bleu, dateCreation: Date = .now) {
        self.nom = nom
        self.couleurBrute = couleur.rawValue
        self.dateCreation = dateCreation
    }

    var couleur: CouleurUE {
        get { CouleurUE(rawValue: couleurBrute) ?? .bleu }
        set { couleurBrute = newValue.rawValue }
    }
}

/// Palette fixe, pour que les UE restent lisibles en mode clair comme en mode sombre.
enum CouleurUE: String, CaseIterable, Identifiable {
    case bleu, vert, orange, rouge, violet, rose, jaune, gris

    var id: String { rawValue }

    var nom: String { rawValue.capitalized }

    var valeur: Color {
        switch self {
        case .bleu: .blue
        case .vert: .green
        case .orange: .orange
        case .rouge: .red
        case .violet: .purple
        case .rose: .pink
        case .jaune: .yellow
        case .gris: .gray
        }
    }
}
