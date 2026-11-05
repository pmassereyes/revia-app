//
//  Notifications.swift
//  RevIA
//

import Foundation
import UserNotifications

/// « 0 question », « 1 question », « 3 questions ».
func libelleQuestions(_ nombre: Int) -> String {
    nombre <= 1 ? "\(nombre) question" : "\(nombre) questions"
}

/// Clés `UserDefaults` du rappel, partagées par Réglages et `RootView`.
enum CleRappel {
    static let actif = "rappel.actif"
    static let minutes = "rappel.minutes"
}

/// Rappels quotidiens par notification locale.
enum Notifications {
    static let prefixe = "rappel-"
    /// Nombre de jours planifiés à l'avance. La planification est refaite à chaque passage en arrière-plan.
    static let horizon = 14
    /// 18 h, en minutes depuis minuit.
    static let heureParDefaut = 18 * 60

    struct Rappel: Equatable {
        let declenchement: Date
        let nombre: Int
    }

    /// Un rappel par jour, à `minutes` après minuit, seulement les jours où des questions sont à revoir.
    /// Le nombre compte aussi les questions en retard, comme si l'utilisateur ne révisait pas d'ici là.
    static func rappels(
        pour revisions: [Date],
        a minutes: Int,
        maintenant: Date,
        calendrier: Calendar = .current
    ) -> [Rappel] {
        let aujourdHui = calendrier.startOfDay(for: maintenant)
        let jours = revisions.map { calendrier.startOfDay(for: $0) }
        return (0..<horizon).compactMap { decalage in
            guard let jour = calendrier.date(byAdding: .day, value: decalage, to: aujourdHui),
                  let declenchement = calendrier.date(byAdding: .minute, value: minutes, to: jour),
                  declenchement > maintenant else { return nil }
            let nombre = jours.filter { $0 <= jour }.count
            return nombre > 0 ? Rappel(declenchement: declenchement, nombre: nombre) : nil
        }
    }

    static func requete(pour rappel: Rappel, calendrier: Calendar = .current) -> UNNotificationRequest {
        let contenu = UNMutableNotificationContent()
        contenu.title = "RevIA"
        contenu.body = "\(libelleQuestions(rappel.nombre)) à revoir aujourd'hui."
        contenu.sound = .default
        let composantes = calendrier.dateComponents([.year, .month, .day, .hour, .minute], from: rappel.declenchement)
        let identifiant = prefixe + rappel.declenchement.formatted(.iso8601)
        return UNNotificationRequest(
            identifier: identifiant,
            content: contenu,
            trigger: UNCalendarNotificationTrigger(dateMatching: composantes, repeats: false)
        )
    }

    static func demanderAutorisation() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Remplace les rappels en attente. Sans rappel actif, les supprime seulement.
    static func replanifier(revisions: [Date], actif: Bool, minutes: Int) async {
        let centre = UNUserNotificationCenter.current()
        let enAttente = await centre.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefixe) }
        centre.removePendingNotificationRequests(withIdentifiers: enAttente)
        guard actif else { return }
        for rappel in rappels(pour: revisions, a: minutes, maintenant: .now) {
            try? await centre.add(requete(pour: rappel))
        }
    }
}
