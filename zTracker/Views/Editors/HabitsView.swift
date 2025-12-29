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
    
    @State private var showingArchive = false
    @State private var selectedHabit: Habit?
    @State private var showingDeleteAlert = false
    @State private var habitToDelete: Habit?
    
    var body: some View {
        NavigationSplitView {
            listContent
        } detail: {
            detailContent
        }
//        .sheet(isPresented: $showingArchive) { ArchiveView(selection: $selectedHabit) }
    }
    
    private var listContent: some View {
        List(selection: $selectedHabit) {
            activeHabitsSection
            
            if !activeHabits.isEmpty {
                archivedSection
            }
        }
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showingHabitEditor = true }) {
                    Label("Add Habit", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $appState.showingHabitEditor) { HabitEditorView() }
        
        .alert("Delete Habit", isPresented: $showingDeleteAlert, presenting: habitToDelete) { habit in
            Button("Cancel", role: .cancel) { habitToDelete = nil }
            Button("Delete", role: .destructive) {
                modelContext.delete(habit)
                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
            }
        } message: { habit in
            Text("Are you sure you want to delete '\(habit.title)'? This will also delete all of its history")
        }
    }
    
    private var activeHabitsSection: some View {
        Section("Active Habits") {
            ForEach(activeHabits) { habit in
                HabitRow(habit: habit)
                    .swipeActions(edge: .trailing) {
                        trailingSwipeActions(for: habit)
                    }
                    .swipeActions(edge: .leading) {
                        leadingSwipeActions(for: habit)
                    }
            }
        }
    }
    
    private var archivedSection: some View {
        Section("Archived") {
            Button { showingArchive = true } label: {
                HStack {
                    Text("View Archived Habits")
                    Spacer()
                    Text("\(archivedHabits.count)")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func trailingSwipeActions(for habit: Habit) -> some View {
        Button(role: .destructive) {
            habitToDelete = habit
            showingDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .buttonStyle(.glass)
        .tint(.red)
        
        Button {
            Task { habit.isArchived.toggle() }
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .buttonStyle(.glass)
        .tint(.orange)
    }
    
    @ViewBuilder
    private func leadingSwipeActions(for habit: Habit) -> some View {
        Button {
            appState.selectedHabit = habit
            appState.showingHabitEditor = true
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
        NavigationLink {
            HabitDetailView(habit: habit)
        } label: {
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
            }
            .padding(.vertical)
        }
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
