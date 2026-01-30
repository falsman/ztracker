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
    
    var body: some View {
        VStack {
            HeaderInfo(displayedRows: $displayedRows, selection: $selection)
            
            EntriesTable(
                displayedRows: $displayedRows,
                selection: $selection,
                sortOrder: $sortOrder,
                habits: habits
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
        }
        .padding()
    }
}

private struct EntriesTable: View {
    @Binding var displayedRows: [DayRow]
    @Binding var selection: Set<DayRow.ID>
    @Binding var sortOrder: [KeyPathComparator<DayRow>]
    var habits: [Habit]
    
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
            }
            
            // Dynamic columns for each habit (editable cells)
            TableColumnForEach(habits) { habit in
                TableColumn(habit.title) { (row: DayRow) in
                    CellEditor(habit: habit, date: row.date)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        // .tableStyle(.inset)
        .onChange(of: sortOrder) { displayedRows.sort(using: sortOrder) }
    }
}

private struct DayRow: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
}

private struct CellEditor: View {
    @Environment(\.modelContext) private var context
    
    let habit: Habit
    let date: Date
    
    var body: some View {
        switch habit.type {
        case .boolean:
            Toggle("", isOn: bindingForBoolean(habit: habit, date: date))
                .labelsHidden()
            
        case .duration:
            // Edit minutes as integer; convert to seconds
            HStack(spacing: 6) {
                TextField(
                    "0",
                    value: bindingForDurationMinutes(habit: habit, date: date),
                    format: .number.precision(.fractionLength(0))
                )
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 44)
                Text("min")
                    .foregroundStyle(.secondary)
            }
            
        case .rating(let minValue, let maxValue, _):
            let binding = bindingForRating(habit: habit, date: date, minValue: minValue, maxValue: maxValue)
            HStack {
                Stepper(value: binding, in: minValue...maxValue) {
                    Text("\(binding.wrappedValue)")
                }
            }
            
        case .numeric(let minValue, let maxValue, let unit, _):
            HStack {
                TextField(
                    "0",
                    value: bindingForNumeric(habit: habit, date: date, minValue: minValue, maxValue: maxValue),
                    format: .number
                )
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 50)
                Text(unit)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Bindings (create-or-update on write, save)
    private func bindingForBoolean(habit: Habit, date: Date) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                habit.entry(for: date)?.completed ?? false
            },
            set: { newValue in
                let day = Calendar.current.startOfDay(for: date)
                _ = habit.createOrUpdateEntry(for: day, completed: newValue)
                saveContext()
            }
        )
    }
    
    // Store/edit minutes as Double; convert to Duration seconds in model
    private func bindingForDurationMinutes(habit: Habit, date: Date) -> Binding<Double> {
        Binding<Double>(
            get: {
                let seconds = Double(habit.entry(for: date)?.durationSeconds ?? 0)
                return seconds / 60.0
            },
            set: { newMinutes in
                let clamped = Swift.max(0, newMinutes)
                let seconds = Int(clamped.rounded()) * 60
                let day = Calendar.current.startOfDay(for: date)
                _ = habit.createOrUpdateEntry(for: day, time: .seconds(seconds))
                saveContext()
            }
        )
    }
    
    private func bindingForRating(habit: Habit, date: Date, minValue: Int, maxValue: Int) -> Binding<Int> {
        Binding<Int>(
            get: {
                habit.entry(for: date)?.ratValue ?? minValue
            },
            set: { newValue in
                let clamped = Swift.min(Swift.max(newValue, minValue), maxValue)
                let day = Calendar.current.startOfDay(for: date)
                _ = habit.createOrUpdateEntry(for: day, ratValue: clamped)
                saveContext()
            }
        )
    }
    
    private func bindingForNumeric(habit: Habit, date: Date, minValue: Double, maxValue: Double) -> Binding<Double> {
        Binding<Double>(
            get: {
                habit.entry(for: date)?.numValue ?? 0
            },
            set: { newValue in
                let clamped = Swift.min(Swift.max(newValue, minValue), maxValue)
                let day = Calendar.current.startOfDay(for: date)
                _ = habit.createOrUpdateEntry(for: day, numValue: clamped)
                saveContext()
            }
        )
    }
    
    private func saveContext() {
        do { try context.save() }
        catch { print("Failed saving context: \(error)") }
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

#Preview("Content View") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return TableView()
            .modelContainer(container)
}
