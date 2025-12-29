//
//  ArchiveView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftUI
import SwiftData


public struct ArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Habit> { $0.isArchived })
    private var archivedHabits: [Habit]
    
    @State var selection: Set<Habit.ID>
    @State private var showingDeleteAlert = false
    
    public var body: some View {
        NavigationStack {
            List(archivedHabits, selection: $selection) { habit in HabitRow(habit: habit)}
                .navigationTitle("Archived Habits")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                    
                    ToolbarItemGroup(placement: .destructiveAction) {
                        Button("Restore Selected") { restoreSelected() }
                            .disabled(selection.isEmpty)
                            .buttonStyle(.glass)
                        
                        Spacer()
                        
                        Button("Delete Selected", role: .destructive) { deleteSelected() }
                            .disabled(selection.isEmpty)
                            .buttonStyle(.glass)
                    }
                }
        }
    }
    
    private func restoreSelected() {
            for id in selection {
                if let habit = archivedHabits.first(where: { $0.id == id}) {
                    habit.isArchived.toggle()
                }
            }
            selection.removeAll()
    }
    
    private func deleteSelected() {
            for id in selection {
                if let habit = archivedHabits.first(where: { $0.id == id }) {
                    modelContext.delete(habit)
                }
            }
            selection.removeAll()
    }
}
