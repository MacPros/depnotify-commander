//
//  main.swift
//  NotifyCommander
//
//  Created by Eric Summers on 4/15/22.
//

import Foundation
import ShellOut
import Files
import Version

print("depnotify-commander v\(Bundle.main.version.description)")

let defaults = UserDefaults.standard

// Note: We currently assume the DEPNotify log is in the default location.
let depnotify = DEPNotify.shared
let path = URL(fileURLWithPath: depnotify.logPath).deletingLastPathComponent().path
guard path != "" else { fatalError() } // This shouldn't happen.

// Export images
let images = defaults.dictionary(forKey: "images") as? [String: Data]
if let images = images {
    for (imagePath, imageData) in images {
        let imageURL = URL(fileURLWithPath: imagePath)
        do {
            try imageData.write(to: imageURL)
        } catch {
            print("Failed to write image: \(imagePath)")
        }
        print("Exported image to: \(imagePath)")
    }
}

guard let jsonConfiguration = defaults.string(forKey: "configuration") else {
    // TODO: Allow an alternative configuration using a JSON Schema.
    fatalError("Missing configuration.")
}

let configuration: Configuration
do {
    configuration = try JSONDecoder().decode(Configuration.self, from: Data(jsonConfiguration.utf8))
} catch {
    fatalError("Invalid configuration. \(error)")
}

print("Starting DEPNotify workflow.")

do {
    for step in configuration.steps {
        print("Starting policies with event: \(step.event)")
        depnotify.status = step.status
        try shellOut(to: "/usr/local/bin/jamf", arguments: ["policy", "-event", step.event])
    }
} catch {
    fatalError("Error communicating with jamf command line. \(error)")
}

print("DEPNotify workflow complete.")
