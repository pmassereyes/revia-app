//
//  Keychain.swift
//  RevIA
//

import Foundation
import Security

/// Petites valeurs sensibles, rangées par clé. Protocole pour pouvoir tester sans Keychain.
protocol StockageSecret {
    func lire(_ cle: String) -> String?
    /// Une valeur vide supprime la clé.
    func ecrire(_ valeur: String, pour cle: String) throws(ErreurKeychain)
}

struct ErreurKeychain: Error, Equatable {
    let statut: OSStatus
}

/// Mots de passe génériques du Keychain, regroupés sous un même service.
struct Keychain: StockageSecret {
    let service: String

    init(service: String = "RevIA") {
        self.service = service
    }

    func lire(_ cle: String) -> String? {
        var requete = base(cle)
        requete[kSecReturnData as String] = true
        requete[kSecMatchLimit as String] = kSecMatchLimitOne
        var resultat: CFTypeRef?
        guard SecItemCopyMatching(requete as CFDictionary, &resultat) == errSecSuccess,
              let donnees = resultat as? Data else { return nil }
        return String(data: donnees, encoding: .utf8)
    }

    func ecrire(_ valeur: String, pour cle: String) throws(ErreurKeychain) {
        guard !valeur.isEmpty else {
            let statut = SecItemDelete(base(cle) as CFDictionary)
            guard statut == errSecSuccess || statut == errSecItemNotFound else { throw ErreurKeychain(statut: statut) }
            return
        }
        let donnees = Data(valeur.utf8)
        let modification = SecItemUpdate(base(cle) as CFDictionary, [kSecValueData as String: donnees] as CFDictionary)
        if modification == errSecSuccess { return }
        guard modification == errSecItemNotFound else { throw ErreurKeychain(statut: modification) }

        var ajout = base(cle)
        ajout[kSecValueData as String] = donnees
        ajout[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let statut = SecItemAdd(ajout as CFDictionary, nil)
        guard statut == errSecSuccess else { throw ErreurKeychain(statut: statut) }
    }

    private func base(_ cle: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cle,
        ]
    }
}
