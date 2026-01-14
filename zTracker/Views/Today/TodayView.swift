//
//  TodayView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    
    @AppStorage("healthKitEnabled") var healthKitEnabled = true
        
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \.sortIndex,
           order: .forward
    )
    private var activeHabits: [Habit]
    
    @State private var selectedHabit: Habit?
    
    private var currentTime = Text(Date(), style: .time)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                #if os(macOS)
                VStack {
                    Text(Date(), style: .date)
                        .font(.title)
                    currentTime
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                #endif
                
                StatsOverviewView()
                    .padding(.horizontal)
                
                HabitCardView(activeHabits: activeHabits, selectedHabit: $selectedHabit)
                
            }
            
            #if os(iOS)
            .background(movingLinearGradient(selectedColor: .theme))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text(Date(), style: .date))
            .navigationSubtitle(currentTime)
            
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button() { Task {
                        try? await syncHealthKitData(for: today, in: context)
                    }
                    } label: { Label("Sync Health Data", systemImage: "arrow.down.heart.fill") }
                        .tint(.red.opacity(0.75))
                        .buttonStyle(.glassProminent)
                        .disabled(healthKitEnabled == false)
                }
            }
            #endif
        }
        .sheet(item: $selectedHabit) {
            habit in EntryEditorView(habit: habit, date: today)
                .background(Color(.clear))
        }
    }
}

struct HabitCardView: View {
    var activeHabits: [Habit]
    @Binding var selectedHabit: Habit?
    
    #if os(macOS)
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 300))
    ]
    #elseif os(iOS)
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 600))
    ]
    #endif
    
    var body: some View {
        return LazyVGrid(columns: columns) {
            ForEach(activeHabits) {
                habit in HabitCard(habit: habit, date: today) {
                    selectedHabit = habit
                }
            }
        }
        .padding()
        .navigationDestination(for: Habit.self) { habit in
            HabitDetailView(habit: habit)
        }
    }
}

struct HabitCard: View {
    let habit: Habit
    let date: Date
    let onTap: () -> Void
    
    @State private var entry: HabitEntry?
    
    var body: some View {
        HStack {
            if let icon = habit.icon { Image(systemName: icon) }
            
            Text(habit.title)
            
            Spacer()
            
            if habit.currentStreak() > 0 {
                HStack {
                    Image(systemName: "flame").font(.caption)
                    Text("\(habit.currentStreak())").font(.caption)
                }
                .foregroundStyle(habit.swiftUIColor.secondary)
            }
            
            Divider()
            
            if let entry = entry {
                EntryView(habit: habit, entry: entry)
                    #if os(macOS)
                    .frame(width: 90)
                    #elseif os(iOS)
                    .containerRelativeFrame(.horizontal, count: 10, span: 3, spacing: 0)
                    #endif
            } else {
                Text("Tap to log")
                    #if os(macOS)
                    .frame(width: 90, alignment: .trailing)
                    #elseif os(iOS)
                    .containerRelativeFrame(.horizontal, count: 10, span: 3, spacing: 0, alignment: .trailing)
                    #endif
            }
        }
        .foregroundStyle(habit.swiftUIColor)
        
        .padding()
        #if os(macOS)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        #endif
        .glassEffect(in: .rect(cornerRadius: 16))
        
        .contentShape(.rect)
        .onTapGesture { onTap() }

        .onAppear { loadEntry() }
        .onChange(of: habit.entries) { loadEntry() }
        
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
    
    private func loadEntry() {  entry = habit.entry(for: date) }
}



#Preview("Today View") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return TodayView()
            .modelContainer(container)
}

#Preview("Habit Card View") {
    let container = PreviewHelpers.previewContainer
    let habits = PreviewHelpers.makeHabits()
    
    habits.forEach { container.mainContext.insert($0) }
    try? container.mainContext.save()
    
    return HabitCard(habit: habits[2], date: today, onTap: {})
        .modelContainer(container)
}

#Preview("Habit Cards VStack") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let firstFourHabits = Array(habits.prefix(4))
    
    return VStack {
        ForEach(firstFourHabits, id: \.id) { habit in
            HabitCard(habit: habit, date: today, onTap: {})
            Divider()
        }
    }
    .modelContainer(container)
    
}
