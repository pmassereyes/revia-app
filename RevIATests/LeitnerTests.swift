//
//  LeitnerTests.swift
//  RevIA
//

import Foundation
import SwiftData
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

/// Règles de Leitner décidées par l'utilisateur (CLAUDE.md), appliquées à une question.
@MainActor
struct ReponsesLeitnerTests {
    let jour = date(2026, 11, 5, 15, 0)

    func question(boite: Int = 1) -> QuestionQCM {
        let question = QuestionQCM(qcm: qcm("Q"), ordre: 0, prochaineRevision: jour)
        question.boite = boite
        return question
    }

    @Test func monteeDeLaBoite1ALaBoite5() {
        let question = question()
        var revisions: [Date] = []
        for _ in 1...4 {
            question.enregistrerReponse(correcte: true, le: jour, calendrier: calendrierDeTest)
            revisions.append(question.prochaineRevision)
        }

        #expect(question.boite == 5)
        // Boîtes 2, 3, 4 et 5 : J+2, J+4, J+8, J+16
        #expect(revisions == [date(2026, 11, 7, 0, 0), date(2026, 11, 9, 0, 0), date(2026, 11, 13, 0, 0), date(2026, 11, 21, 0, 0)])
    }

    @Test func uneBonneReponseEnBoite5YResteEtRevientA16Jours() {
        let question = question(boite: 5)

        question.enregistrerReponse(correcte: true, le: jour, calendrier: calendrierDeTest)

        #expect(question.boite == 5)
        #expect(question.prochaineRevision == date(2026, 11, 21, 0, 0))
    }

    @Test(arguments: 1...5)
    func uneErreurRenvoieEnBoite1PourLeLendemain(boite: Int) {
        let question = question(boite: boite)

        question.enregistrerReponse(correcte: false, le: jour, calendrier: calendrierDeTest)

        #expect(question.boite == 1)
        #expect(question.prochaineRevision == date(2026, 11, 6, 0, 0))
    }

    @Test func uneNouvelleQuestionEstEnBoite1EtRevientLeLendemain() {
        let cours = Cours(titre: "C")
        cours.remplacerQuestions(
            par: ReponseQCM(qcm: [qcm("Q")], avertissement: nil),
            dans: try! StockageDonnees.conteneur(enMemoire: true).mainContext,
            maintenant: jour,
            calendrier: calendrierDeTest
        )

        #expect(cours.questions.first?.boite == 1)
        #expect(cours.questions.first?.prochaineRevision == date(2026, 11, 6, 0, 0))
    }

    @Test func uneQuestionEstARevoirLeJourDeSaRevisionEtApres() {
        let question = question()
        question.prochaineRevision = date(2026, 11, 6, 0, 0)

        #expect(!question.estARevoir(le: date(2026, 11, 5, 23, 59), calendrier: calendrierDeTest))
        #expect(question.estARevoir(le: date(2026, 11, 6, 0, 1), calendrier: calendrierDeTest))
        #expect(question.estARevoir(le: date(2026, 11, 20, 9, 0), calendrier: calendrierDeTest))
    }
}
