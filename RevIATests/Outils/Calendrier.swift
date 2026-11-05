//
//  Calendrier.swift
//  RevIA
//

import Foundation

/// Calendrier fixe pour les tests : grégorien, fuseau de Paris.
let calendrierDeTest: Calendar = {
    var calendrier = Calendar(identifier: .gregorian)
    calendrier.timeZone = TimeZone(identifier: "Europe/Paris")!
    return calendrier
}()

/// Date à heure précise dans le fuseau de `calendrierDeTest`.
func date(_ annee: Int, _ mois: Int, _ jour: Int, _ heure: Int = 12, _ minute: Int = 0) -> Date {
    calendrierDeTest.date(from: DateComponents(year: annee, month: mois, day: jour, hour: heure, minute: minute))!
}
