//
//  ReglagesTests.swift
//  RevIA
//

import Foundation
import Testing
@testable import RevIA

/// Stockage en mémoire, à la place du Keychain.
@MainActor
final class StockageEnMemoire: StockageSecret {
    var valeurs: [String: String] = [:]

    func lire(_ cle: String) -> String? { valeurs[cle] }

    func ecrire(_ valeur: String, pour cle: String) throws(ErreurKeychain) {
        valeurs[cle] = valeur.isEmpty ? nil : valeur
    }
}

@MainActor private let valeursDuXcconfig: [String: Any] = [
    "API_BASE_URL": "http://127.0.0.1:8000",
    "API_TOKEN": "jeton-du-xcconfig",
]

@MainActor
struct KeychainTests {
    /// Service propre à chaque test, pour ne jamais toucher aux vrais réglages.
    let keychain = Keychain(service: "RevIA.tests.\(UUID().uuidString)")

    @Test func ecritPuisRelitUneValeur() throws {
        try keychain.ecrire("valeur", pour: "cle")
        defer { try? keychain.ecrire("", pour: "cle") }

        #expect(keychain.lire("cle") == "valeur")
    }

    @Test func remplaceUneValeurExistante() throws {
        try keychain.ecrire("ancienne", pour: "cle")
        try keychain.ecrire("nouvelle", pour: "cle")
        defer { try? keychain.ecrire("", pour: "cle") }

        #expect(keychain.lire("cle") == "nouvelle")
    }

    @Test func uneValeurVideSupprimeLaCle() throws {
        try keychain.ecrire("valeur", pour: "cle")
        try keychain.ecrire("", pour: "cle")

        #expect(keychain.lire("cle") == nil)
    }

    @Test func supprimerUneCleAbsenteNEstPasUneErreur() throws {
        try keychain.ecrire("", pour: "absente")
    }
}

@MainActor
struct ReglagesAPITests {
    let stockage = StockageEnMemoire()

    @Test func sansRienEnregistreLeXcconfigSertDeValeurInitiale() throws {
        let reglages = ReglagesAPI(stockage: stockage, valeursInitiales: valeursDuXcconfig)

        let configuration = try #require(reglages.configuration)
        #expect(configuration.urlDeBase.absoluteString == "http://127.0.0.1:8000")
        #expect(configuration.jeton == "jeton-du-xcconfig")
    }

    @Test func laValeurDuKeychainPrime() throws {
        let reglages = ReglagesAPI(stockage: stockage, valeursInitiales: valeursDuXcconfig)
        try reglages.enregistrer(urlTexte: " http://mon-mac.local:8000 ", jeton: "jeton-saisi")

        #expect(reglages.urlTexte == "http://mon-mac.local:8000")
        #expect(reglages.jeton == "jeton-saisi")
    }

    @Test func sansXcconfigNiKeychainIlNYAPasDeConfiguration() {
        let reglages = ReglagesAPI(stockage: stockage, valeursInitiales: ["API_BASE_URL": "", "API_TOKEN": ""])

        #expect(reglages.urlTexte.isEmpty)
        #expect(reglages.configuration == nil)
    }

    @Test func unJetonVideNeDonnePasDeConfiguration() throws {
        let reglages = ReglagesAPI(stockage: stockage, valeursInitiales: [:])
        try reglages.enregistrer(urlTexte: "http://127.0.0.1:8000", jeton: "")

        #expect(reglages.configuration == nil)
    }

    @Test(arguments: ["http://127.0.0.1:8000", "https://revia.exemple.fr", "http://mon-mac.local:8000/", " http://hote:8000 "])
    func adresseAcceptee(_ texte: String) {
        #expect(ReglagesAPI.urlValide(texte) != nil)
    }

    @Test(arguments: ["", "127.0.0.1:8000", "ftp://hote", "http://", "pas une adresse"])
    func adresseRefusee(_ texte: String) {
        #expect(ReglagesAPI.urlValide(texte) == nil)
    }
}

@MainActor
struct ReglagesViewModelTests {
    let stockage = StockageEnMemoire()

    func viewModel(joignable: Bool = true) -> ReglagesViewModel {
        ReglagesViewModel(
            reglages: ReglagesAPI(stockage: stockage, valeursInitiales: valeursDuXcconfig),
            verifierConnexion: { _ in joignable }
        )
    }

    @Test func afficheLesValeursInitialesSansModification() {
        let vm = viewModel()

        #expect(vm.urlTexte == "http://127.0.0.1:8000")
        #expect(vm.jeton == "jeton-du-xcconfig")
        #expect(!vm.modifie)
    }

    @Test func enregistreDansLeStockage() {
        let vm = viewModel()
        vm.urlTexte = "http://mon-mac.local:8000"
        vm.jeton = "nouveau-jeton"
        #expect(vm.modifie)

        vm.enregistrer()

        #expect(stockage.valeurs[ReglagesAPI.cleURL] == "http://mon-mac.local:8000")
        #expect(stockage.valeurs[ReglagesAPI.cleJeton] == "nouveau-jeton")
        #expect(!vm.modifie)
        #expect(vm.messageErreur == nil)
    }

    @Test func refuseUneAdresseInvalide() {
        let vm = viewModel()
        vm.urlTexte = "127.0.0.1:8000"

        vm.enregistrer()

        #expect(vm.messageErreur == ReglagesViewModel.messageAdresseInvalide)
        #expect(stockage.valeurs.isEmpty)
    }

    @Test func serveurJoignable() async {
        let vm = viewModel(joignable: true)

        await vm.testerConnexion()

        #expect(vm.etatConnexion == .joignable)
    }

    @Test func serveurInjoignable() async {
        let vm = viewModel(joignable: false)

        await vm.testerConnexion()

        #expect(vm.etatConnexion == .injoignable)
    }

    @Test func pasDeTestAvecUneAdresseInvalide() async {
        let vm = viewModel()
        vm.urlTexte = "pas une adresse"

        await vm.testerConnexion()

        #expect(vm.etatConnexion == .inconnu)
        #expect(vm.messageErreur == ReglagesViewModel.messageAdresseInvalide)
    }
}
