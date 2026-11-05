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

    static let messageGenerationInterrompue =
        "La génération a été interrompue. Relancez-la : si le serveur avait terminé, le résultat arrivera tout de suite."

    /// Au lancement, aucune génération ne peut être en cours : celles qui l'étaient ont été coupées
    /// par la fermeture de l'app. Elles passent en échec, pour pouvoir être relancées.
    static func reprendreGenerationsInterrompues(dans contexte: ModelContext) {
        let enCours = StatutGeneration.enCours.rawValue
        let interrompus = (try? contexte.fetch(FetchDescriptor<Cours>(predicate: #Predicate { $0.statutBrut == enCours }))) ?? []
        for cours in interrompus {
            cours.statut = .echec
            cours.codeErreur = "interrompue"
            cours.messageErreur = messageGenerationInterrompue
        }
        if !interrompus.isEmpty {
            try? contexte.save()
        }
    }
}
