//
//  InsightsView 2.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var activeHabits: [Habit]
    
    @State private var selectedTimeframe: Timeframe = .week
    @State private var selectedHabit: Habit?
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    // .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    CompletionRateCard(habits: activeHabits, days: selectedTimeframe.days)
                        .padding(.horizontal)
                    // .frame(height: 200)
                    
                    VStack(alignment: .leading) {
                        Text("Habit Performance")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(activeHabits) { habit in
                            HabitPerformanceRow(habit: habit, days: selectedTimeframe.days)
                                .padding(.horizontal)
                        }
                    }
                    
                    StreakLeaderboard()
                    
                    if !activeHabits.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Current Streaks")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ]) {
                                ForEach(activeHabits.sorted(by: { $0.currentStreak() > $1.currentStreak() })) { habit in
                                    StreakCard(habit: habit)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    HabitDistributionChart()
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
            // .backgroundExtensionEffect(isEnabled: true)
        }
    }
}
