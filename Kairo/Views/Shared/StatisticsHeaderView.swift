//
//  StatisticsHeaderView.swift
//  Kairo
//
//  Created by Andrii Kovner on 23.06.26.
//

import SwiftUI

struct StatisticsHeaderView: View {
    let statistics: TaskStatistics
    
    private var completionPercentage: Int {
        Int((statistics.completionRate * 100).rounded())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            ProgressView(value: statistics.completionRate)
                .accessibilityLabel("Completion progress")
                .accessibilityValue("\(completionPercentage) percent")
            
            HStack(spacing: 12) {
                statisticItem(title: "Total", value: statistics.total)
                statisticItem(title: "Completed", value: statistics.completed)
                statisticItem(title: "Pending", value: statistics.pending)
            }
        }
        .padding()
        .background(
            Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overview")
                    .font(.headline)
                
                Text("Completion: \(completionPercentage)%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chart.bar.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
    
    private func statisticItem(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview("Empty") {
    StatisticsHeaderView(
        statistics: TaskStatistics(total: 0, completed: 0, pending: 0)
    )
    .padding()
}

#Preview("Partial") {
    StatisticsHeaderView(
        statistics: TaskStatistics(total: 10, completed: 4, pending: 6)
    )
    .padding()
}

#Preview("Complete") {
    StatisticsHeaderView(
        statistics: TaskStatistics(total: 8, completed: 8, pending: 0)
    )
    .padding()
}
