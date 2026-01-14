//
//  InsightsView 2.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
import SwiftData

enum Timeframe: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    
    var id: Self { self }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

struct InsightsView: View {
    
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \.sortIndex,
           order: .forward
    )
    private var activeHabits: [Habit]

    
    @State private var selectedTimeframe: Timeframe = .week
    @State private var selectedHabit: Habit?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    CompletionRateChart(habits: activeHabits, days: selectedTimeframe.days)
                        .padding(.horizontal)
                        .frame(height: 200)
                    
                    VStack(alignment: .leading) {
                        Text("Habit Performance")
                            .font(.headline)
                            .padding()
                        
                        ForEach(activeHabits) { habit in
                            HabitPerformanceRow(habit: habit, days: selectedTimeframe.days)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                    .glassEffect(in: .rect(cornerRadius: 16))
                    .padding(.horizontal)

                    
                    StreakLeaderboard(activeHabits: activeHabits)
                        .padding(.horizontal)
                }
            }
            #if os(iOS)
            .background(movingLinearGradient(selectedColor: .theme))
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Insights")
            // .backgroundExtensionEffect(isEnabled: true)
        }
    }
}

#Preview("Empty State") {
    InsightsView()
        .modelContainer(PreviewHelpers.previewContainer)
        
}

#Preview("With Sample Data") {
    NavigationStack {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return InsightsView()
            .modelContainer(container)
            
    }
}
