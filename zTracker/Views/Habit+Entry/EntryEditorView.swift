//
//  EntryEditorView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit
    let date: Date
    let existingEntry: HabitEntry?

    @State private var completed: Bool = false
    @State private var timeDurationSeconds: Int64?
    @State private var ratingValue: Int?
    @State private var numericValue: Double?
    @State private var note: String = ""
    
    @State private var updatedAt: Date?
        
    @State private var minMaxError = false
    
    init(habit: Habit, entry: HabitEntry? = nil, date: Date? = nil) {
        self.habit = habit
        self.existingEntry = entry
        self.date = entry?.date ?? date ?? today
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack() {
                    #if os(macOS)
                    HStack {
                        Image(systemName: habit.icon ?? "questionmark.circle")
                            .font(.title)
                        Text(habit.title)
                            .font(.title)
                    }
                    .frame(alignment: .top)
                    .foregroundStyle(habit.swiftUIColor)
                        
                    Divider()
                        .padding()

                    #endif
                        
                    dateSection
                        .glassEffect(in: .rect(cornerRadius: 16))
                        .glassEffect(in: .rect(cornerRadius: 16))
                        .padding(.horizontal)
                    
                    metricSection
                        .glassEffect(in: .rect(cornerRadius: 16))
                        .padding(.horizontal)
                    
                    noteSection
                        .glassEffect(in: .rect(cornerRadius: 16))
                        .padding([.bottom, .horizontal])
                    
                    Text("Last updated: \(updatedAt?.formatted(date: .abbreviated, time: .complete) ?? "now?")")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.horizontal)
                        .font(.caption)

                }
            }
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    HStack() {
                        Image(systemName: habit.icon ?? "questionmark.circle")
                            .symbolRenderingMode(.hierarchical)
                        Text(habit.title)
                            .font(.headline)
                    }
                }
                #endif
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) { saveEntry(); dismiss() }
                }
            }
            .presentationDetents([.medium, .large])
            .tint(habit.swiftUIColor)
            .onAppear { loadEntry() }
        }
    }
    
    private var dateSection: some View {
        VStack {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    
    private var metricSection: some View {
        VStack {
            switch habit.type {
            case .boolean(_):
                Toggle(isOn: $completed) {
                    Label(
                        completed ? "Completed" : "Mark Completed",
                        systemImage: completed ? "checkmark.circle.dotted" : "circle.dotted"
                    )
                }
                    .toggleStyle(.button)
                    .frame(maxWidth: .infinity)

            case .duration(_):
                durationPicker()

            case .rating(let min, let max, _):
                ratingPicker(min: min, max: max)

            case .numeric(let min, let max, let unit, _):
                numericPicker(min: min, max: max, unit: unit)
            }
            
        }
        .padding(.vertical)
    }
    
    private var noteSection: some View {
        VStack {
            TextField("Note", text: $note, axis: .vertical)
                .scrollContentBackground(.hidden)
                .autocorrectionDisabled(false)
                .lineLimit(1...3)
        }
        .padding()
    }

    
    private func loadEntry() {
        var entryToUse: HabitEntry?
        
        if let entry = existingEntry { entryToUse = entry
        } else {
            let day = Calendar.current.startOfDay(for: date)
            let habitID = habit.id
            let descriptor = FetchDescriptor<HabitEntry>(
                predicate: #Predicate { $0.habit?.id == habitID && $0.date == day}
            )
            entryToUse = try? habit.modelContext?.fetch(descriptor).first
        }
        
        completed = entryToUse?.completed ?? false
        timeDurationSeconds = entryToUse?.durationSeconds ?? 0
        ratingValue = entryToUse?.ratValue ?? 3
        numericValue = entryToUse?.numValue
        
        note = entryToUse?.note ?? ""
        updatedAt = entryToUse?.updatedAt ?? .now
    }
    
    @MainActor
    private func saveEntry() {
        Task {
            _ = habit.createOrUpdateEntry(
                for: date,
                completed: { if case .boolean = habit.type { return completed } else { return nil } }(),
                time: {
                    if case .duration = habit.type {
                        return Duration(secondsComponent: Int64(timeDurationSeconds ?? 0), attosecondsComponent: 0)
                } else { return nil } }(),
                numValue: { if case .numeric = habit.type { return numericValue } else { return nil } }(),
                ratValue: { if case .rating = habit.type { return ratingValue } else { return nil } }(),
                note: note.isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
                dismiss()
        }
    }
    
    private func ratingPicker(min: Int, max: Int) -> some View {
        HStack {
            ForEach(min...max, id: \.self) { value in
                let isFilled = value <= ratingValue ?? 3

                Image(systemName: isFilled ? "star.fill" : "star")
                    .font(.title)
                    .foregroundStyle(habit.swiftUIColor)
//                    .scaleEffect(isFilled ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: ratingValue)
                    .onTapGesture { ratingValue = value }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func durationPicker () -> some View {
        VStack {
            DatePicker("Duration", selection: Binding(
                        get: {
                            Date(timeInterval: TimeInterval(timeDurationSeconds ?? 0), since: unixEpoch)
                        },
                        set: { newDate in
                            timeDurationSeconds = Int64(newDate.timeIntervalSince(unixEpoch))
                        }
                       ), displayedComponents: .hourAndMinute)
            .labelsHidden()
            .datePickerStyle(.wheel)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func numericPicker(min: Double, max: Double, unit: String) -> some View {
        
        return VStack {
            HStack {
                TextField("Value", value: $numericValue, format: .number)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.trailing)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                Text(unit)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(minMaxError ? .red : .primary)
            .onChange(of: numericValue) { minMaxCheck(min: min, max: max) }

            if minMaxError { Text("Value outside min/max bounds").foregroundStyle(.red).font(.caption) }
        }
    }
    
    private func minMaxCheck(min: Double, max: Double) {
        if let numericValue = numericValue, (numericValue < min || numericValue > max) { minMaxError = true }
        else { minMaxError = false }
    }

}

#Preview("Sheet View") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let habitToShow = habits[1]
    
    let date = Date(timeInterval: 1000, since: .now)
    
    return Text("Parent Backgroudn View")
        .sheet(isPresented: .constant(true)) {
            EntryEditorView(habit: habitToShow, date: date)
//                .background(Color(habitToShow.swiftUIColor).gradient)
        }
        .modelContainer(container)
        
}

#Preview("Full Screen View") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let habitToShow = habits[2]
    
    return EntryEditorView(habit: habitToShow)
        .modelContainer(container)
        
}
