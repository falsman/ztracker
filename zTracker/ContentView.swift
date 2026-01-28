//
//  ContentView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/17/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("userThemeColor") private var userThemeColor: AppColor = .theme
    
    var body: some View {
        TabView() {
            Tab("Today", systemImage: "checklist") { TodayView() }
            Tab("Habits", systemImage: "square.grid.2x2") { HabitsView() }
            Tab("Calendar", systemImage: "calendar") { CalendarView() }
            Tab("Insights", systemImage: "chart.xyaxis.line") { InsightsView() }
            Tab("Settings", systemImage: "gear") { SettingsView() }
        }
        .background(MovingLinearGradient(selectedColor: userThemeColor.color))
    }
}

#Preview("Empty State") {
    ContentView()
        .modelContainer(PreviewHelpers.previewContainer)
}

#Preview("Content View") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return ContentView()
            .modelContainer(container)
}
