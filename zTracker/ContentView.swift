//
//  ContentView 2.swift
//  zTracker
//
//  Created by Jia Sahar on 12/17/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
//        #if os(iOS)
        iOSContentView()
//        #elseif os(macOS)
//        macOSContentView()
//        #endif
    }
}

private struct iOSContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            Tab("Today", systemImage: "checklist", value: .today) { TodayView() }
            Tab("Habits", systemImage: "square.grid.2x2", value: .habits) { HabitsView() }
            Tab("Insights", systemImage: "chart.xyaxis.line", value: .insights) { InsightsView() }
            Tab("Settings", systemImage: "gear", value: .settings) { SettingsView() }
        }
        
    }
}

//private struct macOSContentView: View {
//    @EnvironmentObject private var appState: AppState
//    
//    var body: some View {
//        NavigationSplitView {
//            List(selection: $appState.selectedTab) {
//                Label("Today", systemImage: "checklist")
//                    .tag(AppState.Tab.today)
//                
//                Label("Habits", systemImage: "square.grid.2x2")
//                    .tag(AppState.Tab.habits)
//                
//                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
//                    .tag(AppState.Tab.insights)
//                
//                Label("Settings", systemImage: "gear")
//                    .tag(AppState.Tab.settings)
//            }
//            .navigationTitle("zTracker")
//        } detail: {
//            switch appState.selectedTab {
//            case .today: TodayView()
//            case .habits: HabitsView()
//            case .insights: InsightsView()
//            case .settings: SettingsView()
//            }
//        }
//    }
//}
