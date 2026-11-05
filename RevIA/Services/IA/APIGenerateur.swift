//
//  APIGenerateur.swift
//  RevIA
//

import Foundation

/// Génère les QCM en appelant `POST /v1/qcm` sur revia-api.
nonisolated struct APIGenerateur: GenerateurQCM {
    /// Même limite que l'API. Vérifiée avant l'envoi, pour éviter un refus après un long upload.
    static let tailleMaximalePDF = 20 * 1024 * 1024
    /// La génération prend de 20 à 45 s, et jusqu'à environ 4 min dans le pire cas côté API.
    static let delaiMaximal: TimeInterval = 300

    let configuration: ConfigurationAPI
    let session: URLSession

    init(configuration: ConfigurationAPI, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func generer(pdf: Data, nbQuestions: Int) async throws(GenerationError) -> ReponseQCM {
        guard pdf.count <= Self.tailleMaximalePDF else { throw .pdfTropVolumineux }

        let donnees: Data
        let reponse: URLResponse
        do {
            (donnees, reponse) = try await session.data(for: construireRequete(pdf: pdf, nbQuestions: nbQuestions))
        } catch {
            throw .reseau
        }
        return try Self.interpreter(donnees: donnees, reponse: reponse)
    }

    func construireRequete(pdf: Data, nbQuestions: Int) -> URLRequest {
        var requete = URLRequest(
            url: configuration.urlDeBase.appending(path: "v1/qcm"),
            timeoutInterval: Self.delaiMaximal
        )
        requete.httpMethod = "POST"
        requete.setValue(configuration.jeton, forHTTPHeaderField: "X-API-Token")

        var corps = CorpsMultipart()
        // Champ du formulaire en snake_case, contrairement au JSON de la réponse
        corps.ajouterChamp("nb_questions", valeur: String(nbQuestions))
        corps.ajouterFichier("file", nomDeFichier: "cours.pdf", typeMIME: "application/pdf", contenu: pdf)
        requete.setValue(corps.typeDeContenu, forHTTPHeaderField: "Content-Type")
        requete.httpBody = corps.donneesFinales()
        return requete
    }

    /// Une réponse qui n'est pas du JSON attendu (proxy, serveur arrêté) compte comme une erreur réseau.
    static func interpreter(donnees: Data, reponse: URLResponse) throws(GenerationError) -> ReponseQCM {
        guard let http = reponse as? HTTPURLResponse else { throw .reseau }
        let decodeur = JSONDecoder()
        if http.statusCode == 200 {
            guard let qcm = try? decodeur.decode(ReponseQCM.self, from: donnees) else { throw .reseau }
            return qcm
        }
        guard let erreur = try? decodeur.decode(ErreurAPI.self, from: donnees) else { throw .reseau }
        throw GenerationError(erreur: erreur)
    }
}

/// Corps `multipart/form-data`, que `URLSession` ne sait pas construire.
nonisolated struct CorpsMultipart {
    let frontiere: String
    private var donnees = Data()

    init(frontiere: String = "RevIA-\(UUID().uuidString)") {
        self.frontiere = frontiere
    }

    var typeDeContenu: String { "multipart/form-data; boundary=\(frontiere)" }

    mutating func ajouterChamp(_ nom: String, valeur: String) {
        ajouter("--\(frontiere)\r\n")
        ajouter("Content-Disposition: form-data; name=\"\(nom)\"\r\n\r\n")
        ajouter("\(valeur)\r\n")
    }

    mutating func ajouterFichier(_ nom: String, nomDeFichier: String, typeMIME: String, contenu: Data) {
        ajouter("--\(frontiere)\r\n")
        ajouter("Content-Disposition: form-data; name=\"\(nom)\"; filename=\"\(nomDeFichier)\"\r\n")
        ajouter("Content-Type: \(typeMIME)\r\n\r\n")
        donnees.append(contenu)
        ajouter("\r\n")
    }

    /// Le corps, terminé par la frontière de fin.
    func donneesFinales() -> Data {
        var resultat = donnees
        resultat.append(Data("--\(frontiere)--\r\n".utf8))
        return resultat
    }

    private mutating func ajouter(_ texte: String) {
        donnees.append(Data(texte.utf8))
    }
}
