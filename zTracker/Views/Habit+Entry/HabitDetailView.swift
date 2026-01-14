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
    @Environment(\.modelContext) private var context
    
    @State private var entries: [HabitEntry] = []
    
    @State private var showingHabitEditor = false
    
    @State private var showingDatePicker = false
    @State private var selectedDateForNewEntry = today
    @State private var dateToLog: Date?
    
    @AppStorage("habitsTimeframe") private var summaryTimeframe: Timeframe = .week
    
    let habit: Habit
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack() {
                    HabitDetailSection(habit: habit, summaryTimeframe: summaryTimeframe)
                    
                    ChartSection(habit: habit, entries: entries, summaryTimeframe: summaryTimeframe)
                        .glassEffect(in: .rect(cornerRadius: 16))
                    
                    RecentEntriesSection(habit: habit, entries: entries, summaryTimeframe: summaryTimeframe)
                        .glassEffect(in: .rect(cornerRadius: 16))
                                        
                    ToggleHabitArchive(habit: habit)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red, lineWidth: 1))
                        .glassEffect(.regular.tint(.red.opacity(0.5)), in: .rect(cornerRadius: 16))
                        .padding(.top)
                }
                .padding()
            }
            .background(movingLinearGradient(selectedColor: habit.swiftUIColor))
            
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log Entry", systemImage: "plus") { showingDatePicker = true }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button("Edit Habit", systemImage: "slider.horizontal.3") { showingHabitEditor = true }
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
            .popover(isPresented: $showingDatePicker) {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { Calendar.current.startOfDay(for: selectedDateForNewEntry) },
                        set: { selectedDateForNewEntry = Calendar.current.startOfDay(for: $0) }
                    ),
                    displayedComponents: .date
                )
                    .datePickerStyle(.graphical)
                    .padding()
                    .presentationDetents([.medium])
                Button("Create Entry", role: .confirm) { showingDatePicker = false; dateToLog = selectedDateForNewEntry }
            }
            
            .sheet(item: $dateToLog) {
                date in EntryEditorView(habit: habit, date: date)
//                    .background(Color(habit.swiftUIColor).gradient)
            }
                        
            .sheet(isPresented: $showingHabitEditor) { HabitEditorView(habit: habit) }
            
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
        do { entries = try context.fetch(descriptor) }
        catch {
            print("Failed to fetch entries: \(error)")
            entries = []
        }
    }
}

struct HabitDetailSection: View {
    let habit: Habit
    let summaryTimeframe: Timeframe
    
    private let columns: [GridItem] = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    
    
    var body: some View {
        let averageInfo = HabitAverage(habit: habit, days: summaryTimeframe.days)

        VStack {
            HStack {
                if let icon = habit.icon {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(Color(habit.swiftUIColor))
                }
                Text(habit.title)
                    .font(.largeTitle)
                    .foregroundStyle(Color(habit.swiftUIColor))
            }
            Text(habit.type.displayName)
                .font(.title3)
                .foregroundStyle(Color(habit.swiftUIColor).secondary)
        }
        
        LazyVGrid(columns: columns) {
            StatCard(
                title: "Current Streak",
                value: "\(habit.currentStreak())",
                icon: "flame",
                caption: ""
            )
            StatCard(
                title: "Completion",
                value: habit.completionRate(days: summaryTimeframe.days).formatted(.percent.precision(.fractionLength(0))),
                icon: "chart.xyaxis.line",
                caption: "this \(summaryTimeframe.rawValue)"
            )
            StatCard(
                title: "Total Entries",
                value: "\(habit.entries.count)",
                icon: "number",
                caption: "all time"
            )
            StatCard(
                title: "Summary",
                value: averageInfo.value,
                icon: "sum",
                caption: "\(averageInfo.caption) this \(summaryTimeframe.rawValue)"
            )
        }
    }
}

struct ChartSection: View {
    let habit: Habit
    let entries: [HabitEntry]
    let summaryTimeframe: Timeframe
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(summaryTimeframe.days) Day Progress")
                .font(.headline)
                .padding()
            
            // TODO: zoom in charts
            Chart {
                ForEach(entries.prefix(summaryTimeframe.days)) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Value", normalizedValue(for: entry))
                    )
                    .foregroundStyle(Color(habit.swiftUIColor))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding()
        }
    }
    
    private func normalizedValue(for entry: HabitEntry) -> Double {
        switch habit.type {
        case .boolean: return entry.completed == true ? 1 : 0
        case .duration: return Double(entry.time?.components.seconds ?? 0) / 3600
        case .rating(let min, let max, _): return Double(entry.ratValue ?? min) / Double(max)
        case .numeric(let min, _, _, _): return entry.numValue ?? min
        }
    }
}

struct RecentEntriesSection: View {
    let habit: Habit
    let entries: [HabitEntry]
    let summaryTimeframe: Timeframe

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Entries")
                .font(.headline)
            
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Entries Yet",
                    systemImage: "calendar",
                    description: Text("Log your first entry to see history here")
                )
                .padding()
            } else {
                ForEach(entries.prefix(summaryTimeframe.days)) { entry in
                    EntryRowView(habit: habit, entry: entry)
                //                    .background(Color(habit.swiftUIColor).gradient)
                }
            }
        }
        .padding()
    }
}

struct EntryRowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var entryToEdit: HabitEntry?
    @State private var showingDeleteAlert = false
    
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
        .contentShape(.rect)
        .onTapGesture { entryToEdit = entry }
        
        .contextMenu {
            Button("Delete Entry", systemImage: "trash", role: .destructive) { showingDeleteAlert = true }
        }
        
        .alert("Delete Entry?", isPresented: $showingDeleteAlert, presenting: entry) { entry in
            Button("Delete", systemImage: "trash.fill", role: .destructive) {
                context.delete(entry)
            }
            Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
        } message: {_ in
            Text("This action cannot be undone.")
        }
        
        .sheet(item: $entryToEdit) {
            entry in EntryEditorView(habit: habit, entry: entry)
        }
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
        
        let habitToShow = habits[3]
        
        return HabitDetailView(habit: habitToShow)
            .modelContainer(container)
            
    }
}

