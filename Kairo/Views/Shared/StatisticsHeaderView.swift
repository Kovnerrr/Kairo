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
    
    private let statisticColumns = Array(
        repeating: GridItem(
            .flexible(),
            spacing: 0,
            alignment: .center
        ),
        count: 3
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            ProgressView(value: statistics.completionRate)
                .tint(AppTheme.accent)
                .accessibilityLabel("Completion progress")
                .accessibilityValue("\(completionPercentage) percent")
            
            LazyVGrid(
                columns: statisticColumns,
                spacing: 0
            ) {
                statisticItem(title: "Total", value: statistics.total)
                statisticItem(title: "Completed", value: statistics.completed)
                statisticItem(title: "Pending", value: statistics.pending)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            AppTheme.surface,
            in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overview")
                    .font(AppTheme.Typography.sectionTitle)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Completion: \(completionPercentage)%")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chart.bar.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
    
    private func statisticItem(
        title: String,
        value: Int
    ) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(AppTheme.Typography.statisticNumber)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 38)

            Text(title)
                .font(AppTheme.Typography.secondary)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview("Empty") {
    StatisticsHeaderView(
        statistics: TaskStatistics(total: 0, completed: 0, pending: 0)
    )
    .padding()
    .background(AppTheme.background)
}

#Preview("Partial") {
    StatisticsHeaderView(
        statistics: TaskStatistics(total: 10, completed: 4, pending: 6)
    )
    .padding()
    .background(AppTheme.background)
}

#Preview("Complete") {
    StatisticsHeaderView(
        statistics: TaskStatistics(total: 8, completed: 8, pending: 0)
    )
    .padding()
    .background(AppTheme.background)
}
