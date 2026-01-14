//
//  QuickEntryEditorView.swift
//  zTracker
//
//  Created by Jia Sahar on 1/9/26.
//

import SwiftUI

struct QuickEntryEditorView: View {
    let habit: Habit
    let date: Date
    
    @State private var completed: Bool = false
    @State private var ratingValue: Int = 0
    @State private var numericValue: Double = 0
    @State private var durationValue: Int = 0
    
    var body: some View {
        Group {
            switch habit.type {
            case .boolean:
                Toggle("Toggle \(habit.title)", isOn: $completed)
                    .onChange(of: completed) { saveEntry(completed: completed) }
                
            case .rating(let min, let max, _):
                Stepper("\(habit.title), Step: 1", value: $ratingValue, in: min...max)
                    .onChange(of: ratingValue) { saveEntry(rating: ratingValue) }
                
            case .numeric(let min, let max, let unit, _):
                let step = Int((max - min) / 10)
                Stepper("\(habit.title) in \(unit), Step: \(step)", value: $numericValue, in: min...max, step: Double(step))
                    .onChange(of: numericValue) { saveEntry(numeric: numericValue) }
                
            case .duration:
                Stepper("\(habit.title), Step: 1 min", value: $durationValue, in: 1...1440, step: 1)
                    .onChange(of: durationValue) { saveEntry(durationSeconds: durationValue * 60) }
            }
        }
        .onAppear { loadEntry() }
    }
    
    
    private func loadEntry() {
        let entry = habit.entry(for: date)
        
        completed = entry?.completed ?? false
        ratingValue = entry?.ratValue ?? 0
        numericValue = entry?.numValue ?? 0
        durationValue = Int((entry?.time?.components.seconds ?? 0) / 60)
    }
    
    @MainActor
    private func saveEntry(
        completed: Bool? = nil,
        rating: Int? = nil,
        numeric: Double? = nil,
        durationSeconds: Int? = nil
    ) {
        _ = habit.createOrUpdateEntry(
            for: date,
            completed: completed,
            time: durationSeconds.map { .seconds($0) },
            numValue: numeric,
            ratValue: rating
        )
    }
}
