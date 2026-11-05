//
//  FileDeRevisionTests.swift
//  RevIA
//

import Foundation
import SwiftData
import Testing
@testable import RevIA

@MainActor
struct FileDeRevisionTests {
    let conteneur: ModelContainer
    var contexte: ModelContext { conteneur.mainContext }
    let reseaux = UE(nom: "Réseaux", couleur: .vert)
    let bdd = UE(nom: "Bases de données", couleur: .orange)
    let aujourdHui = date(2026, 11, 10, 9, 0)

    init() throws {
        conteneur = try StockageDonnees.conteneur(enMemoire: true)
        conteneur.mainContext.insert(reseaux)
        conteneur.mainContext.insert(bdd)
    }

    /// Ajoute un cours dont les questions reviennent aux jours indiqués (jour de novembre 2026).
    @discardableResult
    func cours(_ titre: String, ue: UE, jours: [Int]) -> Cours {
        let cours = Cours(titre: titre, ue: ue)
        contexte.insert(cours)
        cours.remplacerQuestions(par: ReponseQCM(qcm: jours.indices.map { qcm("\(titre) Q\($0 + 1)") }, avertissement: nil), dans: contexte)
        for (question, jour) in zip(cours.questionsOrdonnees, jours) {
            question.prochaineRevision = date(2026, 11, jour, 0, 0)
        }
        return cours
    }

    var toutes: [QuestionQCM] { (try? contexte.fetch(FetchDescriptor<QuestionQCM>())) ?? [] }

    @Test func gardeLesQuestionsDuJourEtEnRetardToutesUEConfondues() {
        cours("TCP", ue: reseaux, jours: [10, 11, 8])
        cours("SQL", ue: bdd, jours: [10, 25])

        let aRevoir = FileDeRevision.questionsARevoir(parmi: toutes, le: aujourdHui, calendrier: calendrierDeTest)

        #expect(Set(aRevoir.map(\.question)) == ["TCP Q1", "TCP Q3", "SQL Q1"])
        #expect(FileDeRevision.nombreARevoir(parmi: toutes, le: aujourdHui, calendrier: calendrierDeTest) == 3)
    }

    @Test func lesPlusEnRetardDAbordPuisParCoursEtOrdre() {
        cours("TCP", ue: reseaux, jours: [10, 10, 8])
        cours("ARP", ue: reseaux, jours: [10])

        let aRevoir = FileDeRevision.questionsARevoir(parmi: toutes, le: aujourdHui, calendrier: calendrierDeTest)

        #expect(aRevoir.map(\.question) == ["TCP Q3", "ARP Q1", "TCP Q1", "TCP Q2"])
    }

    @Test func uneQuestionDeDemainNEstPasARevoirMemeA23h59() {
        cours("TCP", ue: reseaux, jours: [11])

        #expect(FileDeRevision.questionsARevoir(parmi: toutes, le: date(2026, 11, 10, 23, 59), calendrier: calendrierDeTest).isEmpty)
        #expect(FileDeRevision.questionsARevoir(parmi: toutes, le: date(2026, 11, 11, 0, 1), calendrier: calendrierDeTest).count == 1)
    }

    @Test func repartitionParUEDeLaPlusChargee() {
        cours("TCP", ue: reseaux, jours: [10])
        cours("SQL", ue: bdd, jours: [9, 10])

        let parts = FileDeRevision.repartitionParUE(FileDeRevision.questionsARevoir(parmi: toutes, le: aujourdHui, calendrier: calendrierDeTest))

        #expect(parts == [
            FileDeRevision.PartUE(nom: "Bases de données", couleur: .orange, nombre: 2),
            FileDeRevision.PartUE(nom: "Réseaux", couleur: .vert, nombre: 1),
        ])
    }

    @Test func prochaineRevisionQuandIlNYARienARevoir() throws {
        cours("TCP", ue: reseaux, jours: [12, 12, 20])

        let prochaine = try #require(FileDeRevision.prochaineRevision(parmi: toutes, apres: aujourdHui, calendrier: calendrierDeTest))

        #expect(prochaine.jour == date(2026, 11, 12, 0, 0))
        #expect(prochaine.nombre == 2)
        #expect(FileDeRevision.libelleJour(prochaine.jour, depuis: aujourdHui, calendrier: calendrierDeTest) == "dans 2 jours")
    }

    @Test func libellesDesJours() {
        #expect(FileDeRevision.libelleJour(date(2026, 11, 11, 0, 0), depuis: date(2026, 11, 10, 23, 59), calendrier: calendrierDeTest) == "demain")
        #expect(FileDeRevision.libelleJour(date(2026, 11, 10, 0, 0), depuis: aujourdHui, calendrier: calendrierDeTest) == "aujourd'hui")
    }

    @Test func sansQuestionIlNYAPasDeProchaineRevision() {
        #expect(FileDeRevision.prochaineRevision(parmi: [], apres: aujourdHui, calendrier: calendrierDeTest) == nil)
    }
}
