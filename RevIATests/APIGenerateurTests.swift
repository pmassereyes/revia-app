//
//  APIGenerateurTests.swift
//  RevIA
//

import Foundation
import Testing
@testable import RevIA

private let configuration = ConfigurationAPI(urlDeBase: URL(string: "http://exemple.test:8000")!, jeton: "jeton-de-test")
private let pdf = Data("%PDF-1.7 contenu du cours".utf8)

/// Code d'erreur de l'API, statut HTTP associé, et cas attendu côté app.
private let erreursDeLAPI: [(String, Int, CodeErreurAPI)] = [
    ("invalid_token", 401, .jetonInvalide),
    ("invalid_pdf", 400, .pdfInvalide),
    ("pdf_too_large", 413, .pdfTropVolumineux),
    ("invalid_request", 422, .requeteInvalide),
    ("rate_limited", 429, .tropDeRequetes),
    ("quota_exceeded", 429, .quotaEpuise),
    ("provider_overloaded", 503, .iaSurchargee),
    ("provider_unavailable", 503, .iaIndisponible),
    ("generation_timeout", 504, .delaiDepasse),
    ("generation_failed", 502, .echecGeneration),
    ("internal_error", 500, .erreurInterne),
]

private func erreurJSON(code: String, message: String = "Message du serveur.") -> Data {
    Data(#"{"code": "\#(code)", "message": "\#(message)"}"#.utf8)
}

/// Construction de la requête, sans réseau.
struct RequeteQCMTests {

    @Test func laRequeteViseLaRouteAvecLeJetonEtUnDelaiDe300s() {
        let requete = APIGenerateur(configuration: configuration).construireRequete(pdf: pdf, nbQuestions: 12)

        #expect(requete.httpMethod == "POST")
        #expect(requete.url?.absoluteString == "http://exemple.test:8000/v1/qcm")
        #expect(requete.value(forHTTPHeaderField: "X-API-Token") == "jeton-de-test")
        #expect(requete.timeoutInterval == 300)
    }

    @Test func uneAdresseTermineeParUnSlashDonneLaMemeRoute() {
        let avecSlash = ConfigurationAPI(urlDeBase: URL(string: "http://exemple.test:8000/")!, jeton: "j")
        let requete = APIGenerateur(configuration: avecSlash).construireRequete(pdf: pdf, nbQuestions: 1)

        #expect(requete.url?.absoluteString == "http://exemple.test:8000/v1/qcm")
    }

    @Test func leCorpsMultipartContientLeNombreDeQuestionsPuisLePDF() throws {
        var corps = CorpsMultipart(frontiere: "FRONTIERE")
        corps.ajouterChamp("nb_questions", valeur: "12")
        corps.ajouterFichier("file", nomDeFichier: "cours.pdf", typeMIME: "application/pdf", contenu: pdf)

        let entete: [String] = [
            "--FRONTIERE",
            "Content-Disposition: form-data; name=\"nb_questions\"",
            "",
            "12",
            "--FRONTIERE",
            "Content-Disposition: form-data; name=\"file\"; filename=\"cours.pdf\"",
            "Content-Type: application/pdf",
            "",
            "",
        ]
        var attendu = Data(entete.joined(separator: "\r\n").utf8)
        attendu.append(pdf)
        attendu.append(Data("\r\n--FRONTIERE--\r\n".utf8))

        #expect(corps.typeDeContenu == "multipart/form-data; boundary=FRONTIERE")
        #expect(corps.donneesFinales() == attendu)
    }
}

/// Échanges avec un serveur simulé. Sérialisés, car la simulation est partagée.
@Suite(.serialized)
struct APIGenerateurTests {
    let generateur = APIGenerateur(configuration: configuration, session: URLProtocolSimule.session())

    init() {
        URLProtocolSimule.reinitialiser()
    }

    @Test func envoieLeFormulaireAttenduParLAPI() async throws {
        URLProtocolSimule.repondre(statut: 200, corps: try fixture("reponse_exemple"))

        _ = try await generateur.generer(pdf: pdf, nbQuestions: 12)

        #expect(URLProtocolSimule.requetesRecues.count == 1)
        let requete = try #require(URLProtocolSimule.requetesRecues.first)
        #expect(requete.value(forHTTPHeaderField: "X-API-Token") == "jeton-de-test")
        let typeDeContenu = try #require(requete.value(forHTTPHeaderField: "Content-Type"))
        #expect(typeDeContenu.hasPrefix("multipart/form-data; boundary="))
        let frontiere = String(typeDeContenu.dropFirst("multipart/form-data; boundary=".count))
        let corps = try #require(requete.httpBody)
        let texte = String(decoding: corps, as: UTF8.self)
        #expect(texte.hasPrefix("--\(frontiere)\r\n"))
        #expect(texte.contains("name=\"nb_questions\"\r\n\r\n12\r\n"))
        #expect(texte.contains("name=\"file\"; filename=\"cours.pdf\"\r\nContent-Type: application/pdf\r\n\r\n%PDF-1.7 contenu du cours\r\n"))
        #expect(texte.hasSuffix("--\(frontiere)--\r\n"))
    }

    @Test func decodeLeQCMRecu() async throws {
        URLProtocolSimule.repondre(statut: 200, corps: try fixture("reponse_exemple"))

        let reponse = try await generateur.generer(pdf: pdf, nbQuestions: 10)

        #expect(reponse == (try JSONDecoder().decode(ReponseQCM.self, from: fixture("reponse_exemple"))))
    }

    @Test(arguments: erreursDeLAPI)
    func traduitLErreurRenvoyeeParLAPI(code: String, statut: Int, attendu: CodeErreurAPI) async {
        URLProtocolSimule.repondre(statut: statut, corps: erreurJSON(code: code))

        await #expect(throws: GenerationError.api(attendu, message: "Message du serveur.")) {
            try await generateur.generer(pdf: pdf, nbQuestions: 10)
        }
    }

    @Test func unCodeInconnuGardeLeMessageDuServeur() async {
        URLProtocolSimule.repondre(statut: 418, corps: erreurJSON(code: "nouveau_code", message: "Nouveau cas."))

        await #expect(throws: GenerationError.api(.inconnu, message: "Nouveau cas.")) {
            try await generateur.generer(pdf: pdf, nbQuestions: 10)
        }
    }

    @Test func uneReponseNonJSONEstUneErreurReseau() async {
        URLProtocolSimule.repondre(statut: 502, corps: Data("<html>Bad Gateway</html>".utf8))

        await #expect(throws: GenerationError.reseau) {
            try await generateur.generer(pdf: pdf, nbQuestions: 10)
        }
    }

    @Test func unSuccesIllisibleEstUneErreurReseau() async {
        URLProtocolSimule.repondre(statut: 200, corps: Data(#"{"inattendu": true}"#.utf8))

        await #expect(throws: GenerationError.reseau) {
            try await generateur.generer(pdf: pdf, nbQuestions: 10)
        }
    }

    @Test func uneCoupureReseauEstUneErreurReseau() async {
        URLProtocolSimule.echouer(avec: URLError(.notConnectedToInternet))

        await #expect(throws: GenerationError.reseau) {
            try await generateur.generer(pdf: pdf, nbQuestions: 10)
        }
    }

    @Test func unPDFDePlusDe20MoEstRefuseSansRienEnvoyer() async {
        URLProtocolSimule.repondre(statut: 200, corps: Data())
        let tropGros = Data(count: 20 * 1024 * 1024 + 1)

        await #expect(throws: GenerationError.pdfTropVolumineux) {
            try await generateur.generer(pdf: tropGros, nbQuestions: 10)
        }
        #expect(URLProtocolSimule.requetesRecues.isEmpty)
    }

    @Test func unPDFDeExactement20MoEstEnvoye() async throws {
        URLProtocolSimule.repondre(statut: 200, corps: try fixture("reponse_exemple"))
        let limite = Data(count: 20 * 1024 * 1024)

        _ = try await generateur.generer(pdf: limite, nbQuestions: 10)

        #expect(URLProtocolSimule.requetesRecues.count == 1)
    }
}
