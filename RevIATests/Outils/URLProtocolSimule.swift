//
//  URLProtocolSimule.swift
//  RevIA
//

import Foundation

/// Remplace le réseau dans les tests : renvoie la réponse préparée et garde les requêtes reçues.
/// L'état est partagé : les suites qui l'utilisent sont `.serialized`.
final class URLProtocolSimule: URLProtocol, @unchecked Sendable {
    typealias Gestionnaire = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) private static var gestionnaire: Gestionnaire?
    /// Requêtes reçues, avec leur corps recopié dans `httpBody`.
    nonisolated(unsafe) private(set) static var requetesRecues: [URLRequest] = []

    /// Une session dont toutes les requêtes passent par ce protocole.
    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolSimule.self]
        return URLSession(configuration: configuration)
    }

    static func reinitialiser() {
        gestionnaire = nil
        requetesRecues = []
    }

    static func repondre(statut: Int, corps: Data) {
        gestionnaire = { requete in
            let reponse = HTTPURLResponse(url: requete.url!, statusCode: statut, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (reponse, corps)
        }
    }

    static func echouer(avec erreur: URLError) {
        gestionnaire = { _ in throw erreur }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // Dans un URLProtocol, le corps n'arrive que sous forme de flux
        var requete = request
        requete.httpBody = Self.lireCorps(de: request)
        Self.requetesRecues.append(requete)

        guard let gestionnaire = Self.gestionnaire else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (reponse, donnees) = try gestionnaire(requete)
            client?.urlProtocol(self, didReceive: reponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: donnees)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func lireCorps(de requete: URLRequest) -> Data? {
        if let corps = requete.httpBody { return corps }
        guard let flux = requete.httpBodyStream else { return nil }
        flux.open()
        defer { flux.close() }
        var donnees = Data()
        var tampon = [UInt8](repeating: 0, count: 64 * 1024)
        while flux.hasBytesAvailable {
            let lus = flux.read(&tampon, maxLength: tampon.count)
            guard lus > 0 else { break }
            donnees.append(tampon, count: lus)
        }
        return donnees
    }
}
