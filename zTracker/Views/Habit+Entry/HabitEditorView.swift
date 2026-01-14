//
//  HabitEditorView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let existingHabit: Habit?
    
    @State private var title = ""
    @State private var selectedType: HabitType = .boolean
    @State private var selectedColor: RGBValues = .init(r: 0.0, g: 0.9, b: 1.0, a: 1.0)
    @State private var icon = ""
    @State private var reminder: Date?
    
    @State private var ratingMin = 1
    @State private var ratingMax = 5
    
    @State private var numericMin = 0.00
    @State private var numericMax = 100.00
    @State private var numericUnit = "units"
    
    @State private var navTitle = "New Habit"
    @State private var showDeleteAlert = false

    
    init(habit: Habit? = nil) { self.existingHabit = habit }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Habit Name", text: $title)
                    
                    Picker("Type", selection: $selectedType) {
                        Text("Checkmark").tag(HabitType.boolean)
                        Text("Duration").tag(HabitType.duration)
                        Text("Rating").tag(HabitType.rating(min: ratingMin, max: ratingMax))
                        Text("Number").tag(HabitType.numeric(min: numericMin, max: numericMax, unit: numericUnit))
                    }
                    
                    if case .rating = selectedType {
                        Stepper("Minimum: \(ratingMin)", value: $ratingMin, in: 1...10)
                        Stepper("Maximum: \(ratingMax)", value: $ratingMax, in: 1...10)
                    }
                    
                    if case .numeric = selectedType {
                        Stepper("Minimum: \(numericMin, specifier: "%.2f")", value: $numericMin, in: 0...100)
                        Stepper("Maximum: \(numericMax, specifier: "%.2f")", value: $numericMax, in: 0...100)
                        TextField("Unit", text: $numericUnit)
#if os(iOS)
                            .textInputAutocapitalization(.never)
#endif
                        
                    }
                }
                
                Section("Appearance") {
                    VStack(alignment: .leading) {
                        
                        ColorPicker("Pick a Color", selection: Binding(
                            get: { selectedColor.color },
                            set: { newColor in
                                let resolved = newColor.resolve(in: EnvironmentValues())
                                selectedColor = RGBValues(
                                    r: Double(resolved.red),
                                    g: Double(resolved.green),
                                    b: Double(resolved.blue),
                                    a: Double(resolved.opacity)
                                )
                            }
                        ))
                        .frame(width: 300, height: 100)
                        
                        TextField("Enter SF Symbol name", text: $icon)
                            .autocorrectionDisabled(true)
                        #if os(iOS)
                            .textInputAutocapitalization(.never)
                        #endif
                        Image(systemName: icon.isEmpty ? "questionmark.circle" : icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(Color(selectedColor.color))
                    }
                }
                
                Section("Reminder") {
                    Toggle("Set Daily Reminder", isOn: .init (
                        get: { reminder != nil },
                        set: { if !$0 { reminder = nil } else {
                            reminder = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: today)
                        }
                        }))
                    
                    if reminder != nil {
                        DatePicker("Time", selection: Binding(
                            get: { reminder ?? today },
                            set: { reminder = $0 }
                        ), displayedComponents: .hourAndMinute)
                    }
                }
                if existingHabit != nil {
                    let habit = existingHabit
                    HStack {
                        Button("Archive Habit", role: .destructive) {
                            habit!.isArchived = true
                        }
                        .buttonStyle(.glass)
                        
                        Spacer()
                        
                        Button("Delete Habit", role: .destructive) {
                            modelContext.delete(habit!)
                        }
                        .buttonStyle(.glassProminent)
                        .alert("Delete Habit?", isPresented: $showDeleteAlert) {
                            Button("Delete", role: .destructive) {
                                modelContext.delete(habit!)
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This action cannot be undone.")
                        }
                    }
                }
            }
            .padding()
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveHabit(); dismiss() }
                        .disabled(title.isEmpty)
                }
            }
        }
        .onAppear { loadHabit() }
        .presentationDetents([.medium, .large])
    }
    
    private func loadHabit() {
        guard let habit = existingHabit else { return }
        
        title = habit.title
        selectedColor = habit.color
        icon = habit.icon ?? ""
        reminder = habit.reminder
        navTitle = "Edit Habit"
        
        switch habit.type {
        case .boolean: selectedType = .boolean
        case .duration: selectedType = .duration
        case .rating(let min, let max): ratingMin = min; ratingMax = max; selectedType = .rating(min: min, max: max)
        case .numeric(let min, let max, let unit): numericMin = min; numericMax = max; selectedType = .numeric(min: min, max: max, unit: unit)
        }
        
    }
    
    @MainActor
    private func saveHabit() {
        let type: HabitType
        switch selectedType {
        case .boolean: type = .boolean
        case .duration: type = .duration
        case .rating: type = .rating(min: ratingMin, max: ratingMax)
        case .numeric: type = .numeric(min: numericMin, max: numericMax, unit: numericUnit)
        }
        
        if let habit = existingHabit {
            habit.title = title
            habit.type = type
            habit.color = selectedColor
            habit.icon = icon.isEmpty ? nil : icon
            habit.reminder = reminder
        } else {
            let habit = Habit(
                title: title,
                type: type,
                color: selectedColor,
                icon: icon.isEmpty ? nil : icon,
                reminder: reminder
            )
            modelContext.insert(habit)
            if reminder != nil { Task { await scheduleNotification(for: habit) }}
        }
    }
}

#Preview("Edit Habit") {
    let container = PreviewHelpers.previewContainer
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    try? container.mainContext.save()
    
    return HabitEditorView(habit: habits.first)
        .modelContainer(container)
        .environmentObject(AppState())
}
