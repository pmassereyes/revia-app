//
//  StatsViewModelTests.swift
//  RevIA
//

import Foundation
import SwiftData
import Testing
@testable import RevIA

@MainActor
struct StatsViewModelTests {
    let sessions = [
        SessionRevision(date: date(2026, 11, 2), perimetre: .cours, titre: "TCP", reponses: [
            ReponseSession(theme: "Transport", nomUE: "Réseaux", correcte: true),
            ReponseSession(theme: "Transport", nomUE: "Réseaux", correcte: false),
            ReponseSession(theme: "Routage", nomUE: "Réseaux", correcte: false),
        ]),
        SessionRevision(date: date(2026, 11, 1), perimetre: .aRevoir, titre: "À revoir aujourd'hui", reponses: [
            ReponseSession(theme: "Jointures", nomUE: "Bases de données", correcte: true),
            ReponseSession(theme: "Transport", nomUE: "Réseaux", correcte: true),
        ]),
    ]

    @Test func resumeGlobal() {
        let stats = StatsViewModel(sessions: sessions, questions: [])

        #expect(!stats.estVide)
        #expect(stats.nbReponses == 5)
        #expect(stats.tauxGlobal.bonnes == 3)
        #expect(stats.tauxGlobal.valeur == 0.6)
    }

    @Test func tauxParUEParOrdreAlphabetique() {
        let stats = StatsViewModel(sessions: sessions, questions: [])

        #expect(stats.parUE == [
            StatsViewModel.Taux(libelle: "Bases de données", bonnes: 1, total: 1),
            StatsViewModel.Taux(libelle: "Réseaux", bonnes: 2, total: 4),
        ])
    }

    @Test func themesDuPlusFaibleAuPlusFort() {
        let stats = StatsViewModel(sessions: sessions, questions: [])

        #expect(stats.parTheme.map(\.libelle) == ["Routage", "Transport", "Jointures"])
        #expect(stats.parTheme.map(\.valeur) == [0, 2.0 / 3.0, 1])
    }

    @Test func evolutionDansLOrdreChronologique() {
        let stats = StatsViewModel(sessions: sessions, questions: [])

        #expect(stats.evolution == [
            StatsViewModel.PointEvolution(date: date(2026, 11, 1), taux: 1),
            StatsViewModel.PointEvolution(date: date(2026, 11, 2), taux: 1.0 / 3.0),
        ])
    }

    @Test func questionsParBoite() throws {
        // Le conteneur doit rester en vie tant que ses objets servent
        let conteneur = try StockageDonnees.conteneur(enMemoire: true)
        defer { withExtendedLifetime(conteneur) {} }
        let contexte = conteneur.mainContext
        let cours = Cours(titre: "TCP")
        contexte.insert(cours)
        cours.remplacerQuestions(par: ReponseQCM(qcm: (1...4).map { qcm("Q\($0)") }, avertissement: nil), dans: contexte)
        let questions = cours.questionsOrdonnees
        questions[1].boite = 3
        questions[2].boite = 5
        questions[3].boite = 5

        let stats = StatsViewModel(sessions: [], questions: questions)

        #expect(stats.parBoite.map(\.nombre) == [1, 0, 1, 0, 2])
        #expect(stats.estVide)
    }
}
