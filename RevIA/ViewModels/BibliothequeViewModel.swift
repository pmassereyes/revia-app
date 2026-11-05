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

    private let stockage: StockagePDF

    init(stockage: StockagePDF = .standard) {
        self.stockage = stockage
    }

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

    /// Supprime l'UE, ses cours, leurs questions et leurs PDF.
    func supprimer(_ ue: UE, contexte: ModelContext) {
        let fichiers = ue.cours.compactMap(\.nomFichier)
        contexte.delete(ue)
        try? contexte.save()
        fichiers.forEach(stockage.supprimer)
    }

    /// Importe le PDF choisi. Renvoie le nom du fichier copié, ou `nil` avec un message d'erreur.
    func importerPDF(depuis url: URL) -> String? {
        do {
            let nom = try stockage.importer(depuis: url)
            messageErreur = nil
            return nom
        } catch {
            messageErreur = error.message
            return nil
        }
    }

    /// Crée le cours d'un PDF déjà importé. Sans titre, il prend `titreParDefaut`.
    @discardableResult
    func ajouterCours(titre: String, titreParDefaut: String, date: Date, nomFichier: String, ue: UE, contexte: ModelContext) -> Cours {
        let titre = titre.trimmingCharacters(in: .whitespacesAndNewlines)
        let cours = Cours(titre: titre.isEmpty ? titreParDefaut : titre, date: date, nomFichier: nomFichier, ue: ue)
        contexte.insert(cours)
        try? contexte.save()
        return cours
    }

    /// Import abandonné : le PDF copié ne sert plus.
    func abandonnerImport(_ nomFichier: String) {
        stockage.supprimer(nomFichier)
    }

    /// Supprime le cours, ses questions et son PDF.
    func supprimer(_ cours: Cours, contexte: ModelContext) {
        let fichier = cours.nomFichier
        contexte.delete(cours)
        try? contexte.save()
        if let fichier { stockage.supprimer(fichier) }
    }

    func effacerErreur() {
        messageErreur = nil
    }
}
