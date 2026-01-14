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
        
    @State private var completed = false
    @State private var timeHours = 0
    @State private var timeMinutes = 0
    @State private var timeDuration: Duration = .zero
    @State private var ratingValue = 1
    @State private var numericValue = 0.00
    @State private var note = ""
    @State private var datePicker = today
    
    init(habit: Habit, entry: HabitEntry? = nil, date: Date? = nil) {
        self.habit = habit
        self.existingEntry = entry
        self.date = entry?.date ?? date ?? today
    }
    
    var body: some View {
        NavigationStack {
                Form {
                    Section {
                        LabeledContent("Date", value: date.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                    
                    Section(habit.type.displayName) {
                        switch habit.type {
                        case .boolean: Toggle("Mark Completed", isOn: $completed)
                                .toggleStyle(.button)
                                .frame(maxWidth: .infinity)
                            
                        case .duration: durationPicker()

                        case .rating(let min, let max): ratingPicker(min: min, max: max)
                            
                        case .numeric(_, _, let unit):
//                            VStack {
                            HStack {
                                    TextField("Value", value: $numericValue, format: .number.precision(.fractionLength(2)))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.trailing)
                                    Text(unit)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
//                                Text(String(format: "%.2f %@", numericValue, unit))
//                                    .font(.title2)
//                                    .fontWeight(.semibold)
//                                
//                                TextField("Value", value: $numericValue, format: .number)
//                            }
                            .padding(.vertical)
                        }
                    }
                    
                    
                    Section("Note") {
                        TextEditor(text: $note)
                            .frame(height: 100)

                    }
                }
                .navigationTitle(habit.title)
                .glassEffect(.regular.tint(Color(habit.color.color)), in: .rect(cornerRadius: 16))
            
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveEntry(); dismiss() }
                    }
                }
            }
            .onAppear { loadEntry() }
            .presentationDetents([.medium])
            .tint(habit.color.color)

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
            
        if let seconds = entryToUse?.time?.components.seconds {
            timeHours = Int(seconds) / 3600
            timeMinutes = (Int(seconds) % 3600) / 60
        } else {
            timeHours = 0
            timeMinutes = 0
        }
        ratingValue = entryToUse?.ratValue ?? 3
        numericValue = entryToUse?.numValue ?? 0
        note = entryToUse?.note ?? ""
    }
    
    func updateDuration() {
        let totalSeconds = (timeHours * 3600) + (timeMinutes * 60)
        timeDuration = .seconds(totalSeconds)
    }
    
    @MainActor
    private func saveEntry() {
        Task {
            _ = habit.createOrUpdateEntry(
                for: date,
                completed: { if case .boolean = habit.type { return completed } else { return nil } }(),
                time: { if case .duration = habit.type { return .seconds(timeHours * 3600 + timeMinutes * 60) } else { return nil } }(),
                numValue: { if case .numeric = habit.type { return numericValue } else { return nil } }(),
                ratValue: { if case .rating = habit.type { return ratingValue } else { return nil } }(),
                note: note.isEmpty ? nil : note
            )
            
                dismiss()
        }
    }
    
    private func ratingPicker(min: Int, max: Int) -> some View {
        HStack {
            ForEach(min...max, id: \.self) { value in
                Image(systemName: value <= ratingValue ? "star.fill" : "star")
                    .font(.title)
                    .foregroundStyle(value <= ratingValue ? habit.color.color : .secondary)
                    .contentShape(Rectangle())
                    .onTapGesture { ratingValue = value }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func durationPicker () -> some View {
        HStack {
            Picker("Hours", selection: $timeHours) {
                ForEach(0..<24) { hour in
                    Text("\(hour)").tag(hour)
                }
            }
            #if os(iOS)
            .pickerStyle(.wheel)
            #endif
                                            
            Divider()
            
            Picker("Minutes", selection: $timeMinutes) {
                ForEach(0..<60) { minute in
                    Text("\(minute)").tag(minute)
                }
            }
            #if os(iOS)
            .pickerStyle(.wheel)
            #endif
            
        }
        .onChange(of: timeHours) { updateDuration() }
        .onChange(of: timeMinutes) { updateDuration() }
    }
}



#Preview("With Sample Data") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let habitToShow = habits[1]
    
    return EntryEditorView(habit: habitToShow)
        .modelContainer(container)
        .environmentObject(AppState())
}
