//
//  Configuration.swift
//  depnotify_commander
//
//  Created by Eric Summers on 4/16/22.
//

import Foundation

class Configuration: Decodable {
    
    init(defaults: UserDefaults) {
        steps = []
        if let stepPlists = defaults.array(forKey: "steps") {
            for step in stepPlists {
                if let stepPlist = step as? [String: Any] {
                    steps.append(DEPNotifyStep(plist: stepPlist))
                }
            }
        }
    
        if let contentPlist = defaults.dictionary(forKey: "content") {
            content = DEPNotifyContent(plist: contentPlist)
        }
        
        if let contentPlist = defaults.dictionary(forKey: "completionContent") {
            completionContent = DEPNotifyContent(plist: contentPlist)
        }
        
        status = defaults.string(forKey: "status")
        icon = defaults.string(forKey: "icon")
        disableNotifyOnSuccess = defaults.bool(forKey: "disableNotifyOnSuccess")
        completionButton = defaults.string(forKey: "completionButton")
        completionText = defaults.string(forKey: "completionText")
        completionEvent = defaults.string(forKey: "completionEvent")
        eulaButton = defaults.string(forKey: "eulaButton")
    }
    
    var steps: [DEPNotifyStep]
    
    /// The initial content.
    var content: DEPNotifyContent?
    
    /// The initial status.
    var status: String?
    
    /// Replace the default DEPNotify icon.
    var icon: String?
    
    /// The content to show on completion.
    var completionContent: DEPNotifyContent?
    
    /// Disable notify script with authchanger on success.
    var disableNotifyOnSuccess: Bool?
    
    /// Arguments to pass to disable notify script. By default `["-reset", "-JamfConnect"]`.
    var authchangerArguments: [String]?
    
    /// Show the EULA continue button with the custom label.
    var eulaButton: String?
    
    /// Show a completion button after the last step.
    ///
    /// - Note: The command for this button seems to be ignored in the version of DEPNotify embedded in Jamf Connect (as of v2.11.0). Use `completionText` instead.
    var completionButton: String?
    
    /// This will quit DEPNotify with text displayed in an alert window.
    var completionText: String?
    
    /// Run a policy before exiting. This will run before the button is pressed.
    var completionEvent: String?
}

class DEPNotifyStep: Decodable {
    
    init(plist: [String: Any]) {
        event = plist["event"] as? String
        status = plist["status"] as? String
        if let contentPlist = plist["content"] as? [String: Any] {
            content = DEPNotifyContent(plist: contentPlist)
        }
        skipInventory = plist["skipInventory"] as? Bool
        runScript = plist["runScript"] as? String
        abortOnError = plist["abortOnError"] as? Bool
    }
    
    /// The custom trigger to invoke.
    var event: String?
    
    var status: String?
    
    var content: DEPNotifyContent?
    
    /// Skip inventory for this step.
    var skipInventory: Bool?
    
    var runScript: String?
    
    var abortOnError: Bool?
}

class DEPNotifyContent: Decodable {
    
    init(plist: [String: Any]) {
        title = plist["title"] as? String
        text = plist["text"] as? String
        image = plist["image"] as? String
        video = plist["video"] as? String
        youTube = plist["youTube"] as? String
        website = plist["website"] as? String
    }
    
    var title: String?
    
    var text: String?
    
    var image: String?
    
    var video: String?
    
    var youTube: String?
    
    var website: String?
}
