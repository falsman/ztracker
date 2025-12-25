//
//  HabitsViews.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
import WidgetKit

struct SingleHabitView: View {
    var habit: HabitEntity?

    var body: some View {
        VStack {
            Text(habit?.title ?? "No Habit")
            if let habit = habit { HabitButtonsView(habit: habit) }
        }
        .padding()
        .glassEffect()
    }
}

struct MultipleHabitsView: View {
    var habits: [HabitEntity]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(habits) { habit in
                HStack {
                    Text(habit.title)
                    Spacer()
                    HabitButtonsView(habit: habit)
                }
            }
        }
        .padding()
        .glassEffect()
    }
}
