//
//  ActionsView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
import WidgetKit
import AppIntents


struct ActionsView: View {
    var actions: [SelectActionsIntent.ActionType]

    var body: some View {
        VStack {
            ForEach(actions, id: \.self) { action in
                Button(intent: intent(for: action)) { Text(action.rawValue) }
            }
        }
        .padding()
        .glassEffect()
    }

    func intent(for action: SelectActionsIntent.ActionType) -> any AppIntent {
        switch action {
        case .boolean: SetBooleanIntent()
        case .duration: SetDurationIntent()
        case .rating: SetValueIntent()
        case .numeric: SetValueIntent()
        case .note: SetNoteIntent()
        }
    }
}
//
