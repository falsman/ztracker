import WidgetKit

@main
struct zTrackerWidgets: WidgetBundle {
    var body: some Widget {
        SingleHabitWidget()
        MultipleHabitsWidget()
        QuickActionsWidget()
        QuickLogWidget()
    }
}

struct SingleHabitWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "SingleHabitWidget",
                               intent: SelectHabitIntent.self,
                               provider: SingleHabitProvider()) { entry in
            SingleHabitView(habit: entry.habit)
        }.supportedFamilies([.systemSmall])
    }
}

struct MultipleHabitsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "MultipleHabitsWidget",
                               intent: SelectHabitsIntent.self,
                               provider: MultipleHabitsProvider()) { entry in
            MultipleHabitsView(habits: entry.habits)
        }.supportedFamilies([.systemMedium])
    }
}

struct QuickActionsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "QuickActionsWidget",
                               intent: SelectActionsIntent.self,
                               provider: ActionsProvider()) { entry in
            ActionsView(actions: entry.actions)
        }.supportedFamilies([.systemSmall])
    }
}

struct QuickLogWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "QuickLogWidget",
                               intent: SelectActionsIntent.self,
                               provider: ActionsProvider()) { entry in
            ActionsView(actions: entry.actions)
        }.supportedFamilies([.systemMedium])
    }
}
