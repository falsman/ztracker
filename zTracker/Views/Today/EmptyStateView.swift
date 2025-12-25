//
//  EmptyStateView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Image(systemName: "square.grid.2x2")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            VStack {
                Text("No Habits Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Add your first habit to start tracking")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
