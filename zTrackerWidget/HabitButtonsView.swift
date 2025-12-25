import SwiftUI

struct HabitButtonsView: View {
    var habit: HabitEntity

    var body: some View {
        HStack(spacing: 4) {
            switch habit.type {
            case .rating, .numeric:
                Button(intent: SetValueIntent(habit: habit, value: 1)) { Text("Set") }
                if case .numeric = habit.type {
                    Button(intent: AdjustValueIntent(habit: habit, delta: -1)) { Text("-") }
                    Button(intent: AdjustValueIntent(habit: habit, delta: 1)) { Text("+") }
                }
            case .toggle:
                Button(intent: SetBooleanIntent(habit: habit, value: true)) { Text("Toggle") }
            case .duration:
                Button(intent: SetDurationIntent(habit: habit, duration: 1)) { Text("Log") }
            }
        }
    }
}
