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
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
            
            HStack(spacing: 12) {
                statisticItem(title: "Total", value: statistics.total)
                statisticItem(title: "Completed", value: statistics.completed)
                statisticItem(title: "Pending", value: statistics.pending)
            }
            
            Text("Completion: \(completionPercentage)%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func statisticItem(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
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

#Preview {
    StatisticsHeaderView(
        statistics: TaskStatistics(total: 10, completed: 4, pending: 6)
    )
    .padding()
}
