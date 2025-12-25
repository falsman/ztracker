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
                }
                
                Text(habit.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // MARK: streak indicator
                if habit.currentStreak() > 0 {
                    HStack {
                        Image(systemName: "flame")
                            .foregroundStyle(.orange)
                        Text("\(habit.currentStreak())")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                
                Divider()
                
                // MARK: entry display
                if let entry = entry {
                    EntryView{habit: habit, entry: entry}
                } else {
                    Text("Tap to log")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
            }
            
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .glassEffect(.regular.tint(habit.color), in: .rect(cornerRadius: 16))
        }
        
        .buttonStyle(.glass)
        .onAppear { loadEntry() }
        .onChange(of: habit.entries) { loadEntry() }
        
    }
    
    private func loadEntry() {
        entry = habit.entry(for: Date())
        
    }
}
