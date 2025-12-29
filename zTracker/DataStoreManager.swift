//
//  DataStoreManager.swift
//  zTracker
//
//  Created by Jia Sahar on 12/20/25.
//

import Foundation

final class DataStoreManager: Sendable {
    static let shared = DataStoreManager()
    private let bookmarkKey = "storeBookmark"
    
    var needsLocationPicker: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) == nil
    }
    
    func saveLocation(_ url: URL) throws {
        _ = url.startAccessingSecurityScopedResource()
        
        let bookmark = try url.bookmarkData(options: .minimalBookmark)
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
    }
    
    func getStoreURL() throws -> URL {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else { throw NSError(domain: "No location found", code: 0) }
        
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            bookmarkDataIsStale: &isStale
        )

        try assertReadWriteAccess(to: url)
        
        return url.appendingPathComponent("AppData.sqlite")
    }
    
    func assertReadWriteAccess(to url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "Security scope denied", code: 1)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let testFile = url.appendingPathComponent(".rw_test")
        let data = Data("test".utf8)

        try data.write(to: testFile)
        try FileManager.default.removeItem(at: testFile)
    }

}
