//
//  TableView.swift
//  zTracker
//
//  Created by Jia Sahar on 1/28/26.
//

import SwiftUI
import SwiftData
import Foundation

struct TableView: View {
    @Environment(\.modelContext) private var context
    
    // One column per active (non-archived) habit
    @Query(
        filter: #Predicate<Habit> { $0.isArchived == false },
        sort: [ SortDescriptor(\Habit.sortIndex, order: .forward) ]
    )
    private var habits: [Habit]
    
    // Selection and sorting (native)
    @State private var selection = Set<DayRow.ID>() // Date as ID
    @State private var sortOrder: [KeyPathComparator<DayRow>] = [
        .init(\.date, order: .reverse) // newest first by default
    ]
    
    // Backing storage for the table’s rows that we can sort in-place
    @State private var displayedRows: [DayRow] = []
    
    // Editor presentation
    @State private var editorDate: Date?
    @State private var showingNewDay = false
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderInfo(
                displayedRows: $displayedRows,
                selection: $selection,
                onNewDay: { showingNewDay = true }
            )
            
            EntriesTable(
                displayedRows: $displayedRows,
                selection: $selection,
                sortOrder: $sortOrder,
                habits: habits,
                onDoubleClickDate: { date in editorDate = date },
                onDoubleClickCell: { date in editorDate = date }
            )
        }
        .navigationTitle("Entries")
        .task {
            rebuildRows()
            displayedRows.sort(using: sortOrder)
        }
        .onChange(of: habits.map(\.id)) {
            rebuildRows()
            displayedRows.sort(using: sortOrder)
        }
        .sheet(item: $editorDate) { date in
            DayEditorView(date: date, habits: habits)
        }
        .sheet(isPresented: $showingNewDay) {
            DayEditorView(
                date: today,
                habits: habits
            )
        }
    }
    
    // MARK: - Build all rows from data
    private func rebuildRows() {
        let cal = Calendar.current
        // Collect all entry dates across all active habits, normalize to start of day
        let allDates = habits.flatMap { habit in
            habit.entries.map { cal.startOfDay(for: $0.date) }
        }
        let uniqueDates = Array(Set(allDates))
        let rows = uniqueDates.map { DayRow(date: $0) }
        displayedRows = rows
    }
}

private struct HeaderInfo: View {
    @Binding var displayedRows: [DayRow]
    @Binding var selection: Set<DayRow.ID>
    var onNewDay: () -> Void
    
    var body: some View {
        HStack {
            Text("Rows: \(displayedRows.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let minDate = displayedRows.map(\.date).min(),
               let maxDate = displayedRows.map(\.date).max() {
                Text("Range: \(minDate.formatted(date: .abbreviated, time: .omitted)) – \(maxDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !selection.isEmpty {
                Text("\(selection.count) selected")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button {
                onNewDay()
            } label: {
                Label("New Day", systemImage: "calendar.badge.plus")
            }
            .buttonStyle(.glassProminent)
        }
        .padding()
    }
}

private struct EntriesTable: View {
    @Binding var displayedRows: [DayRow]
    @Binding var selection: Set<DayRow.ID>
    @Binding var sortOrder: [KeyPathComparator<DayRow>]
    var habits: [Habit]
    var onDoubleClickDate: (Date) -> Void
    var onDoubleClickCell: (Date) -> Void
    
    var body: some View {
        Table(
            displayedRows,
            selection: $selection,
            sortOrder: $sortOrder
        ) {
            // Date column: sortable via key path
            TableColumn("Date", value: \.date) { (row: DayRow) in
                Text(row.date, format: .dateTime.year().month().day())
                    .font(.body.monospacedDigit())
                    .contentShape(.rect)
                    .modifier(DoubleClickHandler { onDoubleClickDate(row.date) })
            }
            
            // Dynamic columns for each habit (read-only cells; edit via popup)
            TableColumnForEach(habits) { habit in
                TableColumn(habit.title) { (row: DayRow) in
                    DisplayCell(habit: habit, date: row.date)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                        .modifier(DoubleClickHandler { onDoubleClickCell(row.date) })
                }
            }
        }
        .onChange(of: sortOrder) { displayedRows.sort(using: sortOrder) }
    }
}

// Helper modifier to attach a double-click gesture on macOS, single tap elsewhere
private struct DoubleClickHandler: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onTapGesture(count: 2, perform: action)
        #else
        content.onTapGesture(perform: action)
        #endif
    }
}

private struct DayRow: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
}

