//
//  BibliothequeViewModel.swift
//  RevIA
//

import Foundation
import Observation
import SwiftData

@Observable
final class BibliothequeViewModel {
    private(set) var messageErreur: String?

    /// Ajoute une UE. Refuse un nom vide, ou déjà pris sans tenir compte de la casse ni des accents.
    @discardableResult
    func ajouterUE(nom: String, couleur: CouleurUE, contexte: ModelContext) -> UE? {
        let nom = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nom.isEmpty else {
            messageErreur = "Donnez un nom à l'UE."
            return nil
        }
        let existantes = (try? contexte.fetch(FetchDescriptor<UE>())) ?? []
        let dejaPris = existantes.contains {
            $0.nom.compare(nom, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        guard !dejaPris else {
            messageErreur = "Une UE porte déjà ce nom."
            return nil
        }
        let ue = UE(nom: nom, couleur: couleur)
        contexte.insert(ue)
        try? contexte.save()
        messageErreur = nil
        return ue
    }

    /// Supprime l'UE, ses cours et leurs questions.
    func supprimer(_ ue: UE, contexte: ModelContext) {
        contexte.delete(ue)
        try? contexte.save()
    }

    func effacerErreur() {
        messageErreur = nil
    }
}
