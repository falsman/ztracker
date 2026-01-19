//
//  StatsOverviewView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct StatsOverviewView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived })
    private var activeHabits: [Habit]
    
    var body: some View {
        HStack {
            let todayCompletionRate = dailyCompletionRate(for: today)
            let completedHabitCount = todayCompletionRate * Double(activeHabits.count)
            StatCard(
                title: "Today",
                value: todayCompletionRate.formatted(.percent.precision(.fractionLength(0))),
                icon: "ellipsis.calendar",
                iconVariation: todayCompletionRate,
                caption: ""
                )
            .contentShape(.rect)
            .contextMenu {
                Text("Current Progress: \(Int(completedHabitCount)) / \(activeHabits.count)")
            }
          preview: {
              VStack {
                  //TODO: add info for today
              }
              .padding()
              .glassEffect(in: .rect(cornerRadius: 16))
            }
            
            StatCard(
                title: "Habits",
                value: activeHabits.count.description,
                icon: "square.grid.2x2",
                iconVariation: 1,
                caption: ""
            )
            .contentShape(.rect)
            .contextMenu {
                Text("# of Active Habits")
            }
          preview: {
              VStack(alignment: .leading) {
                  Text("This Week")
                      .font(.headline)
                  
                  ForEach(activeHabits) { habit in
                      HStack() {
                          Image(systemName: habit.icon ?? "checkmark.circle")
                          Text(habit.title)
                          
                          Spacer()
                                                    
                          Text((HabitAverage(habit: habit, days: 7)).value)
                      }
                      .foregroundStyle(habit.swiftUIColor.secondary)
                  }
              }
              .padding()
              .glassEffect(in: .rect(cornerRadius: 16))
            }
            
            StatCard(
                title: "Streak",
                value: longestStreak().streakCount.description,
                icon: "flame",
                iconVariation: 1,
                caption: ""
            )
            .contentShape(.rect)
            .contextMenu {
                Text("Longest: \(longestStreak().habit.title)")
            }
          preview: {
              StreakLeaderboard(activeHabits: activeHabits)
            }
        }
    }
    
    private func dailyCompletionRate(for date: Date) -> Double {
        var completed = 0
        
        for habit in activeHabits {
            if let entry = habit.entry(for: date) {
                switch habit.type {
                case .boolean: if entry.completed == true { completed += 1 }
                case .duration: if entry.time != nil { completed += 1 }
                case .rating: if entry.ratValue != nil { completed += 1 }
                case .numeric: if entry.numValue != nil { completed += 1 }
                }
            }
        }
        
        return activeHabits.isEmpty ? 0 : Double(completed) / Double(activeHabits.count)
    }
    
    private func longestStreak() -> (habit: Habit, streakCount: Int) {
        var currentLongest = (habit: activeHabits.first!, streakCount: activeHabits.first!.currentGoalStreak())
        
        for habit in activeHabits {
            if habit.currentGoalStreak() > currentLongest.streakCount {
                currentLongest = (habit: habit, streakCount: habit.currentGoalStreak())
            }
            
        }
        return currentLongest
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconVariation: Double = 1.0
    let caption: LocalizedStringKey?
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon, variableValue: iconVariation)
                    .dynamicTypeSize(.large)
                   // .foregroundStyle(color)
                Text(title)
//                    .frame(maxHeight: 20)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            
            HStack(alignment: .bottom) {
                Text(value)
                    .dynamicTypeSize(.xxLarge)
                    .lineLimit(1)
//                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let caption {
                    Spacer()
                    Text(caption)
                        .font(.caption2.italic())
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                    
                }
            }
        }
        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(in: .rect)
        .cornerRadius(16)
        
    }
}

#Preview {
    let container = PreviewHelpers.previewContainer
    let habits = PreviewHelpers.makeHabits()
    
    habits.forEach { container.mainContext.insert($0) }
    
    return StatsOverviewView()
        .modelContainer(container)
        .padding()
}

#Preview("Stat Card") {
    VStack {
        HStack {
            StatCard(
                title: "Today",
                value: "40%",
                icon: "ellipsis.calendar",
                iconVariation: 0.4,
                caption: "Done"
            )
            
            StatCard(
                title: "Habits",
                value: "20",
                icon: "square.grid.2x2",
                iconVariation: 1,
                caption: "Active"
            )
            
            StatCard(
                title: "Streak",
                value: "90",
                icon: "flame",
                caption: "Longest"
            )
        }
        .padding()
            
    }
}