// Read-only cell content that reflects the current entry (or empty)
private struct DisplayCell: View {
    let habit: Habit
    let date: Date
    
    var body: some View {
        if let entry = habit.entry(for: date) {
            Text(entry.displayValue)
                .foregroundStyle(.primary)
        } else {
            Text("—")
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Day Editor (edit all active habits for a day, and allow creating a new row)
private struct DayEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var selectedDate: Date
    let habits: [Habit]
    
    init(date: Date, habits: [Habit]) {
        self._selectedDate = State(initialValue: Calendar.current.startOfDay(for: date))
        self.habits = habits
    }
    
    var body: some View {
        ScrollView {
            if habits.isEmpty {
                ContentUnavailableView {
                    Label("No Active Habits", systemImage: "square.grid.2x2")
                } description: {
                    Text("Create or unarchive habits to edit entries.")
                }
            } else {
                ForEach(habits) { habit in
                    HStack {
                        Text(habit.title)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        HabitValueRow(habit: habit, date: selectedDate)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                    }
                    .glassEffect(in: .rect(cornerRadius: 16))
                }
            }
        }
        .padding()
        .navigationTitle("Edit Day")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark", role: .confirm) {
                    ensureEntriesForAllHabits()
                    do { try context.save() } catch { print("Save failed: \(error)") }
                    dismiss()
                }
            }
        }
    }
    
    private func ensureEntriesForAllHabits() {
        let day = Calendar.current.startOfDay(for: selectedDate)
        for habit in habits {
            _ = habit.createOrUpdateEntry(for: day)
        }
    }
}

// Editors per habit type, writing via createOrUpdateEntry (updates or creates)
private struct HabitValueRow: View {
    @Environment(\.modelContext) private var context
    
    let habit: Habit
    let date: Date
    
    @State private var minMaxError: Bool = false
    
    var body: some View {
        MetricEntrySection(
            completed: bindingForCompleted(),
            timeDurationSeconds: bindingForDurationSeconds(),
            ratingValue: bindingForRating(),
            numericValue: bindingForNumeric(),
            minMaxError: $minMaxError,
            habit: habit
        )
    }
    
    private func bindingForCompleted() -> Binding<Bool> {
        Binding<Bool>(
            get: { habit.entry(for: date)?.completed ?? false },
            set: { newValue in
                let day = Calendar.current.startOfDay(for: date)
                _ = habit.createOrUpdateEntry(for: day, completed: newValue)
                save()
            }
        )
    }
    
    private func bindingForDurationSeconds() -> Binding<Int64?> {
        Binding<Int64?>(
            get: { habit.entry(for: date)?.durationSeconds },
            set: { newSeconds in
                let seconds = Int64(newSeconds ?? 0)
                let day = Calendar.current.startOfDay(for: date)
                let duration = Duration(secondsComponent: seconds, attosecondsComponent: 0)
                _ = habit.createOrUpdateEntry(for: day, time: duration)
                save()
            }
        )
    }
    
    private func bindingForRating() -> Binding<Int?> {
        Binding<Int?>(
            get: { habit.entry(for: date)?.ratValue },
            set: { newValue in
                let day = Calendar.current.startOfDay(for: date)
                _ = habit.createOrUpdateEntry(for: day, ratValue: newValue)
                save()
            }
        )
    }
    
    private func bindingForNumeric() -> Binding<Double?> {
        Binding<Double?>(
            get: { habit.entry(for: date)?.numValue },
            set: { newValue in
                let day = Calendar.current.startOfDay(for: date)
                _ = habit.createOrUpdateEntry(for: day, numValue: newValue)
                save()
            }
        )
    }
    
    private func save() {
        do { try context.save() } catch { print("Failed saving context: \(error)") }
    }
}

#Preview("Table View") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return TableView()
        .modelContainer(container)
}

#Preview("Day Editor View") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return DayEditorView(date: Date(), habits: habits)
        .modelContainer(container)
}

#Preview("Habit Value Row") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return HabitValueRow(habit:habits.first! , date: Date())
        .modelContainer(container)
}

