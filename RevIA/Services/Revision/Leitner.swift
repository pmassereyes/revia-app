//
//  Leitner.swift
//  RevIA
//

import Foundation

/// Répétition espacée à 5 boîtes. Les dates se comptent en jours calendaires (fuseau local, début de journée).
nonisolated enum Leitner {
    /// Délai, en jours, avant la prochaine révision d'une question de la boîte 1, 2, 3, 4 ou 5.
    static let intervalles = [1, 2, 4, 8, 16]
    static let premiereBoite = 1
    static var derniereBoite: Int { intervalles.count }

    /// Début du jour où une question de cette boîte revient, à compter de `date`.
    static func prochaineRevision(boite: Int, depuis date: Date, calendrier: Calendar = .current) -> Date {
        let boite = min(max(boite, premiereBoite), derniereBoite)
        let debutDuJour = calendrier.startOfDay(for: date)
        return calendrier.date(byAdding: .day, value: intervalles[boite - 1], to: debutDuJour) ?? debutDuJour
    }
}
