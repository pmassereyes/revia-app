//
//  ReglagesView.swift
//  RevIA
//

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
                    Text("Sur le simulateur : http://127.0.0.1:8000. Sur un iPhone : http://nom-du-mac.local:8000. L'adresse et le jeton sont rangés dans le Keychain.")
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
            ProgressView()
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
