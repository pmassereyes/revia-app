//
//  QuizViewModelTests.swift
//  RevIA
//

import Foundation
import SwiftData
import Testing
@testable import RevIA

@MainActor
struct QuizViewModelTests {
    let conteneur: ModelContainer
    var contexte: ModelContext { conteneur.mainContext }
    let cours: Cours
    let jour = date(2026, 11, 5, 15, 0)

    init() throws {
        conteneur = try StockageDonnees.conteneur(enMemoire: true)
        let ue = UE(nom: "Réseaux")
        cours = Cours(titre: "TCP/IP", ue: ue)
        conteneur.mainContext.insert(ue)
        conteneur.mainContext.insert(cours)
        // Bonne réponse : proposition 2 (« C »)
        cours.remplacerQuestions(
            par: ReponseQCM(qcm: [qcm("Q1", theme: "Transport"), qcm("Q2", theme: "Routage"), qcm("Q3", theme: "Transport")], avertissement: nil),
            dans: conteneur.mainContext,
            maintenant: date(2026, 11, 1),
            calendrier: calendrierDeTest
        )
    }

    func viewModel() -> QuizViewModel {
        QuizViewModel(questions: cours.questionsOrdonnees, perimetre: .cours, titre: cours.titre, maintenant: { jour }, calendrier: calendrierDeTest)
    }

    @Test func uneReponseEstCorrigeeEtMetAJourLaBoite() throws {
        let vm = viewModel()

        vm.repondre(2, contexte: contexte)

        let reponse = try #require(vm.reponseCourante)
        #expect(reponse.correcte)
        #expect(vm.questionCourante?.boite == 2)
        #expect(vm.questionCourante?.prochaineRevision == date(2026, 11, 7, 0, 0))
    }

    @Test func uneMauvaiseReponseRenvoieEnBoite1() {
        let vm = viewModel()

        vm.repondre(0, contexte: contexte)

        #expect(vm.reponseCourante?.correcte == false)
        #expect(vm.questionCourante?.boite == 1)
        #expect(vm.questionCourante?.prochaineRevision == date(2026, 11, 6, 0, 0))
    }

    @Test func onNeRepondQuUneFoisParQuestion() {
        let vm = viewModel()

        vm.repondre(0, contexte: contexte)
        vm.repondre(2, contexte: contexte)

        #expect(vm.reponses.count == 1)
        #expect(vm.reponseCourante?.choix == 0)
    }

    @Test func onNePassePasALaSuiteSansRepondre() {
        let vm = viewModel()

        vm.continuer(contexte: contexte)

        #expect(vm.index == 0)
    }

    @Test func unQuizCompletDonneLeScoreLesErreursEtUneSession() throws {
        let vm = viewModel()
        for choix in [2, 0, 2] {
            vm.repondre(choix, contexte: contexte)
            vm.continuer(contexte: contexte)
        }

        #expect(vm.termine)
        #expect(vm.score == 2)
        #expect(vm.erreurs.map(\.question.question) == ["Q2"])

        let sessions = try contexte.fetch(FetchDescriptor<SessionRevision>())
        let session = try #require(sessions.first)
        #expect(sessions.count == 1)
        #expect(session.perimetre == .cours)
        #expect(session.titre == "TCP/IP")
        #expect(session.date == jour)
        #expect(session.nbQuestions == 3)
        #expect(session.nbBonnesReponses == 2)
        #expect(session.reponses == [
            ReponseSession(theme: "Transport", nomUE: "Réseaux", correcte: true),
            ReponseSession(theme: "Routage", nomUE: "Réseaux", correcte: false),
            ReponseSession(theme: "Transport", nomUE: "Réseaux", correcte: true),
        ])
    }

    @Test func quitterAvantLaFinGardeLesBoitesSansEnregistrerDeSession() throws {
        let vm = viewModel()
        vm.repondre(2, contexte: contexte)

        #expect(cours.questionsOrdonnees[0].boite == 2)
        #expect(try contexte.fetchCount(FetchDescriptor<SessionRevision>()) == 0)
    }

    @Test func unQuizSansQuestionEstTermine() {
        #expect(QuizViewModel(questions: [], perimetre: .aRevoir, titre: "À revoir").termine)
    }
}
