//
//  FileDeRevision.swift
//  RevIA
//

import Foundation

/// Questions à revoir, toutes UE confondues.
enum FileDeRevision {
    struct PartUE: Equatable {
        let nom: String
        let couleur: CouleurUE
        let nombre: Int
    }

    /// Questions dont le jour de révision est `date` ou passé : les plus en retard d'abord,
    /// puis par cours et dans l'ordre du QCM.
    static func questionsARevoir(parmi questions: [QuestionQCM], le date: Date, calendrier: Calendar = .current) -> [QuestionQCM] {
        questions
            .filter { $0.cours != nil && $0.estARevoir(le: date, calendrier: calendrier) }
            .sorted { a, b in
                if a.prochaineRevision != b.prochaineRevision { return a.prochaineRevision < b.prochaineRevision }
                let coursA = a.cours?.titre ?? "", coursB = b.cours?.titre ?? ""
                if coursA != coursB { return coursA.localizedStandardCompare(coursB) == .orderedAscending }
                return a.ordre < b.ordre
            }
    }

    /// Nombre de questions par UE, de la plus chargée à la moins chargée.
    static func repartitionParUE(_ questions: [QuestionQCM]) -> [PartUE] {
        var parts: [String: PartUE] = [:]
        for question in questions {
            let ue = question.cours?.ue
            let nom = ue?.nom ?? "Sans UE"
            let actuelle = parts[nom]?.nombre ?? 0
            parts[nom] = PartUE(nom: nom, couleur: ue?.couleur ?? .gris, nombre: actuelle + 1)
        }
        return parts.values.sorted { $0.nombre != $1.nombre ? $0.nombre > $1.nombre : $0.nom < $1.nom }
    }

    /// Premier jour, après `date`, où des questions seront à revoir, avec leur nombre.
    static func prochaineRevision(parmi questions: [QuestionQCM], apres date: Date, calendrier: Calendar = .current) -> (jour: Date, nombre: Int)? {
        let aujourdHui = calendrier.startOfDay(for: date)
        let jours = questions
            .filter { $0.cours != nil }
            .map { calendrier.startOfDay(for: $0.prochaineRevision) }
            .filter { $0 > aujourdHui }
        guard let premier = jours.min() else { return nil }
        return (premier, jours.filter { $0 == premier }.count)
    }

    /// « demain », « dans 3 jours », compté en jours calendaires.
    static func libelleJour(_ jour: Date, depuis date: Date, calendrier: Calendar = .current) -> String {
        let ecart = calendrier.dateComponents([.day], from: calendrier.startOfDay(for: date), to: calendrier.startOfDay(for: jour)).day ?? 0
        switch ecart {
        case ...0: return "aujourd'hui"
        case 1: return "demain"
        default: return "dans \(ecart) jours"
        }
    }

    /// Nombre de questions à revoir le `date`, pour le badge de l'onglet.
    static func nombreARevoir(parmi questions: [QuestionQCM], le date: Date, calendrier: Calendar = .current) -> Int {
        questions.filter { $0.cours != nil && $0.estARevoir(le: date, calendrier: calendrier) }.count
    }
}
