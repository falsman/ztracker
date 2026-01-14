//
//  HabitEditorView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData
import SFSymbols

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    let existingHabit: Habit?
    
    @State private var title = ""
    @State private var selectedType: HabitType = .boolean(goal: nil)
    @State private var selectedColor: AppColor = .theme
    @State private var icon = ""
    
    @State private var goalState: Bool = false
    @State private var goalTarget: Double?
    @State private var goalFrequency: HabitGoal.Frequency?
    var goalInfoMissing: Bool { goalState && (goalTarget == nil || goalFrequency == nil) }
    
    @State private var reminder: Date?
    
    @State private var ratingMin: Int?
    @State private var ratingMax: Int?
    
    @State private var numericMin: Double?
    @State private var numericMax: Double?
    @State private var numericUnit: String = ""
    
    @State private var showDeleteAlert = false
    
    @State private var showSymbolPicker = false
    
    var minMaxError: Bool {
        let numericError: Bool = {
            guard let min = numericMin, let max = numericMax else { return false }
            return min > max
        }()

        let ratingError: Bool = {
            guard let min = ratingMin, let max = ratingMax else { return false }
            return min > max
        }()

        return numericError || ratingError
    }

    @Query(sort: \Habit.sortIndex) private var allHabits: [Habit]
    private var nextSortIndex: Int { (allHabits.map(\.sortIndex).max() ?? -1) + 1 }
    
    init(habit: Habit? = nil) { self.existingHabit = habit }
    
    var body: some View {
        NavigationStack {
            
            ScrollView {
                
                BasicInfoSection(title: $title, selectedType: $selectedType, ratingMin: $ratingMin, ratingMax: $ratingMax, numericMin: $numericMin, numericMax: $numericMax, numericUnit: $numericUnit, minMaxError: minMaxError, existingHabit: existingHabit)
                    .glassEffect(in: .rect(cornerRadius: 16))
                    .padding([.top, .horizontal])
                
                AppearanceSection(selectedColor: $selectedColor, icon: $icon, showSymbolPicker: $showSymbolPicker)
                    .glassEffect(in: .rect(cornerRadius: 16))
                    .padding(.horizontal)
                
                GoalsSection(goalState: $goalState, goalTarget: $goalTarget, goalFrequency: $goalFrequency, goalInfoMissing: goalInfoMissing)
                    .glassEffect(in: .rect(cornerRadius: 16))
                    .padding(.horizontal)

                ReminderSection(reminder: $reminder)
                    .glassEffect(in: .rect(cornerRadius: 16))
                    .padding(.horizontal)
                
                Text("Created on: \((existingHabit?.createdAt ?? Date()).formatted(date: .long, time: .omitted))")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.horizontal)
                    .font(.caption)

            }
            #if os(iOS)
            .navigationTitle(existingHabit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                    
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) { saveHabit(); dismiss() }
                        .disabled(title.isEmpty)
                        .disabled(minMaxError)
                        .disabled(goalInfoMissing)
                }
            }
        }
        .background(selectedColor.color.gradient)
        .presentationDetents([.medium, .large])
        .tint(Color(selectedColor.color))
        .onAppear { loadHabit() }
    }
    
    private func loadHabit() {
        guard let habit = existingHabit else { return }
        
        title = habit.title
        selectedColor = AppColor(rawValue: habit.color)!
        icon = habit.icon ?? ""
        reminder = habit.reminder
        
        switch habit.type {
        case .boolean(let goal): selectedType = .boolean(goal: goal)
        case .duration(let goal): selectedType = .duration(goal: goal)
        case .rating(let min, let max, let goal): ratingMin = min; ratingMax = max; selectedType = .rating(min: min, max: max, goal: goal)
        case .numeric(let min, let max, let unit, let goal): numericMin = min; numericMax = max; numericUnit = unit; selectedType = .numeric(min: min, max: max, unit: unit, goal: goal)
        }
        
        if habit.type.goal != nil {
            goalState = true
            goalTarget = habit.type.goal?.target ?? 0
            goalFrequency = habit.type.goal?.frequency ?? .daily
        }
    }
        
    @MainActor
    private func saveHabit() {
        let type: HabitType
        switch selectedType {
        case .boolean: type = .boolean(goal: nil)
        case .duration: type = .duration(goal: nil)
        case .rating: type = .rating(min: ratingMin ?? 0, max: ratingMax ?? 0, goal: nil)
        case .numeric: type = .numeric(min: numericMin ?? 0, max: numericMax ?? 0, unit: numericUnit.trimmingCharacters(in: .whitespacesAndNewlines), goal: nil)
        }
        
        if let habit = existingHabit {
            habit.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            habit.type = type
            habit.color = selectedColor.rawValue
            habit.icon = icon.isEmpty ? nil : icon
            habit.reminder = reminder
        } else {
            let habit = Habit(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                color: selectedColor.rawValue,
                icon: icon.isEmpty ? nil : icon,
                createdAt: Date(),
                reminder: reminder,
                sortIndex: nextSortIndex
            )
            context.insert(habit)
            if reminder != nil { Task { await scheduleNotification(for: habit) }}
        }
    }
}

