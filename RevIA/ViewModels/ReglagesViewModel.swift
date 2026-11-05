//
//  ReglagesViewModel.swift
//  RevIA
//

import Foundation
import Observation

@Observable
final class ReglagesViewModel {
    enum EtatConnexion: Equatable {
        case inconnu, enCours, joignable, injoignable
    }

    var urlTexte: String
    var jeton: String
    private(set) var etatConnexion: EtatConnexion = .inconnu
    private(set) var messageErreur: String?

    private let reglages: ReglagesAPI
    private let verifierConnexion: (URL) async -> Bool
    private var urlEnregistree: String
    private var jetonEnregistre: String

    init(
        reglages: ReglagesAPI,
        verifierConnexion: @escaping (URL) async -> Bool = { await APIGenerateur.verifierConnexion(a: $0) }
    ) {
        self.reglages = reglages
        self.verifierConnexion = verifierConnexion
        let url = reglages.urlTexte
        let jeton = reglages.jeton
        urlEnregistree = url
        jetonEnregistre = jeton
        urlTexte = url
        self.jeton = jeton
    }

    var modifie: Bool {
        urlTexte != urlEnregistree || jeton != jetonEnregistre
    }

    func enregistrer() {
        guard ReglagesAPI.urlValide(urlTexte) != nil else {
            messageErreur = Self.messageAdresseInvalide
            return
        }
        do {
            try reglages.enregistrer(urlTexte: urlTexte, jeton: jeton)
            urlEnregistree = reglages.urlTexte
            jetonEnregistre = reglages.jeton
            urlTexte = urlEnregistree
            jeton = jetonEnregistre
            messageErreur = nil
        } catch {
            messageErreur = "Enregistrement impossible dans le Keychain (code \(error.statut))."
        }
    }

    func testerConnexion() async {
        guard let url = ReglagesAPI.urlValide(urlTexte) else {
            etatConnexion = .inconnu
            messageErreur = Self.messageAdresseInvalide
            return
        }
        messageErreur = nil
        etatConnexion = .enCours
        etatConnexion = await verifierConnexion(url) ? .joignable : .injoignable
    }

    static let messageAdresseInvalide = "Adresse invalide : elle doit commencer par http:// ou https://, suivi du nom du serveur."
}
