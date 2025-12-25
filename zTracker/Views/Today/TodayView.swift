//
//  TodayView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var activeHabits: [Habit]
    @State private var showingEntryEditor: Habit?
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            
            ScrollView {
                
                // MARK: date header
                VStack {
                    Text(Date(), style: .date)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(Date(), style: .time)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                StatsOverviewView()
                    .padding(Edge.Set.horizontal)
                
                // MARK: today's habits
                LazyVGrid {
                    ForEach(activeHabits) { habit in HabitCardView(habit: habit) { showingEntryEditor = habit }
                            .contextMenu {
                                Button("Edit Entry") {
                                    showingEntryEditor = habit
                                }
                                .buttonStyle(.glass)
                                
                                Button("View History") {
                                    appState.selectedHabit = habit
                                    appState.selectedTab = .habits
                                }
                                .buttonStyle(.glass)
                                
                                Divider()
                                
                                Button("Archive", role: .destructive) {
                                    Task { await StorageManager.shared.archiveHabit(habit) }
                                }
                                .buttonStyle(.glass)
                            }
                    }
                }
                .padding()
                
                if activeHabits.isEmpty { EmptyStateView() }
            }
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showingNewHabit = true }) {
                    Label("Add Habit", systemImage: "plus")
                }
                .buttonStyle(.glass)
            }
        }
        .glassEffect()

        .sheet(item: $showingEntryEditor) { habit in EntryEditorView(habit: habit) }
        .sheet(isPresented: $appState.showingNewHabit) { HabitEditorView() }
    }
}
