//
//  ImportEtGenerationTests.swift
//  RevIA
//

import Foundation
import SwiftData
import Testing
@testable import RevIA

struct StockagePDFTests {
    let stockage = stockageTemporaire()

    @Test func importeUnPDFDansLeDossierDeLApp() throws {
        let nom = try stockage.importer(depuis: fichierSource(contenuPDF))

        #expect(nom.hasSuffix(".pdf"))
        #expect(try stockage.donnees(de: nom) == contenuPDF)
    }

    @Test func refuseUnFichierQuiNEstPasUnPDF() throws {
        let source = try fichierSource(Data("Bonjour".utf8), nom: "notes.pdf")

        #expect(throws: ErreurImport.pasUnPDF) { try stockage.importer(depuis: source) }
    }

    @Test func refuseUnPDFDePlusDe20Mo() throws {
        let source = try fichierSource(contenuPDF)
        // Fichier creux : agrandi sans écrire 20 Mo sur le disque
        let fichier = try FileHandle(forWritingTo: source)
        try fichier.truncate(atOffset: UInt64(APIGenerateur.tailleMaximalePDF + 1))
        try fichier.close()

        #expect(throws: ErreurImport.tropVolumineux) { try stockage.importer(depuis: source) }
    }

    @Test func supprimeUnPDF() throws {
        let nom = try stockage.importer(depuis: fichierSource(contenuPDF))

        stockage.supprimer(nom)

        #expect(!FileManager.default.fileExists(atPath: stockage.url(de: nom).path()))
    }
}

struct MessagesErreurTests {

    @Test func leCodeEnregistreSuitLeContratDeLAPI() {
        #expect(GenerationError.api(.quotaEpuise, message: "m").code == "quota_exceeded")
        #expect(GenerationError.api(.inconnu, message: "m").code == "inconnu")
        #expect(GenerationError.reseau.code == "reseau")
        #expect(GenerationError.pdfTropVolumineux.code == "pdf_trop_volumineux")
    }

    @Test func leMessageDeLAPIEstSuiviDeLaConduiteATenir() {
        #expect(GenerationError.api(.jetonInvalide, message: "Jeton invalide ou manquant.").messagePourUtilisateur
            == "Jeton invalide ou manquant. Vérifiez le jeton dans Réglages.")
        #expect(GenerationError.api(.tropDeRequetes, message: "Trop de requêtes.").messagePourUtilisateur
            == "Trop de requêtes. Patientez une minute avant de réessayer.")
    }

    @Test func sansConduiteUtileLeMessageDeLAPIEstAfficheTelQuel() {
        #expect(GenerationError.api(.pdfInvalide, message: "Le fichier n'est pas un PDF valide.").messagePourUtilisateur
            == "Le fichier n'est pas un PDF valide.")
    }

    @Test func uneErreurReseauRenvoieVersReglages() {
        #expect(GenerationError.reseau.messagePourUtilisateur.contains("Réglages"))
    }
}

@MainActor
struct DetailCoursViewModelTests {
    let conteneur: ModelContainer
    var contexte: ModelContext { conteneur.mainContext }
    let stockage = stockageTemporaire()
    let cours: Cours

    init() throws {
        conteneur = try StockageDonnees.conteneur(enMemoire: true)
        let nom = try stockage.importer(depuis: fichierSource(contenuPDF))
        cours = Cours(titre: "TCP/IP", nomFichier: nom)
        conteneur.mainContext.insert(cours)
    }

    func viewModel(_ generateur: FauxGenerateur?) -> DetailCoursViewModel {
        DetailCoursViewModel(cours: cours, stockage: stockage, fabriqueGenerateur: { generateur })
    }

    @Test func genereLeQCMAvecLePDFEtLeNombreDeQuestionsChoisi() async {
        let generateur = FauxGenerateur(.success(ReponseQCM(qcm: [qcm("Q1"), qcm("Q2", theme: "Routage")], avertissement: nil)))
        let vm = viewModel(generateur)
        vm.nbQuestions = 12

        await vm.generer(contexte: contexte)

        #expect(generateur.pdfRecu == contenuPDF)
        #expect(generateur.nbQuestionsRecu == 12)
        #expect(cours.statut == .terminee)
        #expect(cours.questionsOrdonnees.map(\.question) == ["Q1", "Q2"])
        #expect(!vm.generationEnCours)
        #expect(vm.themes.map(\.theme) == ["Réseaux", "Routage"])
    }

    @Test func gardeLAvertissementDeLAPI() async {
        let vm = viewModel(FauxGenerateur(.success(ReponseQCM(qcm: [qcm("Q1")], avertissement: "Une seule question possible."))))

        await vm.generer(contexte: contexte)

        #expect(cours.avertissement == "Une seule question possible.")
    }

    @Test func sansConfigurationRenvoieVersReglages() async {
        let vm = viewModel(nil)

        await vm.generer(contexte: contexte)

        #expect(cours.statut == .echec)
        #expect(cours.codeErreur == "configuration")
        #expect(cours.messageErreur == DetailCoursViewModel.messageSansConfiguration)
    }

