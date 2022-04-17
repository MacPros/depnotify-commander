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

if let icon = configuration.icon {
    depnotify.image = .path(icon)
}

if let content = configuration.content {
    content.update()
}

do {
    for step in configuration.steps {
        if let status = step.status {
            print("Status: \(status)")
            depnotify.status = step.status ?? ""
        }
        
        if let content = step.content {
            content.update()
        }
        
        if let event = step.event {
            print("Starting policies with event: \(event)")
            try shellOut(to: "/usr/local/bin/jamf", arguments: ["policy", "-event", event])
        }
    }
    
    if let completionContent = configuration.completionContent {
        completionContent.update()
    }
    
    if let completionButton = configuration.completionButton {
        depnotify.showQuitButton(buttonLabel: completionButton)
    }
    
    if let completionEvent = configuration.completionEvent {
        try shellOut(to: "/usr/local/bin/jamf", arguments: ["policy", "-event", completionEvent])
    }
    
} catch {
    fatalError("Error communicating with jamf command line. \(error)")
}

print("DEPNotify workflow complete.")

// MARK: - Helpers

extension DEPNotifyContent {
    public func update() {
        if let title = title {
            depnotify.title = title
        }
        if let text = text {
            depnotify.content = .text(text)
        }
        
        if let image = image, image != "" {
            depnotify.content = .image(.path(image))
        }
        
        if let video = video, video != "" {
            var vid: DEPNotify.Video? = nil
            if video.hasPrefix("http") {
                if let url = URL(string: video) {
                    vid = .url(url)
                } else {
                    vid = .path(video)
                }
            }
            if let vid = vid {
                depnotify.content = .video(vid)
            }
        }
        
        if let youTube = youTube, youTube != "" {
            depnotify.content = .video(.youTube(id: youTube))
        }
        
        if let website = website, website != "" {
            if let url = URL(string: website) {
                depnotify.content = .website(url)
            }
        }
    }
}
