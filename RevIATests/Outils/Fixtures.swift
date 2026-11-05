//
//  Fixtures.swift
//  RevIA
//

import Foundation
import Testing

/// Repère pour retrouver le bundle de tests, où Xcode copie les fixtures.
private final class RepereBundle {}

/// Contenu d'un fichier JSON de `RevIATests/Fixtures`.
func fixture(_ nom: String) throws -> Data {
    let bundle = Bundle(for: RepereBundle.self)
    let url = try #require(
        bundle.url(forResource: nom, withExtension: "json")
            ?? bundle.url(forResource: nom, withExtension: "json", subdirectory: "Fixtures"),
        "Fixture \(nom).json absente du bundle de tests"
    )
    return try Data(contentsOf: url)
}
