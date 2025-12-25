//
//  StatCard.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(color), in: .rect(cornerRadius: 16))
    }
}
