//
//  GenerateurQCM.swift
//  RevIA
//

import Foundation

/// Source des QCM. Les ViewModels ne dépendent que de ce protocole, ce qui permet de les tester
/// avec un faux générateur, sans serveur.
nonisolated protocol GenerateurQCM: Sendable {
    /// Génère un QCM à partir d'un PDF de cours.
    /// - Parameters:
    ///   - pdf: contenu brut du PDF.
    ///   - nbQuestions: nombre de questions demandé, de 1 à 30.
    func generer(pdf: Data, nbQuestions: Int) async throws(GenerationError) -> ReponseQCM
}
