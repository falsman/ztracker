//
//  TodayView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Habit> { !$0.isArchived })
    private var activeHabits: [Habit]
    
    @State private var showingEntryEditor: Habit?
    @State private var selectedHabit: Habit?
    @State private var path = NavigationPath()
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400))
    ]
    
    var body: some View {
        NavigationSplitView {
            listContent
        } detail: {
            detailContent
        }
        .sheet(item: $showingEntryEditor) { habit in EntryEditorView(habit: habit, date: today) }
        //        .sheet(isPresented: $appState.showingNewHabit) { HabitEditorView() }
        .onAppear {
            if selectedHabit == nil {
                selectedHabit = activeHabits.first
            }
        }
    }
    
    private var listContent: some View {
        ScrollView {
            
            // MARK: date header
            VStack {
                Text(today, style: .date)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(today, style: .time)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)
            
            StatsOverviewView()
                .padding(Edge.Set.horizontal)
            
            // MARK: today's habits
            LazyVGrid(columns: columns) {
                ForEach(activeHabits) { habit in HabitCardView(habit: habit) { showingEntryEditor = habit }
                        .contextMenu {
                            Button("Edit Entry") {
                                showingEntryEditor = habit
                            }
                            
                            Button("View Details") {
                                appState.selectedHabit = habit
                                appState.selectedTab = .habits
                                path.append(habit)
                            }
                            
                            Divider()
                            
                            Button("Archive", role: .destructive) {
                                habit.isArchived.toggle()
                            }
                        }
                }
            }
            .padding()
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(habit: habit)
            }
            
            if activeHabits.isEmpty { EmptyStateView() }
        }
        .navigationTitle("Today")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button() { Task {
                    try? await syncHealthKitData(for: today, in: modelContext)
                }
                } label: { Label("Sync Health Data", systemImage: "arrow.down.heart.fill") }
                    .buttonStyle(.glassProminent)
            }
        }
        #endif
    }
    
    private var detailContent: some View {
        Group {
            if let habit = appState.selectedHabit {
                EntryEditorView(habit: habit, date: today)
            } else {
                listContent
            }
        }
    }
}

#Preview("Empty State") {
    TodayView()
        .modelContainer(PreviewHelpers.previewContainer)
        .environmentObject(AppState())
}

#Preview("With Sample Data") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return TodayView()
            .modelContainer(container)
            .environmentObject(AppState())
}
