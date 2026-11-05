//
//  QuestionCardView.swift
//  RevIA
//

import SwiftUI

/// Une question, ses propositions, puis la correction et l'explication une fois la réponse donnée.
struct QuestionCardView: View {
    let question: QuestionQCM
    let reponse: QuizViewModel.Reponse?
    let repondre: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.theme)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.tint.opacity(0.15), in: Capsule())
            Text(question.question)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(question.propositions.indices, id: \.self) { index in
                    Button { repondre(index) } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(question.propositions[index])
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            if let symbole = symbole(index) {
                                Image(systemName: symbole)
                                    .foregroundStyle(estBonne(index) ? .green : .red)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(fond(index), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(bordure(index), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    // Pas de .disabled : il griserait la correction. Le ViewModel ignore une seconde réponse.
                    .allowsHitTesting(reponse == nil)
                    .accessibilityHint(indice(index))
                }
            }

            if let reponse {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        reponse.correcte ? "Bonne réponse" : "Mauvaise réponse",
                        systemImage: reponse.correcte ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(reponse.correcte ? .green : .red)
                    Text(question.explication)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func estBonne(_ index: Int) -> Bool { index == question.indexBonneReponse }
    private func estChoisie(_ index: Int) -> Bool { reponse?.choix == index }

    private func symbole(_ index: Int) -> String? {
        guard reponse != nil else { return nil }
        if estBonne(index) { return "checkmark.circle.fill" }
        if estChoisie(index) { return "xmark.circle.fill" }
        return nil
    }

    private func fond(_ index: Int) -> Color {
        guard reponse != nil else { return Color(.secondarySystemBackground) }
        if estBonne(index) { return .green.opacity(0.2) }
        if estChoisie(index) { return .red.opacity(0.2) }
        return Color(.secondarySystemBackground)
    }

    private func bordure(_ index: Int) -> Color {
        guard reponse != nil else { return .clear }
        if estBonne(index) { return .green }
        if estChoisie(index) { return .red }
        return .clear
    }

    private func indice(_ index: Int) -> String {
        guard reponse != nil else { return "" }
        if estBonne(index) { return "Bonne réponse" }
        if estChoisie(index) { return "Votre réponse" }
        return ""
    }
}
