//
//  CalendarView.swift
//  zTracker
//
//  Created by Jia Sahar on 1/7/26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \.sortIndex,
           order: .forward
    )
    private var activeHabits: [Habit]
    
    @State private var selectedDate: Date = today
    @State private var selectedHabit: Habit?
    
    private let columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: {
                            Calendar.current.startOfDay(for: selectedDate)
                        },
                        set: {
                            selectedDate = Calendar.current.startOfDay(for: $0)
                        }
                    ),
                    displayedComponents: .date
                )
                .frame(maxWidth: .infinity)
                .datePickerStyle(.graphical)
                .padding()
                .glassEffect(in: .rect(cornerRadius: 16))
                .padding(.horizontal)
                
                
                LazyVGrid(columns: columns) {
                    ForEach(activeHabits) { habit in
                        CompactHabitCard(habit: habit, date: selectedDate)
                            .onTapGesture { selectedHabit = habit }
                            .contextMenu {
                                Button("Edit Entry", systemImage: "pencil") { selectedHabit = habit }
                                    .buttonStyle(.glass)
                                    .tint(.blue)
                                Divider()
                                NavigationLink {
                                    HabitDetailView(habit: habit)
                                } label: {
                                    Label("View Habit Details", systemImage: "info.circle")
                                }
                                .buttonStyle(.glass)
                        }
                    }
                }
                .padding()
            }
            
            #if os(iOS)
            .background(MovingLinearGradient(selectedColor: .theme))
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Calendar")

        }
        .sheet(item: $selectedHabit) { habit in
            EntryEditorView(habit: habit, date: selectedDate)
                .background(.clear)
        }
    }
}

struct CompactHabitCard: View {
    let habit: Habit
    let date: Date
    
    @State private var entry: HabitEntry?
    
    var body: some View {
        VStack {
            HStack {
                if let icon = habit.icon {
                    Image(systemName: icon)
                        .foregroundStyle(habit.swiftUIColor.secondary)
                }
                Text(habit.title)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
            }
            
            if let entry = entry {
                Text(entry.displayValue)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Tap to Log")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(in: .rect(cornerRadius: 16))
        .onAppear { loadEntry() }
        .onChange(of: date) { loadEntry() }
        .onChange(of: entry) { loadEntry() }
        .contextMenu {
            QuickEntryEditorView(habit: habit, date: date)
            #if os(macOS)
            Divider()
            NavigationLink {
                HabitDetailView(habit: habit)
            } label: {
                Label("View Habit Details", systemImage: "info.circle")
            }
            .buttonStyle(.glass)
            #endif
        }
    }
    
    private func loadEntry() { entry = habit.entry(for: date) }
}

#Preview("Calendar View") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return CalendarView()
        .modelContainer(container)
}

#Preview("Content View") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return ContentView()
            .modelContainer(container)
}
