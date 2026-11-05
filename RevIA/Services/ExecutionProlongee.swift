//
//  ExecutionProlongee.swift
//  RevIA
//

import UIKit

/// Demande au système de laisser finir une tâche si l'utilisateur quitte l'app (environ 30 s de plus).
/// Si la tâche est coupée quand même, la relancer ne coûte rien : l'API garde en cache les QCM déjà générés.
final class ExecutionProlongee {
    private var identifiant: UIBackgroundTaskIdentifier = .invalid

    func commencer(_ nom: String) {
        identifiant = UIApplication.shared.beginBackgroundTask(withName: nom) { [weak self] in
            self?.terminer()
        }
    }

    func terminer() {
        guard identifiant != .invalid else { return }
        UIApplication.shared.endBackgroundTask(identifiant)
        identifiant = .invalid
    }
}
