//
//  StockageDonnees.swift
//  RevIA
//

import Foundation
import SwiftData

/// Schéma SwiftData de l'app, partagé par l'app et les tests.
enum StockageDonnees {
    static let modeles: [any PersistentModel.Type] = [UE.self, Cours.self, QuestionQCM.self]

    static func conteneur(enMemoire: Bool = false) throws -> ModelContainer {
        let schema = Schema(modeles)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: enMemoire)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
