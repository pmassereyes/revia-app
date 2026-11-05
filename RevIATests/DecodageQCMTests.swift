//
//  DecodageQCMTests.swift
//  RevIA
//

import Foundation
import Testing
@testable import RevIA

/// Les 11 codes du contrat de l'API, écrits en toutes lettres pour ne pas dépendre des valeurs de l'enum.
private let codesDeLAPI: [(String, CodeErreurAPI)] = [
    ("invalid_token", .jetonInvalide),
    ("invalid_pdf", .pdfInvalide),
    ("pdf_too_large", .pdfTropVolumineux),
    ("invalid_request", .requeteInvalide),
    ("rate_limited", .tropDeRequetes),
    ("quota_exceeded", .quotaEpuise),
    ("provider_overloaded", .iaSurchargee),
    ("provider_unavailable", .iaIndisponible),
    ("generation_timeout", .delaiDepasse),
    ("generation_failed", .echecGeneration),
    ("internal_error", .erreurInterne),
]

/// Repère pour retrouver le bundle de tests, où Xcode copie les fixtures.
private final class RepereBundle {}

private func fixture(_ nom: String) throws -> Data {
    let bundle = Bundle(for: RepereBundle.self)
    let url = try #require(
        bundle.url(forResource: nom, withExtension: "json")
            ?? bundle.url(forResource: nom, withExtension: "json", subdirectory: "Fixtures"),
        "Fixture \(nom).json absente du bundle de tests"
    )
    return try Data(contentsOf: url)
}

struct DecodageQCMTests {

    @Test func decodeLaReponseExemplePartageeAvecLAPI() throws {
        let reponse = try JSONDecoder().decode(ReponseQCM.self, from: fixture("reponse_exemple"))

        #expect(reponse.avertissement == nil)
        #expect(reponse.qcm.count == 1)
        let qcm = try #require(reponse.qcm.first)
        #expect(qcm.question == "Quel protocole assure un transport fiable en TCP/IP ?")
        #expect(qcm.propositions == ["UDP", "TCP", "ICMP", "ARP"])
        #expect(qcm.propositions[qcm.indexBonneReponse] == "TCP")
        #expect(qcm.theme == "Réseaux")
        #expect(!qcm.explication.isEmpty)
    }

    @Test func decodeUnAvertissement() throws {
        let json = """
            {"qcm": [{"question": "Q ?", "propositions": ["A", "B"], "indexBonneReponse": 0,
                      "explication": "E", "theme": "T"}],
             "avertissement": "Le document ne permet de produire que 1 question."}
            """
        let reponse = try JSONDecoder().decode(ReponseQCM.self, from: Data(json.utf8))

        #expect(reponse.avertissement == "Le document ne permet de produire que 1 question.")
    }

    @Test func decodeUneErreur() throws {
        let json = #"{"code": "invalid_token", "message": "Jeton d'API absent ou invalide."}"#
        let erreur = try JSONDecoder().decode(ErreurAPI.self, from: Data(json.utf8))

        #expect(erreur == ErreurAPI(code: "invalid_token", message: "Jeton d'API absent ou invalide."))
        #expect(GenerationError(erreur: erreur) == .api(.jetonInvalide, message: "Jeton d'API absent ou invalide."))
    }

    @Test(arguments: codesDeLAPI)
    func traduitChaqueCodeDeLAPI(code: String, attendu: CodeErreurAPI) {
        #expect(CodeErreurAPI(code: code) == attendu)
    }

    @Test func chaqueCodeConnuEstCouvertParLesTests() {
        let couverts = Set(codesDeLAPI.map(\.1))
        #expect(couverts == Set(CodeErreurAPI.allCases).subtracting([.inconnu]))
        #expect(codesDeLAPI.count == 11)
    }

    @Test func unCodeInconnuGardeLeMessageDuServeur() {
        let erreur = ErreurAPI(code: "nouveau_code", message: "Message du serveur.")

        #expect(GenerationError(erreur: erreur) == .api(.inconnu, message: "Message du serveur."))
    }
}