struct BasicInfoSection: View {
    @Binding var title: String
    @Binding var selectedType: HabitType
    
    @Binding var ratingMin: Int?
    @Binding var ratingMax: Int?
    
    @Binding var numericMin: Double?
    @Binding var numericMax: Double?
    @Binding var numericUnit: String
    
    var minMaxError: Bool
    let existingHabit: Habit?
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Habit Name", text: $title)
                .font(.title)
            
            Picker("Habit Type", selection: $selectedType) {
                Text("Checkmark").tag(HabitType.boolean(goal: nil))
                Text("Duration").tag(HabitType.duration(goal: nil))
                Text("Rating").tag(HabitType.rating(min: ratingMin ?? 0, max: ratingMax ?? 5, goal: nil))
                Text("Number").tag(HabitType.numeric(min: numericMin ?? 0, max: numericMax ?? 100, unit: numericUnit, goal: nil))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(existingHabit != nil)
            
            
            if case .rating = selectedType {
                VStack {
                    Stepper("Minimum: \(ratingMin ?? 0)", value: Binding(
                        get: { ratingMin ?? 0 },
                        set: { ratingMin = $0 }
                    ), in: 0...10)
                    
                    Stepper("Maximum: \(ratingMax ?? 5)", value: Binding(
                        get: { ratingMax ?? 5 },
                        set: { ratingMax = $0 }
                    ), in: 0...10)
                    
                    if minMaxError { Text("Min/Max Value Error").foregroundStyle(.red).font(.caption).frame(maxWidth: .infinity, alignment: .leading) }

                }
                .foregroundStyle(minMaxError ? .red : .primary)

            }
            
            if case .numeric = selectedType {
                HStack {
                    TextField("Minimum", value: $numericMin, format: .number)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Maximum", value: $numericMax, format: .number)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                .foregroundStyle(minMaxError ? .red : .primary)
                
                if minMaxError { Text("Min/Max Value Error").foregroundStyle(.red).font(.caption).frame(maxWidth: .infinity, alignment: .leading) }

                TextField("Unit", text: $numericUnit)
                    .autocorrectionDisabled(true)
                
            }
        }
        .padding()
    }
}

struct AppearanceSection: View {
    @Binding var selectedColor: AppColor
    @Binding var icon: String
    @Binding var showSymbolPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Appearance")
                .font(.headline)
                
            HStack {
                VStack(alignment: .leading) {
                    TextField("SF Symbol Name", text: $icon)
                        .autocorrectionDisabled(true)
                    
                    Picker("Select Color", selection: $selectedColor) {
                        ForEach(AppColor.allCases, id: \.self) { id in
                            HStack {
                                id.color
                                    .frame(width: 20, height: 12.5)
                                    .cornerRadius(16)
                                    .environment(\.colorScheme, .light)
                                    .padding(.leading)
                                
                                id.color
                                    .frame(width: 20, height: 12.5)
                                    .cornerRadius(16)
                                    .environment(\.colorScheme, .dark)
                                
                                Text(id.rawValue)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                
                                Spacer()
                                
                            }
                            .tag(id.rawValue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    #if os(macOS)
                    .pickerStyle(.radioGroup)
                    #elseif os(iOS)
                    .pickerStyle(.inline)
                    #endif
                }
                
                Spacer()
                
                Button(action: {
                    showSymbolPicker = true
                }) {
                    Image(systemName: icon.isEmpty ? "questionmark.circle" : icon) //
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        #if os(macOS)
                        .containerRelativeFrame(.horizontal, count: 10, span: 2, spacing: 0)
                        #endif
                        .tint(Color(selectedColor.color))
                    
                }
                .sfSymbolPicker(isPresented: $showSymbolPicker, selection: $icon)
                .padding()
            }
        }
        .padding()

    }
}

struct GoalsSection: View {
    @Binding var goalState: Bool
    @Binding var goalTarget: Double?
    @Binding var goalFrequency: HabitGoal.Frequency?
    
    var goalInfoMissing: Bool
    
    var body: some View {
        VStack {
            Toggle("Set Goal", isOn: $goalState)
            
            if goalState {
                HStack {
                    TextField("Goal Value", value: $goalTarget, format: .number)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    
                    Picker("Goal Frequency", selection: $goalFrequency) {
                        ForEach(HabitGoal.Frequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue.capitalized)
                                .tag(frequency)
                        }
                    }
                }
            }
    
            if goalInfoMissing {
                Text("Enter goal value and frequency.").foregroundStyle(.red).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
struct ReminderSection: View {
    @Binding var reminder: Date?
    
    var body: some View {
        VStack {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}


#Preview("Sheet View") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let habitToShow = habits[2]
    
    return Text("Parent Backgroudn View")
        .sheet(isPresented: .constant(true)) {
            HabitEditorView(habit: habitToShow)
        }
        .modelContainer(container)
        
}

#Preview("Full Screen View") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let habitToShow = habits[2]
    
    return HabitEditorView(habit: habitToShow)
        .modelContainer(container)
        
}
