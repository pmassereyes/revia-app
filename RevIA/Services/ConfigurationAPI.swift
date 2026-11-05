//
//  ConfigurationAPI.swift
//  RevIA
//

import Foundation

/// Accès à revia-api : adresse de base (par exemple `http://127.0.0.1:8000`) et jeton.
nonisolated struct ConfigurationAPI: Sendable, Equatable {
    let urlDeBase: URL
    let jeton: String
}