    @Test func sansPDFLaGenerationEchoue() async {
        stockage.supprimer(cours.nomFichier!)
        let generateur = FauxGenerateur(.success(ReponseQCM(qcm: [qcm("Q1")], avertissement: nil)))

        await viewModel(generateur).generer(contexte: contexte)

        #expect(cours.codeErreur == "pdf_introuvable")
        #expect(generateur.pdfRecu == nil)
    }

    @Test func uneErreurDeLAPIEstEnregistreeAvecSonConseil() async {
        await viewModel(FauxGenerateur(.failure(.api(.quotaEpuise, message: "Quota épuisé.")))).generer(contexte: contexte)

        #expect(cours.statut == .echec)
        #expect(cours.codeErreur == "quota_exceeded")
        #expect(cours.messageErreur == "Quota épuisé. Réessayez dans quelques minutes.")
    }

    @Test func uneRegenerationEchoueeGardeLesQuestionsPrecedentes() async {
        cours.remplacerQuestions(par: ReponseQCM(qcm: [qcm("Ancienne")], avertissement: nil), dans: contexte)
        let vm = viewModel(FauxGenerateur(.failure(.reseau)))
        #expect(vm.regenerationAConfirmer)

        await vm.generer(contexte: contexte)

        #expect(cours.statut == .echec)
        #expect(cours.questions.map(\.question) == ["Ancienne"])
    }

    @Test func pasDeGenerationPendantUneAutre() async {
        cours.statut = .enCours
        let generateur = FauxGenerateur(.success(ReponseQCM(qcm: [qcm("Q1")], avertissement: nil)))
        let vm = viewModel(generateur)

        #expect(!vm.peutGenerer)
        await vm.generer(contexte: contexte)
        #expect(generateur.nbQuestionsRecu == nil)
    }

    @Test func leNombreDeQuestionsVaDe1A30Et10ParDefaut() {
        #expect(DetailCoursViewModel.plageNbQuestions == 1...30)
        #expect(viewModel(nil).nbQuestions == 10)
    }
}

@MainActor
struct RepriseEtSuppressionTests {
    let conteneur: ModelContainer
    var contexte: ModelContext { conteneur.mainContext }
    let stockage = stockageTemporaire()

    init() throws {
        conteneur = try StockageDonnees.conteneur(enMemoire: true)
    }

    @Test func uneGenerationInterrompuePasseEnEchecAuLancement() throws {
        let interrompu = Cours(titre: "Interrompu")
        interrompu.statut = .enCours
        let termine = Cours(titre: "Terminé")
        termine.statut = .terminee
        contexte.insert(interrompu)
        contexte.insert(termine)
        try contexte.save()

        StockageDonnees.reprendreGenerationsInterrompues(dans: contexte)

        #expect(interrompu.statut == .echec)
        #expect(interrompu.codeErreur == "interrompue")
        #expect(interrompu.messageErreur == StockageDonnees.messageGenerationInterrompue)
        #expect(termine.statut == .terminee)
    }

    @Test func ajouterUnCoursSansTitrePrendLeNomDuFichier() throws {
        let vm = BibliothequeViewModel(stockage: stockage)
        let ue = UE(nom: "Réseaux")
        contexte.insert(ue)

        let cours = vm.ajouterCours(titre: "  ", titreParDefaut: "Cours TCP", date: .now, nomFichier: "x.pdf", ue: ue, contexte: contexte)

        #expect(cours.titre == "Cours TCP")
        #expect(ue.cours.count == 1)
    }

    @Test func unImportRefuseDonneUnMessage() throws {
        let vm = BibliothequeViewModel(stockage: stockage)

        #expect(vm.importerPDF(depuis: try fichierSource(Data("texte".utf8))) == nil)
        #expect(vm.messageErreur == ErreurImport.pasUnPDF.message)
    }

    @Test func supprimerUnCoursSupprimeSonPDF() throws {
        let vm = BibliothequeViewModel(stockage: stockage)
        let nom = try #require(vm.importerPDF(depuis: try fichierSource(contenuPDF)))
        let cours = Cours(titre: "TCP", nomFichier: nom)
        contexte.insert(cours)

        vm.supprimer(cours, contexte: contexte)

        #expect(!FileManager.default.fileExists(atPath: stockage.url(de: nom).path()))
    }

    @Test func supprimerUneUESupprimeLesPDFDeSesCours() throws {
        let vm = BibliothequeViewModel(stockage: stockage)
        let ue = UE(nom: "Réseaux")
        contexte.insert(ue)
        let noms = try (1...2).map { _ in try #require(vm.importerPDF(depuis: try fichierSource(contenuPDF))) }
        for nom in noms { contexte.insert(Cours(titre: nom, nomFichier: nom, ue: ue)) }
        try contexte.save()

        vm.supprimer(ue, contexte: contexte)

        for nom in noms {
            #expect(!FileManager.default.fileExists(atPath: stockage.url(de: nom).path()))
        }
    }

    @Test func abandonnerUnImportSupprimeLePDFCopie() throws {
        let vm = BibliothequeViewModel(stockage: stockage)
        let nom = try #require(vm.importerPDF(depuis: try fichierSource(contenuPDF)))

        vm.abandonnerImport(nom)

        #expect(!FileManager.default.fileExists(atPath: stockage.url(de: nom).path()))
    }
}
