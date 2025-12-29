//
//  HabitCardView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct HabitCardView: View {
    let habit: Habit
    let onTap: () -> Void
    @State private var entry: HabitEntry?
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if let icon = habit.icon {
                    Image(systemName: icon)
                        .font(.headline)
                        .tint(.primary)
                }
                
                Text(habit.title)
                    .font(.headline)
                    .tint(.primary)
                
                Spacer()
                
                // MARK: streak indicator
                if habit.currentStreak() > 0 {
                    HStack {
                        Image(systemName: "flame")
                            .foregroundStyle(.orange)
                        
                        Text("\(habit.currentStreak())")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .tint(.primary)
                    }
                }
                
                Divider()
                
                // MARK: entry display
                if let entry = entry {
                    EntryView(habit: habit, entry: entry)
                        .tint(.primary)
                } else {
                    Text("Tap to log")
                        .tint(.primary)
                }
                
                
            }
            
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(habit.color.color, lineWidth: 0.75)
            )
            .glassEffect(.regular.tint(habit.color.color.opacity(0.2)), in: .rect(cornerRadius: 16))

        }
        
        .onAppear { loadEntry() }
        .onChange(of: habit.entries) { loadEntry() }
        
    }
    
    private func loadEntry() {  entry = habit.entry(for: today) }
}

#Preview {
    let container = PreviewHelpers.previewContainer
    let habits = PreviewHelpers.makeHabits()
    
    habits.forEach { container.mainContext.insert($0) }
    try? container.mainContext.save()
    
    return HabitCardView(habit: habits[2], onTap: {})
        .modelContainer(container)
}

