//
//  LeitnerTests.swift
//  RevIA
//

import Foundation
import Testing
@testable import RevIA

@MainActor
struct LeitnerTests {

    @Test func cinqBoitesDe1A16Jours() {
        #expect(Leitner.intervalles == [1, 2, 4, 8, 16])
        #expect(Leitner.premiereBoite == 1)
        #expect(Leitner.derniereBoite == 5)
    }

    @Test(arguments: [(1, 6), (2, 7), (3, 9), (4, 13), (5, 21)])
    func prochaineRevisionSelonLaBoite(boite: Int, jourAttendu: Int) {
        let revision = Leitner.prochaineRevision(boite: boite, depuis: date(2026, 11, 5, 15, 30), calendrier: calendrierDeTest)

        #expect(revision == date(2026, 11, jourAttendu, 0, 0))
    }

    @Test func leCalculSeFaitEnJoursCalendairesEtNonEnHeures() {
        let tard = Leitner.prochaineRevision(boite: 1, depuis: date(2026, 11, 5, 23, 59), calendrier: calendrierDeTest)
        let tot = Leitner.prochaineRevision(boite: 1, depuis: date(2026, 11, 6, 0, 1), calendrier: calendrierDeTest)

        #expect(tard == date(2026, 11, 6, 0, 0))
        #expect(tot == date(2026, 11, 7, 0, 0))
    }

    @Test func traverseLeChangementDHeure() {
        // Passage à l'heure d'hiver le 25 octobre 2026 à Paris : la journée dure 25 heures
        let revision = Leitner.prochaineRevision(boite: 1, depuis: date(2026, 10, 24, 22, 0), calendrier: calendrierDeTest)

        #expect(revision == date(2026, 10, 25, 0, 0))
        #expect(Leitner.prochaineRevision(boite: 2, depuis: date(2026, 10, 24, 22, 0), calendrier: calendrierDeTest) == date(2026, 10, 26, 0, 0))
    }
}
