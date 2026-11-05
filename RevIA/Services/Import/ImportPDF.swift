//
//  ImportPDF.swift
//  RevIA
//

import Foundation

/// PDF des cours, copiés dans le dossier de l'app. Un cours ne garde que le nom du fichier.
nonisolated struct StockagePDF: Sendable {
    let dossier: URL

    static var standard: StockagePDF {
        StockagePDF(dossier: URL.applicationSupportDirectory.appending(path: "Cours", directoryHint: .isDirectory))
    }

    /// Copie le PDF choisi par l'utilisateur et renvoie le nom du fichier créé.
    /// Refuse ce que l'API refuserait : un fichier qui n'est pas un PDF, ou de plus de 20 Mo.
    func importer(depuis source: URL) throws(ErreurImport) -> String {
        // URL hors du bac à sable, fournie par le sélecteur de fichiers
        let acces = source.startAccessingSecurityScopedResource()
        defer { if acces { source.stopAccessingSecurityScopedResource() } }

        guard let taille = try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize else { throw .lectureImpossible }
        guard taille <= APIGenerateur.tailleMaximalePDF else { throw .tropVolumineux }
        guard Self.commenceParLEnTetePDF(source) else { throw .pasUnPDF }

        let nom = "\(UUID().uuidString).pdf"
        do {
            try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: source, to: url(de: nom))
        } catch {
            throw .copieImpossible
        }
        return nom
    }

    func url(de nom: String) -> URL {
        dossier.appending(path: nom)
    }

    func donnees(de nom: String) throws -> Data {
        try Data(contentsOf: url(de: nom))
    }

    func supprimer(_ nom: String) {
        try? FileManager.default.removeItem(at: url(de: nom))
    }

    private static func commenceParLEnTetePDF(_ url: URL) -> Bool {
        guard let fichier = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? fichier.close() }
        return (try? fichier.read(upToCount: 5)) == Data("%PDF-".utf8)
    }
}

nonisolated enum ErreurImport: Error, Equatable {
    case lectureImpossible, pasUnPDF, tropVolumineux, copieImpossible

    var message: String {
        switch self {
        case .lectureImpossible: "Le fichier n'a pas pu être lu."
        case .pasUnPDF: "Ce fichier n'est pas un PDF."
        case .tropVolumineux: "Ce PDF dépasse 20 Mo, la taille maximale acceptée pour générer un QCM."
        case .copieImpossible: "Le PDF n'a pas pu être copié dans l'app."
        }
    }
}
