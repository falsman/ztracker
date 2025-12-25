//
//  EntryEditorView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    @State private var entry: HabitEntry?
    
    @State private var completed = false
    @State private var timeHours = 0
    @State private var timeMinutes = 0
    @State private var timeDuration: Duration = .zero
    @State private var numericValue = 0.00
    @State private var rating = 3
    @State private var note = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Entry") {
                    switch habit.type {
                    case .boolean: Toggle("Completed", isOn: $completed)
                    case .hours:
                        HStack {
                            TextField("Hours", value: $timeHours, format: .number)
                            TextField("Minutes", value: $timeMinutes, format: .number)
                        }
                    case .rating(let min, let max):
                        VStack {
                            Text("\(rating)/\(max)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack {
                                ForEach(min...max, id: \.self) { value in
                                    Button(action: { rating = value }) {
                                        Image(systemName: value <= rating ? "star.fill" : "star")
                                            .font(.title)
                                            .foregroundStyle(value <= rating ? .yellow : .gray)
                                    }
                                    .buttonStyle(.glass)
                                }
                            }
                        }
                        // .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    case .numeric(let min, let max, let unit):
                        VStack {
                            Text(String(format: "%.2f %@", numericValue, unit))
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            TextField("Value", value: $numericValue, format: .number)
                        }
                        .padding(.vertical)
                    }
                }
                
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
            }
            .navigationTitle(habit.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.glass)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .buttonStyle(.glass)
                }
            }
        }
        .onAppear { loadEntry() }
        .presentationDetents([.medium, .large])
    }
    
    private func loadEntry() {
        if let existingEntry = habit.entry(for: date) {
            entry = existingEntry
            completed = existingEntry.completed ?? false
            
            if let time = existingEntry.time {
                let seconds = Int(time.components.seconds)
                timeHours = seconds / 3600
                timeMinutes = (seconds % 3600) / 60 
            }
            numericValue = existingEntry.value ?? 0
            rating = existingEntry.rating ?? 3
            note = existingEntry.note ?? ""
        } else { entry = nil }
    }
    
    private func saveEntry() {
        Task {
            let time: Duration?
            if case .hours = habit.type {
                let seconds = timeHours * 3600 + timeMinutes * 60
                time = .seconds(seconds)
            } else { time = nil }
            
            
            _ = await StorageManager.shared.createOrUpdateEntry(
                for: habit,
                date: date,
                completed: habit.type == .boolean ? completed : nil,
                time: time,
                value: value,
                rating: ratingValue,
                note: note.isEmpty ? nil : note
                )
            
            await MainActor.run { dismiss() }
        }
    }
}
