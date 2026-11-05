//
//  NotificationsTests.swift
//  RevIA
//

import Foundation
import Testing
import UserNotifications
@testable import RevIA

@MainActor
struct NotificationsTests {
    let dixHuitHeures = 18 * 60

    func jours(_ jours: [Int]) -> [Date] {
        jours.map { date(2026, 11, $0, 0, 0) }
    }

    @Test func unRappelParJourAPartirDuPremierJourDeRevisionAvecLeCumulDesRetards() {
        let rappels = Notifications.rappels(pour: jours([12, 10, 12]), a: dixHuitHeures, maintenant: date(2026, 11, 10, 9, 0), calendrier: calendrierDeTest)

        #expect(rappels.first == Notifications.Rappel(declenchement: date(2026, 11, 10, 18, 0), nombre: 1))
        #expect(rappels.prefix(3).map(\.nombre) == [1, 1, 3])
        // Du 10 au 23 novembre : 14 jours
        #expect(rappels.count == Notifications.horizon)
        #expect(rappels.last?.declenchement == date(2026, 11, 23, 18, 0))
    }

    @Test func pasDeRappelLesJoursSansQuestion() {
        let rappels = Notifications.rappels(pour: jours([13]), a: dixHuitHeures, maintenant: date(2026, 11, 10, 9, 0), calendrier: calendrierDeTest)

        #expect(rappels.first?.declenchement == date(2026, 11, 13, 18, 0))
    }

    @Test func uneHeureDejaPasseeNeDeclenchePlusRienAujourdHui() {
        let rappels = Notifications.rappels(pour: jours([10]), a: dixHuitHeures, maintenant: date(2026, 11, 10, 19, 0), calendrier: calendrierDeTest)

        #expect(rappels.first?.declenchement == date(2026, 11, 11, 18, 0))
    }

    @Test func rienAuDelaDeLHorizonNiSansQuestion() {
        #expect(Notifications.rappels(pour: jours([28]), a: dixHuitHeures, maintenant: date(2026, 11, 10, 9, 0), calendrier: calendrierDeTest).isEmpty)
        #expect(Notifications.rappels(pour: [], a: dixHuitHeures, maintenant: date(2026, 11, 10, 9, 0), calendrier: calendrierDeTest).isEmpty)
    }

    @Test func contenuEtDeclencheurDeLaNotification() throws {
        let requete = Notifications.requete(
            pour: Notifications.Rappel(declenchement: date(2026, 11, 12, 18, 30), nombre: 3),
            calendrier: calendrierDeTest
        )

        #expect(requete.identifier.hasPrefix(Notifications.prefixe))
        #expect(requete.content.body == "3 questions à revoir aujourd'hui.")
        let declencheur = try #require(requete.trigger as? UNCalendarNotificationTrigger)
        #expect(!declencheur.repeats)
        #expect(declencheur.dateComponents.day == 12)
        #expect(declencheur.dateComponents.hour == 18)
        #expect(declencheur.dateComponents.minute == 30)
    }

    @Test func accordDeQuestion() {
        #expect(libelleQuestions(0) == "0 question")
        #expect(libelleQuestions(1) == "1 question")
        #expect(libelleQuestions(2) == "2 questions")
        #expect(Notifications.requete(pour: Notifications.Rappel(declenchement: date(2026, 11, 12, 18, 0), nombre: 1)).content.body
            == "1 question à revoir aujourd'hui.")
    }

    @Test func heureParDefautA18h() {
        #expect(Notifications.heureParDefaut == 18 * 60)
    }
}
