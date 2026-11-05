//
//  StatutGeneration.swift
//  RevIA
//

import Foundation

/// État de la génération du QCM d'un cours. Stocké sous sa valeur brute, avec le code d'erreur à part,
/// pour rester simple à filtrer dans les requêtes SwiftData.
enum StatutGeneration: String, CaseIterable {
    case jamaisGeneree
    case enCours
    case terminee
    case echec
}
