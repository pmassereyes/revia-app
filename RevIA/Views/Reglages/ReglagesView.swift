//
//  ReglagesView.swift
//  RevIA
//

import SwiftData
import SwiftUI

struct ReglagesView: View {
    @State private var viewModel: ReglagesViewModel

    init(viewModel: ReglagesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Adresse", text: $viewModel.urlTexte, prompt: Text("http://127.0.0.1:8000"))
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Jeton", text: $viewModel.jeton, prompt: Text("Jeton d'accès"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("API de génération")
                } footer: {
                    Text("API hébergée : https://nom-du-service.onrender.com. En développement : http://127.0.0.1:8000 sur le simulateur, http://nom-du-mac.local:8000 sur un iPhone. L'adresse et le jeton sont rangés dans le Keychain.")
                }

                Section {
                    Button("Enregistrer") { viewModel.enregistrer() }
                        .disabled(!viewModel.modifie)
                    Button {
                        Task { await viewModel.testerConnexion() }
                    } label: {
                        HStack {
                            Text("Tester la connexion")
                            Spacer()
                            etatConnexion
                        }
                    }
                    .disabled(viewModel.etatConnexion == .enCours)
                }

                SectionRappel()

                if let message = viewModel.messageErreur {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Réglages")
        }
    }

    @ViewBuilder
    private var etatConnexion: some View {
        switch viewModel.etatConnexion {
        case .inconnu:
            EmptyView()
        case .enCours:
            HStack(spacing: 8) {
                Text("Réveil possible, jusqu'à 1 min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView()
            }
        case .joignable:
            Label("Serveur joignable", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .injoignable:
            Label("Serveur injoignable", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    ReglagesView(viewModel: ReglagesViewModel(reglages: .standard))
}

/// Activation et heure du rappel quotidien.
private struct SectionRappel: View {
    @AppStorage(CleRappel.actif) private var actif = false
    @AppStorage(CleRappel.minutes) private var minutes = Notifications.heureParDefaut
    @Query private var questions: [QuestionQCM]
    @State private var refuse = false

    var body: some View {
        Section {
            Toggle("Rappel quotidien", isOn: Binding(get: { actif }, set: { nouveau in Task { await activer(nouveau) } }))
            if actif {
                DatePicker("Heure", selection: heure, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Rappel")
        } footer: {
            Text(refuse
                ? "Les notifications de RevIA sont refusées : autorisez-les dans l'app Réglages de l'iPhone."
                : "Une notification, seulement les jours où des questions sont à revoir.")
        }
        .onChange(of: minutes) { Task { await replanifier() } }
    }

    private var heure: Binding<Date> {
        Binding(
            get: { Calendar.current.date(byAdding: .minute, value: minutes, to: Calendar.current.startOfDay(for: .now)) ?? .now },
            set: { date in
                let composantes = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes = (composantes.hour ?? 0) * 60 + (composantes.minute ?? 0)
            }
        )
    }

    private func activer(_ nouveau: Bool) async {
        if nouveau {
            let autorise = await Notifications.demanderAutorisation()
            refuse = !autorise
            actif = autorise
        } else {
            actif = false
        }
        await replanifier()
    }

    private func replanifier() async {
        await Notifications.replanifier(
            revisions: questions.filter { $0.cours != nil }.map(\.prochaineRevision),
            actif: actif,
            minutes: minutes
        )
    }
}
