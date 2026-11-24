//
//  MoodInsightsView.swift
//  Kairo
//
//  Created by Andrii Kovner on 24.11.26.
//

import SwiftUI
import SwiftData
import Charts

struct MoodInsightsView: View {
    @Query private var moods: [DailyMood]
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var referenceDate = Date.now
    @State private var currentTimeZone = TimeZone.current
    
    @State private var selectedPeriod: MoodInsightsPeriod = .sevenDays
    
    private var days: [MoodInsightsDay] {
        MoodInsightsCalculator.days(
            from: moods,
            period: selectedPeriod,
            referenceDate: referenceDate,
            timeZone: currentTimeZone
        )
    }
    
    var body: some View {
        let summary = MoodInsightsSummary(days: days)
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            AnimatedAppBackground()
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
            ScrollView {
                VStack(spacing: 24) {
                    periodPicker
                    trackingSection(summary)
                    chartSection(summary)
                    distributionSection(summary)
                }
                .padding()
            }
        }
        .navigationTitle("Mood Insights")
        .navigationBarTitleDisplayMode(.inline)
        
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshCalendarContext()
            }
        }
        
        .onReceive(
            NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
        ) { _ in
            refreshCalendarContext()
        }
        
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.significantTimeChangeNotification
            )
        ) { _ in
            refreshCalendarContext()
        }
    }
    
    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(MoodInsightsPeriod.allCases) { period in
                Text(period.title)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private func trackingSection(_ summary: MoodInsightsSummary) -> some View {
        VStack(spacing: 8) {
            Text("Days Tracked")
                .font(.headline)
            
            Text("\(summary.daysTracked) / \(summary.totalDays)")
                .font(.largeTitle.bold())
            
            Text("Days without an entry: \(summary.missingDays)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Chart
    
    private func chartSection(_ summary: MoodInsightsSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if summary.daysTracked == 0 {
                ContentUnavailableView(
                    "No Mood Entries in This Period",
                    systemImage: "chart.xyaxis.line",
                    description: Text("You can record your mood in Today.")
                )
            } else {
                let range = chartDateRange(for: summary.days)
                let dateStyle = Date.IntervalFormatStyle(
                    calendar: chartCalendar,
                    timeZone: currentTimeZone
                ).month(.abbreviated).day()

                Text((range.lowerBound..<range.upperBound).formatted(dateStyle))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Chart {
                    ForEach(MoodType.allCases) { mood in
                        RuleMark(y: .value("Mood", mood.title))
                            .foregroundStyle(.secondary.opacity(0.25))
                            .lineStyle(StrokeStyle(lineWidth: 0.5))
                            .annotation(position: .leading, spacing: 6) {
                                Text(mood.title)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .accessibilityHidden(true)
                    }
                    
                    ForEach(summary.days) { day in
                        if let mood = day.mood {
                            PointMark(
                                x: .value("Day", day.date),
                                y: .value("Mood", mood.title)
                            )
                            .foregroundStyle(Color.accentColor)
                            .symbolSize(90)
                            .accessibilityLabel(
                                Text(day.date, format: .dateTime.day().month(.wide).year())
                            )
                            .accessibilityValue(Text(mood.title))
                        }
                    }
                }
                .chartYScale(domain: MoodType.allCases.map(\.title))
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(preset: .aligned, values: axisDates(for: summary.days)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel(centered: false, anchor: .top) {
                                Text(chartCalendar.component(.day, from: date), format: .number)
                            }
                        }
                    }
                }
                .chartXScale(
                    domain: chartDateRange(for: summary.days),
                    range: .plotDimension(startPadding: 10, endPadding: 10)
                )
                .frame(height: 240)
                .padding(.leading, 36)
                .accessibilityLabel("Mood over time")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var chartCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = currentTimeZone
        return calendar
    }

    private func axisDates(for days: [MoodInsightsDay]) -> [Date] {
        guard days.count > 7 else {
            return days.map(\.date)
        }

        let lastIndex = days.count - 1

        return days.indices
            .filter { $0.isMultiple(of: 5) || $0 == lastIndex }
            .map { days[$0].date }
    }
    
    private func chartDateRange(for visibleDays: [MoodInsightsDay]) -> ClosedRange<Date> {
        let start = visibleDays.first?.date ?? referenceDate
        let end = visibleDays.last?.date ?? start
        
        return start...end
    }
    
    // MARK: - Distribution
    
    private func distributionSection(_ summary: MoodInsightsSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mood Distribution")
                .font(.headline)
            
            ForEach(MoodType.allCases) { mood in
                HStack(spacing: 12) {
                    Image(systemName: mood.symbolName)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    
                    Text(mood.title)
                    
                    Spacer()
                    
                    Text("\(summary.count(for: mood))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Calendar Updates
    
    private func refreshCalendarContext() {
        referenceDate = .now
        currentTimeZone = .current
    }
}

// MARK: - Preview

#Preview("Mood Insights") {
    let calendar = Calendar.current
    let now = Date.now
    
    let moodTypes: [MoodType] = [
        .great,
        .good,
        .okay,
        .low,
        .bad,
        .good
    ]
    
    let sampleMoods: [DailyMood] = moodTypes
        .enumerated()
        .compactMap { index, mood -> DailyMood? in
            guard let date = calendar.date(
                byAdding: .day,
                value: -(index * 2),
                to: now
            ) else {
                return nil
            }
            
            let dayKey = MoodDayKey.make(for: date)
            
            return DailyMood(
                dayKey: dayKey,
                mood: mood
            )
        }
    
    return NavigationStack {
        MoodInsightsView()
    }
    .modelContainer(
        PreviewContainer.make(
            tasks: [],
            journalEntries: [],
            moods: sampleMoods
        )
    )
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
}
