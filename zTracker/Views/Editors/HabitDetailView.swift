//
//  HabitDetailView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData
import Charts

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    
    @State private var entries: [HabitEntry] = []
    
    @State private var showingDatePicker = false
    @State private var selectedDateForNewEntry = today
    @State private var entryToEdit: HabitEntry?
    @State private var dateToLog: Date?
    
    let habit: Habit
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack {
                        HStack {
                            if let icon = habit.icon {
                                Image(systemName: icon)
                                    .font(.title)
                                    .foregroundStyle(Color(habit.color.color))
                            }
                            
                            Text(habit.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        Text(habit.type.displayName)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    HStack {
                        StatCard(
                            title: "Current Streak",
                            value: "\(habit.currentStreak())",
                            icon: "flame",
                            color: .clear
                        )
                        StatCard(
                            title: "Completion Date",
                            value: "\(Int(habit.completionRate() * 100))%",
                            icon: "chart.xyaxis.line",
                            color: habit.color.color
                        )
                        StatCard(
                            title: "Total Entries",
                            value: "\(habit.entries.count)",
                            icon: "number",
                            color: habit.color.color
                        )
                    }
                    .padding(.horizontal)
                    
                    ChartSection()
                    
                    RecentEntriesSection()
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log Entry", systemImage: "plus") { showingDatePicker = true }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Edit Habit", systemImage: "slider.horizontal.3") { appState.showingHabitEditor = true }
                }
            }
            .popover(isPresented: $showingDatePicker) {
                DatePicker("Select Date", selection: $selectedDateForNewEntry, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .presentationDetents([.medium]) // Limits the height on iOS
                Button("Create Entry", role: .confirm) { showingDatePicker = false; dateToLog = selectedDateForNewEntry }
            }
            
            .padding()
            
            .sheet(item: $dateToLog) { date in EntryEditorView(habit: habit, date: date) }
            
            .sheet(item: $entryToEdit) { entry in EntryEditorView(habit: habit, entry: entry) }
            
            .sheet(isPresented: $appState.showingHabitEditor) { HabitEditorView(habit: habit) }
            
            .task { loadEntries() }
            .onChange(of: habit.entries) { loadEntries() }
        }
    }
    
    private func loadEntries() {
        let habitID = habit.id
        let descriptor = FetchDescriptor<HabitEntry>(
            predicate: #Predicate<HabitEntry> { entry in entry.habit?.id == habitID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do { entries = try modelContext.fetch(descriptor) }
        catch {
            print("Failed to fetch entries: \(error)")
            entries = []
        }
    }
    
    @ViewBuilder
    private func ChartSection() -> some View {
        VStack(alignment: .leading) {
            Text("30 Day Progress")
                .font(.headline)
                .padding(.horizontal)
            
            // TODO: zoom in charts
            Chart {
                ForEach(entries.prefix(30)) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Value", normalizedValue(for: entry))
                    )
                    .foregroundStyle(Color(habit.color.color))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 16))
        }
    }
    
    private func normalizedValue(for entry: HabitEntry) -> Double {
        switch habit.type {
        case .boolean: return entry.completed == true ? 1 : 0
        case .duration: return Double(entry.time?.components.seconds ?? 0) / 3600
        case .rating(let min, let max): return Double(entry.ratValue ?? min) / Double(max)
        case .numeric(let min, _, _): return entry.numValue ?? min
        }
    }
    
    @ViewBuilder
    private func RecentEntriesSection() -> some View {
        VStack(alignment: .leading) {
            Text("Recent Entries")
                .font(.headline)
                .padding(.horizontal)
            
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Entries Yet",
                    systemImage: "calendar",
                    description: Text("Log your first entry to see history here")
                )
                .padding()
            } else {
                ForEach(entries.prefix(10)) { entry in
                    EntryRow(habit: habit, entry:entry)
                        .onTapGesture { entryToEdit = entry  }
                        .padding(Edge.Set.horizontal)
                }
            }
        }
    }
}
    
    
struct EntryRow: View {
    let habit: Habit
    let entry: HabitEntry
    
    var body: some View {
        HStack {
                VStack(alignment: .leading) {
                    Text(entry.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let note = entry.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text(entry.displayValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 16))
    }
}

extension Date: @retroactive Identifiable {
    public var id: Self { self }
}
    
    
#Preview("With Sample Data") {
    NavigationStack {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        let habitToShow = habits[0]
        
        return HabitDetailView(habit: habitToShow)
            .modelContainer(container)
            .environmentObject(AppState())
    }
}
