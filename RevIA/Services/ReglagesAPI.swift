//
//  ReglagesAPI.swift
//  RevIA
//

import Foundation

/// Adresse de l'API et jeton, saisis dans Réglages.
/// La valeur du Keychain prime. Celle de l'`Info.plist` (issue de `Secrets.xcconfig`, en Debug seulement)
/// ne sert que de valeur initiale, tant que rien n'a été enregistré.
struct ReglagesAPI {
    static let cleURL = "api.url"
    static let cleJeton = "api.jeton"

    let stockage: StockageSecret
    /// En pratique `Bundle.main.infoDictionary`.
    let valeursInitiales: [String: Any]

    static var standard: ReglagesAPI {
        ReglagesAPI(stockage: Keychain(), valeursInitiales: Bundle.main.infoDictionary ?? [:])
    }

    var urlTexte: String {
        stockage.lire(Self.cleURL) ?? valeurInitiale("API_BASE_URL")
    }

    var jeton: String {
        stockage.lire(Self.cleJeton) ?? valeurInitiale("API_TOKEN")
    }

    /// `nil` tant que l'adresse n'est pas valide ou que le jeton manque.
    var configuration: ConfigurationAPI? {
        guard let url = Self.urlValide(urlTexte), !jeton.isEmpty else { return nil }
        return ConfigurationAPI(urlDeBase: url, jeton: jeton)
    }

    func enregistrer(urlTexte: String, jeton: String) throws(ErreurKeychain) {
        try stockage.ecrire(urlTexte.trimmingCharacters(in: .whitespacesAndNewlines), pour: Self.cleURL)
        try stockage.ecrire(jeton.trimmingCharacters(in: .whitespacesAndNewlines), pour: Self.cleJeton)
    }

    /// Une adresse http ou https, avec un hôte.
    static func urlValide(_ texte: String) -> URL? {
        let nettoye = texte.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: nettoye),
              let schema = url.scheme?.lowercased(), ["http", "https"].contains(schema),
              let hote = url.host(), !hote.isEmpty else { return nil }
        return url
    }

    /// Une variable absente de `Secrets.xcconfig` arrive vide dans l'`Info.plist`.
    private func valeurInitiale(_ cle: String) -> String {
        (valeursInitiales[cle] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
