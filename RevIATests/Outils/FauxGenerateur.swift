//
//  FauxGenerateur.swift
//  RevIA
//

import Foundation
@testable import RevIA

/// Générateur de test : renvoie le résultat prévu et note ce qu'il a reçu.
final class FauxGenerateur: GenerateurQCM, @unchecked Sendable {
    let resultat: Result<ReponseQCM, GenerationError>
    private(set) var pdfRecu: Data?
    private(set) var nbQuestionsRecu: Int?

    init(_ resultat: Result<ReponseQCM, GenerationError>) {
        self.resultat = resultat
    }

    func generer(pdf: Data, nbQuestions: Int) async throws(GenerationError) -> ReponseQCM {
        pdfRecu = pdf
        nbQuestionsRecu = nbQuestions
        return try resultat.get()
    }
}

/// Dossier de PDF propre à un test.
func stockageTemporaire() -> StockagePDF {
    StockagePDF(dossier: FileManager.default.temporaryDirectory.appending(path: "RevIA-tests-\(UUID().uuidString)", directoryHint: .isDirectory))
}

/// Fichier source, comme ceux que renvoie le sélecteur de fichiers.
func fichierSource(_ contenu: Data, nom: String = "Cours TCP.pdf") throws -> URL {
    let dossier = FileManager.default.temporaryDirectory.appending(path: "RevIA-sources-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
    let url = dossier.appending(path: nom)
    try contenu.write(to: url)
    return url
}

let contenuPDF = Data("%PDF-1.7\ncontenu du cours".utf8)
