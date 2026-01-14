//
//  ImportExportViews2.swift
//  zTracker
//
//  Created by Jia Sahar on 1/10/26.
//

import SwiftUI
import SwiftData

struct HabitDTO: Codable {
    let id: UUID
    let title: String
    let type: HabitType
    let color: String
    let icon: String?
    let isArchived: Bool
    let createdAt: Date
    let reminder: Date?
    let metadata: Data?
}

struct HabitEntryDTO: Codable {
    let id: UUID
    let habitID: UUID
    let date: Date
    let completed: Bool?
    let durationSeconds: Int64?
    let ratValue: Int?
    let numValue: Double?
    let note: String?
    let updatedAt: Date
}

