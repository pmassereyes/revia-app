//
//  UEDetailView.swift
//  RevIA
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Les cours d'une UE, du plus récent au plus ancien, et l'import d'un nouveau PDF.
struct UEDetailView: View {
    let ue: UE
    @Environment(\.modelContext) private var contexte
    @State private var viewModel = BibliothequeViewModel()
    @State private var selecteurAffiche = false
    @State private var pdfImporte: PDFImporte?
    @State private var coursASupprimer: Cours?

    private var coursTries: [Cours] {
        ue.cours.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if ue.cours.isEmpty {
                ContentUnavailableView {
                    Label("Aucun cours", systemImage: "doc.text")
                } description: {
                    Text("Importez le PDF d'un cours pour en tirer un QCM.")
                } actions: {
                    Button("Importer un PDF") { selecteurAffiche = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List(coursTries) { cours in
                    NavigationLink(value: cours) {
                        LigneCours(cours: cours)
                    }
                    .swipeActions {
                        Button("Supprimer", systemImage: "trash", role: .destructive) { coursASupprimer = cours }
                    }
                }
            }
        }
        .navigationTitle(ue.nom)
        .navigationDestination(for: Cours.self) { DetailCoursView(cours: $0) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Importer un PDF", systemImage: "plus") { selecteurAffiche = true }
            }
        }
        .fileImporter(isPresented: $selecteurAffiche, allowedContentTypes: [.pdf]) { resultat in
            guard case .success(let url) = resultat else { return }
            if let nom = viewModel.importerPDF(depuis: url) {
                pdfImporte = PDFImporte(nomFichier: nom, titre: url.deletingPathExtension().lastPathComponent)
            }
        }
        .sheet(item: $pdfImporte) { pdf in
            AjoutCoursView(titreInitial: pdf.titre) { titre, date in
                viewModel.ajouterCours(titre: titre, titreParDefaut: pdf.titre, date: date, nomFichier: pdf.nomFichier, ue: ue, contexte: contexte)
            } annuler: {
                viewModel.abandonnerImport(pdf.nomFichier)
            }
            // Fermer la feuille d'un geste laisserait un PDF copié sans cours
            .interactiveDismissDisabled()
        }
        .alert(
            "Import impossible",
            isPresented: Binding(get: { viewModel.messageErreur != nil }, set: { if !$0 { viewModel.effacerErreur() } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.messageErreur ?? "")
        }
        .alert(
            "Supprimer le cours ?",
            isPresented: Binding(get: { coursASupprimer != nil }, set: { if !$0 { coursASupprimer = nil } }),
            presenting: coursASupprimer
        ) { cours in
            Button("Supprimer", role: .destructive) { viewModel.supprimer(cours, contexte: contexte) }
            Button("Annuler", role: .cancel) {}
        } message: { cours in
            Text("« \(cours.titre) », son PDF et ses \(cours.questions.count) questions seront supprimés.")
        }
    }
}

/// PDF copié dans l'app, en attente de son titre et de sa date.
private struct PDFImporte: Identifiable {
    let nomFichier: String
    let titre: String
    var id: String { nomFichier }
}

struct LigneCours: View {
    let cours: Cours

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cours.titre)
                .font(.headline)
            HStack {
                Text(cours.date, format: .dateTime.day().month().year())
                Text("·")
                statut
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statut: some View {
        switch cours.statut {
        case .jamaisGeneree:
            Text("QCM à générer")
        case .enCours:
            Text("Génération en cours…")
        case .terminee:
            Text("\(cours.questions.count) questions")
        case .echec:
            Text("Échec de la génération")
                .foregroundStyle(.red)
        }
    }
}
