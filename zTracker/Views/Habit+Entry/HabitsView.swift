//
//  HabitsView 2.swift
//  zTracker
//
//  Created by Jia Sahar on 12/17/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct HabitsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Habit> { !$0.isArchived })
    private var activeHabits: [Habit]
    
    @Query(filter: #Predicate<Habit> { $0.isArchived })
    private var archivedHabits: [Habit]
    
    @State private var showingHabitEditor = false

    @State private var selectedHabit: Habit?
    
    var body: some View {
        NavigationSplitView {
            listContent
        } detail: {
            detailContent
        }
    }
    
    private var listContent: some View {
        List(selection: $selectedHabit) {
            activeHabitsSection
            
            if !archivedHabits.isEmpty {
                archivedSection
            }
        }
        .navigationDestination(for: Habit.self) { habit in
            HabitDetailView(habit: habit)
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingHabitEditor = true }) {
                    Label("Add Habit", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingHabitEditor) { HabitEditorView() }
    }
    
    private var activeHabitsSection: some View {
        Section("Active Habits") {
            ForEach(activeHabits) { habit in
                NavigationLink(value: habit) {
                    HabitRow(habit: habit)
                }
                    .swipeActions(edge: .trailing) {
                        editHabit(for: habit)
                    }
                    .swipeActions(edge: .leading) {
                        archiveHabit(for: habit)
                    }
                    .contextMenu {
                        editHabit(for: habit)
                        Divider()
                        archiveHabit(for: habit)
                    }
            }
        }
    }
    
    private var archivedSection: some View {
        Section("Archived") {
            NavigationLink { ArchiveView() } label: {
                HStack {
                    Text("View Archived Habits")
                    Spacer()
                    Text("\(archivedHabits.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func archiveHabit(for habit: Habit) -> some View {
        Button {
            Task { habit.isArchived.toggle() }
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .buttonStyle(.glass)
        .tint(.orange)
    }
    
    @ViewBuilder
    private func editHabit(for habit: Habit) -> some View {
        Button {
            showingHabitEditor = true
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .buttonStyle(.glass)
        .tint(.blue)
    }
    
    private var detailContent: some View {
        Group {
            if let habit = selectedHabit {
                HabitDetailView(habit: habit)
            } else {
                ContentUnavailableView(
                    "Select a Habit",
                    systemImage: "square.grid.2x2",
                    description: Text("Choose a habit to view its deatails and history")
                )
            }
        }
    }
}

struct HabitRow: View {
    let habit: Habit

    var body: some View {
            HStack {
                if let icon = habit.icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(Color(habit.color.color))
                        .frame(width: 30, height: 30)
                }
                
                VStack(alignment: .leading) {
                    Text(habit.title)
                        .font(.headline)
                    
                    Text(habit.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(habit.currentStreak())")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
    }
}

#Preview("Empty State") {
    HabitsView()
        .modelContainer(PreviewHelpers.previewContainer)
        .environmentObject(AppState())
}

#Preview("With Sample Data") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return HabitsView()
        .modelContainer(container)
        .environmentObject(AppState())
}
