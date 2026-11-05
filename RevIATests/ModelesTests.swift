//
//  ModelesTests.swift
//  RevIA
//

import Foundation
import SwiftData
import Testing
@testable import RevIA

func qcm(_ question: String, theme: String = "Réseaux") -> QCM {
    QCM(question: question, propositions: ["A", "B", "C", "D"], indexBonneReponse: 2, explication: "Parce que C.", theme: theme)
}

@MainActor
struct ModelesTests {
    let conteneur: ModelContainer
    var contexte: ModelContext { conteneur.mainContext }

    init() throws {
        conteneur = try StockageDonnees.conteneur(enMemoire: true)
    }

    func nombre<T: PersistentModel>(_: T.Type) throws -> Int {
        try contexte.fetchCount(FetchDescriptor<T>())
    }

    @Test func laConversionGardeLOrdreEtLeContenuDesQuestions() throws {
        let cours = Cours(titre: "TCP/IP")
        contexte.insert(cours)
        let reponse = ReponseQCM(qcm: (1...5).map { qcm("Question \($0)") }, avertissement: nil)

        cours.remplacerQuestions(par: reponse, dans: contexte)
        try contexte.save()

        #expect(cours.questionsOrdonnees.map(\.question) == (1...5).map { "Question \($0)" })
        let premiere = try #require(cours.questionsOrdonnees.first)
        #expect(premiere.propositions == ["A", "B", "C", "D"])
        #expect(premiere.bonneReponse == "C")
        #expect(premiere.explication == "Parce que C.")
        #expect(premiere.theme == "Réseaux")
        #expect(cours.statut == .terminee)
    }

    @Test func lesNouvellesQuestionsSontEnBoite1EtReviennentLeLendemain() throws {
        let cours = Cours(titre: "TCP/IP")
        contexte.insert(cours)

        cours.remplacerQuestions(
            par: ReponseQCM(qcm: [qcm("Q")], avertissement: nil),
            dans: contexte,
            maintenant: date(2026, 11, 5, 23, 59),
            calendrier: calendrierDeTest
        )

        let question = try #require(cours.questions.first)
        #expect(question.boite == 1)
        #expect(question.prochaineRevision == date(2026, 11, 6, 0, 0))
    }

    @Test func regenererRemplaceLesQuestionsEtEffaceLEchecPrecedent() throws {
        let cours = Cours(titre: "TCP/IP")
        contexte.insert(cours)
        cours.statut = .echec
        cours.codeErreur = "generation_failed"
        cours.messageErreur = "Échec"
        cours.remplacerQuestions(par: ReponseQCM(qcm: [qcm("Ancienne")], avertissement: nil), dans: contexte)
        try contexte.save()

        cours.remplacerQuestions(
            par: ReponseQCM(qcm: [qcm("Nouvelle 1"), qcm("Nouvelle 2")], avertissement: "Seulement 2 questions."),
            dans: contexte
        )
        try contexte.save()

        #expect(try nombre(QuestionQCM.self) == 2)
        #expect(cours.questionsOrdonnees.map(\.question) == ["Nouvelle 1", "Nouvelle 2"])
        #expect(cours.avertissement == "Seulement 2 questions.")
        #expect(cours.codeErreur == nil)
        #expect(cours.messageErreur == nil)
    }

    @Test func supprimerUneUESupprimeSesCoursEtLeursQuestions() throws {
        let ue = UE(nom: "Réseaux")
        contexte.insert(ue)
        for titre in ["Cours 1", "Cours 2"] {
            let cours = Cours(titre: titre, ue: ue)
            contexte.insert(cours)
            cours.remplacerQuestions(par: ReponseQCM(qcm: [qcm("Q1"), qcm("Q2")], avertissement: nil), dans: contexte)
        }
        try contexte.save()
        #expect(try nombre(Cours.self) == 2)
        #expect(try nombre(QuestionQCM.self) == 4)

        contexte.delete(ue)
        try contexte.save()

        #expect(try nombre(UE.self) == 0)
        #expect(try nombre(Cours.self) == 0)
        #expect(try nombre(QuestionQCM.self) == 0)
    }

    @Test func supprimerUnCoursGardeLUEEtLesAutresCours() throws {
        let ue = UE(nom: "Réseaux")
        contexte.insert(ue)
        let conserve = Cours(titre: "Gardé", ue: ue)
        let supprime = Cours(titre: "Supprimé", ue: ue)
        contexte.insert(conserve)
        contexte.insert(supprime)
        supprime.remplacerQuestions(par: ReponseQCM(qcm: [qcm("Q")], avertissement: nil), dans: contexte)
        try contexte.save()

        contexte.delete(supprime)
        try contexte.save()

        #expect(try nombre(UE.self) == 1)
        #expect(ue.cours.map(\.titre) == ["Gardé"])
        #expect(try nombre(QuestionQCM.self) == 0)
    }

    @Test func leStatutEtLaCouleurSeRelisent() {
        let cours = Cours(titre: "TCP/IP")
        #expect(cours.statut == .jamaisGeneree)
        cours.statut = .enCours
        #expect(cours.statutBrut == "enCours")

        let ue = UE(nom: "Réseaux", couleur: .violet)
        #expect(ue.couleur == .violet)
        ue.couleurBrute = "inconnue"
        #expect(ue.couleur == .bleu)
    }
}

@MainActor
struct BibliothequeViewModelTests {
    let conteneur: ModelContainer
    var contexte: ModelContext { conteneur.mainContext }
    let viewModel = BibliothequeViewModel()

    init() throws {
        conteneur = try StockageDonnees.conteneur(enMemoire: true)
    }

    @Test func ajouteUneUE() throws {
        let ue = try #require(viewModel.ajouterUE(nom: "  Réseaux  ", couleur: .vert, contexte: contexte))

        #expect(ue.nom == "Réseaux")
        #expect(ue.couleur == .vert)
        #expect(try contexte.fetchCount(FetchDescriptor<UE>()) == 1)
        #expect(viewModel.messageErreur == nil)
    }

    @Test func refuseUnNomVide() throws {
        #expect(viewModel.ajouterUE(nom: "   ", couleur: .bleu, contexte: contexte) == nil)
        #expect(viewModel.messageErreur == "Donnez un nom à l'UE.")
        #expect(try contexte.fetchCount(FetchDescriptor<UE>()) == 0)
    }

    @Test func refuseUnNomDejaPrisSansTenirCompteDeLaCasseNiDesAccents() throws {
        viewModel.ajouterUE(nom: "Réseaux", couleur: .bleu, contexte: contexte)

        #expect(viewModel.ajouterUE(nom: "RESEAUX", couleur: .rouge, contexte: contexte) == nil)
        #expect(viewModel.messageErreur == "Une UE porte déjà ce nom.")
        #expect(try contexte.fetchCount(FetchDescriptor<UE>()) == 1)
    }

    @Test func supprimeUneUEEtSesCours() throws {
        let ue = try #require(viewModel.ajouterUE(nom: "Réseaux", couleur: .bleu, contexte: contexte))
        contexte.insert(Cours(titre: "TCP", ue: ue))
        try contexte.save()

        viewModel.supprimer(ue, contexte: contexte)

        #expect(try contexte.fetchCount(FetchDescriptor<UE>()) == 0)
        #expect(try contexte.fetchCount(FetchDescriptor<Cours>()) == 0)
    }
}
