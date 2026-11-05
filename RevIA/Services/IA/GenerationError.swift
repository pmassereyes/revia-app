//
//  GenerationError.swift
//  RevIA
//

import Foundation

/// Corps de toute réponse d'erreur de l'API.
nonisolated struct ErreurAPI: Codable, Sendable, Equatable {
    /// Stable : c'est sur lui que l'app se branche, jamais sur le message.
    let code: String
    /// En français, affiché tel quel.
    let message: String
}

/// Codes d'erreur de l'API, tels qu'elle les renvoie dans `ErreurAPI.code`.
nonisolated enum CodeErreurAPI: String, CaseIterable, Sendable {
    case jetonInvalide = "invalid_token"
    case pdfInvalide = "invalid_pdf"
    case pdfTropVolumineux = "pdf_too_large"
    case requeteInvalide = "invalid_request"
    case tropDeRequetes = "rate_limited"
    case quotaEpuise = "quota_exceeded"
    case iaSurchargee = "provider_overloaded"
    case iaIndisponible = "provider_unavailable"
    case delaiDepasse = "generation_timeout"
    case echecGeneration = "generation_failed"
    case erreurInterne = "internal_error"
    /// Code que cette version de l'app ne connaît pas : traité comme une erreur générique.
    case inconnu

    init(code: String) {
        self = CodeErreurAPI(rawValue: code) ?? .inconnu
    }
}

/// Échec de la génération d'un QCM.
nonisolated enum GenerationError: Error, Equatable, Sendable {
    /// Erreur renvoyée par l'API : on se branche sur le code, on affiche le message reçu.
    case api(CodeErreurAPI, message: String)
    /// Pas de réponse exploitable : hors ligne, serveur arrêté, réponse non JSON.
    case reseau
    /// PDF de plus de 20 Mo, refusé avant l'envoi.
    case pdfTropVolumineux

    init(erreur: ErreurAPI) {
        self = .api(CodeErreurAPI(code: erreur.code), message: erreur.message)
    }
}
