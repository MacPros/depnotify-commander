//
//  depnotify_commander.swift
//  depnotify_commander
//
//  Copyright © 2022 Konica Minolta Business Solutions U.S.A., Inc.
//

import Foundation
import ArgumentParser
import Version

@main
struct DEPNotifyCommander: AsyncParsableCommand {
    
    @Flag(help: "Run without posting Jamf custom triggers.")
    var mockRun = false
    
    static var configuration = CommandConfiguration(
        version: Bundle.main.version.description
    )

    func run() async throws {
        try? await executeWorkflow(mockRun: mockRun)
    }
    
}
