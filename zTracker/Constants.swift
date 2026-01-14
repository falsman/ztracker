//
//  Constants.swift
//  zTracker
//
//  Created by Jia Sahar on 12/27/25.
//

import Foundation

nonisolated(unsafe) var today: Date = Calendar.current.startOfDay(for: Date())
nonisolated(unsafe) var yesterday: Date = Calendar.current.date(byAdding: .day, value: -1, to: today)!

