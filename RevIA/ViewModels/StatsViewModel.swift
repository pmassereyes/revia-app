//
//  StatsViewModel.swift
//  RevIA
//

import Foundation

/// Statistiques calculées à partir des sessions terminées et de l'état de Leitner des questions.
struct StatsViewModel {
    struct Taux: Equatable, Identifiable {
        let libelle: String
        let bonnes: Int
        let total: Int
        var id: String { libelle }
        var valeur: Double { total == 0 ? 0 : Double(bonnes) / Double(total) }
    }

    struct PointEvolution: Equatable, Identifiable {
        let date: Date
        let taux: Double
        var id: Date { date }
    }

    struct Boite: Equatable, Identifiable {
        let numero: Int
        let nombre: Int
        var id: Int { numero }
    }

    let sessions: [SessionRevision]
    let questions: [QuestionQCM]

    var estVide: Bool { sessions.isEmpty }

    var nbReponses: Int { sessions.reduce(0) { $0 + $1.nbQuestions } }

    var tauxGlobal: Taux {
        Taux(libelle: "Global", bonnes: sessions.reduce(0) { $0 + $1.nbBonnesReponses }, total: nbReponses)
    }

    /// Taux de réussite par UE, par ordre alphabétique.
    var parUE: [Taux] {
        regrouper(par: { $0.nomUE.isEmpty ? "Sans UE" : $0.nomUE })
            .sorted { $0.libelle.localizedStandardCompare($1.libelle) == .orderedAscending }
    }

    /// Thèmes du plus faible au plus fort : les premiers sont à retravailler.
    var parTheme: [Taux] {
        regrouper(par: \.theme)
            .sorted { $0.valeur != $1.valeur ? $0.valeur < $1.valeur : $0.libelle < $1.libelle }
    }

    /// Nombre de questions dans chacune des 5 boîtes.
    var parBoite: [Boite] {
        (Leitner.premiereBoite...Leitner.derniereBoite).map { numero in
            Boite(numero: numero, nombre: questions.filter { $0.cours != nil && $0.boite == numero }.count)
        }
    }

    /// Score de chaque session, dans l'ordre chronologique.
    var evolution: [PointEvolution] {
        sessions
            .filter { $0.nbQuestions > 0 }
            .sorted { $0.date < $1.date }
            .map { PointEvolution(date: $0.date, taux: Double($0.nbBonnesReponses) / Double($0.nbQuestions)) }
    }

    private func regrouper(par cle: (ReponseSession) -> String) -> [Taux] {
        var bonnes: [String: Int] = [:]
        var totaux: [String: Int] = [:]
        for reponse in sessions.flatMap(\.reponses) {
            let libelle = cle(reponse)
            totaux[libelle, default: 0] += 1
            if reponse.correcte { bonnes[libelle, default: 0] += 1 }
        }
        return totaux.map { Taux(libelle: $0.key, bonnes: bonnes[$0.key] ?? 0, total: $0.value) }
    }
}
