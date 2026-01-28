//
//  HabitsView 2.swift
//  zTracker
//
//  Created by Jia Sahar on 12/17/25.
//

import SwiftUI
import SwiftData
import UserNotifications

enum HabitMode {
    case active
    case archived
}

struct HabitsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @AppStorage("habitsTimeframe") private var summaryTimeframe: Timeframe = .week
    @AppStorage("userThemeColor") private var userThemeColor: AppColor = .theme
    
    @Query(sort: \Habit.sortIndex) private var allHabits: [Habit]

    var shownHabits: [Habit] {
        allHabits.filter {
            habitMode == .active ? !$0.isArchived : $0.isArchived
        }
    }
    
    @State private var selectedHabit: Habit?
    @State private var showingHabitAdder = false
    
    @State private var habitToEdit: Habit?
    
    @State private var habitMode: HabitMode = .active

    var body: some View {
        NavigationSplitView { listContent }
        detail: { detailContent }
    }
    
    private var listContent: some View {
        List(selection: $selectedHabit) {
            ForEach(shownHabits) { habit in HabitRow(habit: habit) { selectedHabit = habit }
                
                .listRowSeparator(.hidden)
                .listRowBackground(Color(.clear))
                
                .contextMenu {
                    Button("Edit Habit", systemImage: "pencil") { habitToEdit = habit }
                    .buttonStyle(.glass)
                    .tint(.blue)
                    
                    Divider()
                    
                    if !habit.isArchived { ArchiveHabitButton(habit: habit) } else { UnarchiveHabitButton(habit: habit, totalHabitsCount: allHabits.count) }
                }
            }
            .onMove { from, to in
                var reordered = shownHabits
                reordered.move(fromOffsets: from, toOffset: to)

                for (newIndex, habit) in reordered.enumerated() {
                    habit.sortIndex = newIndex
                }
            }
            
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        
        .navigationTitle(habitMode == .active ? "Habits" : "Archived Habits")
        .navigationSplitViewColumnWidth(
            min: 150, ideal: 200, max: 400)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .background(MovingLinearGradient(selectedColor: userThemeColor.color))
        #endif
        
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingHabitAdder = true }) {
                    Label("Add Habit", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { habitMode = habitMode == .active ? .archived : .active }) {
                    Label(
                        habitMode == .active ? "Show Archived" : "Show Active",
                        systemImage: habitMode == .active ? "archivebox" : "square.grid.2x2"
                    )
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Picker("Summary Range", systemImage: "ellipsis.calendar", selection: $summaryTimeframe) {
                    ForEach(Timeframe.allCases) { timeframe in
                        Text(timeframe.rawValue)
                            .tag(timeframe)
                    }
                }
            }
        }
        .toolbarBackground(.hidden)
        
        .sheet(isPresented: $showingHabitAdder) { HabitEditorView() }
        .sheet(item: $habitToEdit) { habit in HabitEditorView(habit: habit) }

    }
    
    private var detailContent: some View {
        Group {
            if let habit = selectedHabit {
                HabitDetailView(habit: habit)
            } else {
                ContentUnavailableView {
                    Label("Select a Habit", systemImage: "square.grid.2x2")
                } description: {
                    Text("Choose a habit to view its deatails and history.")
                }
            }
        }
    }
}

struct ArchiveHabitButton: View {
    let habit: Habit
    
    var body: some View {
        Button("Archive Habit", systemImage: "archivebox") {
            habit.isArchived = true
            habit.sortIndex = -habit.sortIndex
        }
    }
}

struct UnarchiveHabitButton: View {
    let habit: Habit
    let totalHabitsCount: Int
    
    var body: some View {
        Button("Unarchive Habit", systemImage: "arrow.up.bin") {
            habit.isArchived = false
            habit.sortIndex = totalHabitsCount + 1
        }
    }
}

struct HabitRow: View {
    @AppStorage("habitsTimeframe") private var summaryTimeframe: Timeframe = .week

    let habit: Habit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if let icon = habit.icon {
                    ZStack {
                        Circle()
                            .trim(from: 0, to: habit.goalProgress().rate)
                            .fill(Color(habit.swiftUIColor).secondary)
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text(habit.title)
                    Text(habit.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                let averageInfo = HabitAverage(habit: habit, days: summaryTimeframe.days)
                VStack(alignment: .trailing) {
                    Text(averageInfo.value)
                    Text(averageInfo.caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .glassEffect(in: .rect(cornerRadius: 16))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Content View") {
    let container = PreviewHelpers.previewContainer

    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }

    try? container.mainContext.save()

    return ContentView()
        .modelContainer(container)
}

#Preview("Habits View") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return HabitsView()
        .modelContainer(container)
        
}

#Preview("Habit Row") {
    let container = PreviewHelpers.previewContainer
    let habits = PreviewHelpers.makeHabits()
    
    habits.forEach { container.mainContext.insert($0) }
    try? container.mainContext.save()
    
    return HabitRow(habit: habits[2], onTap: {})
        .modelContainer(container)
}
