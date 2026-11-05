//
//  StatsView.swift
//  RevIA
//

import Charts
import SwiftData
import SwiftUI

/// Réussite par UE et par thème, état de Leitner et évolution des scores.
struct StatsView: View {
    @Query(sort: \SessionRevision.date) private var sessions: [SessionRevision]
    @Query private var questions: [QuestionQCM]

    /// Nombre de thèmes affichés, les plus faibles d'abord.
    private let nbThemes = 8

    var body: some View {
        let stats = StatsViewModel(sessions: sessions, questions: questions)
        NavigationStack {
            Group {
                if stats.estVide {
                    ContentUnavailableView(
                        "Pas encore de statistiques",
                        systemImage: "chart.bar",
                        description: Text("Terminez un quiz : vos résultats par UE et par thème apparaîtront ici.")
                    )
                } else {
                    List {
                        Section {
                            HStack {
                                chiffre("\(sessions.count)", "sessions")
                                chiffre("\(stats.nbReponses)", "réponses")
                                chiffre(stats.tauxGlobal.valeur.formatted(.percent.precision(.fractionLength(0))), "de réussite")
                            }
                        }
                        Section("Réussite par UE") {
                            GraphiqueTaux(taux: stats.parUE)
                        }
                        Section("Thèmes à retravailler") {
                            GraphiqueTaux(taux: Array(stats.parTheme.prefix(nbThemes)))
                        }
                        Section("Questions par boîte de Leitner") {
                            Chart(stats.parBoite) { boite in
                                BarMark(x: .value("Boîte", "Boîte \(boite.numero)"), y: .value("Questions", boite.nombre))
                                    .foregroundStyle(.tint)
                            }
                            .frame(height: 180)
                        }
                        if stats.evolution.count > 1 {
                            Section("Évolution du score") {
                                Chart(stats.evolution) { point in
                                    LineMark(x: .value("Date", point.date), y: .value("Réussite", point.taux))
                                    PointMark(x: .value("Date", point.date), y: .value("Réussite", point.taux))
                                }
                                .chartYScale(domain: 0...1)
                                .chartYAxis {
                                    AxisMarks(values: [0, 0.5, 1]) { valeur in
                                        AxisGridLine()
                                        AxisValueLabel { Text((valeur.as(Double.self) ?? 0).formatted(.percent)) }
                                    }
                                }
                                .frame(height: 180)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Statistiques")
        }
    }

    private func chiffre(_ valeur: String, _ libelle: String) -> some View {
        VStack {
            Text(valeur).font(.title2.bold())
            Text(libelle).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Barres horizontales de taux de réussite, de 0 à 100 % : vert à partir de 70 %, orange à partir de 40 %.
struct GraphiqueTaux: View {
    let taux: [StatsViewModel.Taux]

    var body: some View {
        Chart(taux) { ligne in
            BarMark(x: .value("Réussite", ligne.valeur), y: .value("Libellé", ligne.libelle))
                .foregroundStyle(ligne.valeur >= 0.7 ? .green : ligne.valeur >= 0.4 ? .orange : .red)
                .annotation(position: .trailing) {
                    Text("\(ligne.bonnes)/\(ligne.total)").font(.caption2).foregroundStyle(.secondary)
                }
        }
        .chartXScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(values: [0, 0.5, 1]) { valeur in
                AxisGridLine()
                AxisValueLabel { Text((valeur.as(Double.self) ?? 0).formatted(.percent)) }
            }
        }
        .frame(height: CGFloat(max(taux.count, 1)) * 36 + 30)
    }
}
