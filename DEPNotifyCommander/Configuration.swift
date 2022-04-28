//
//  Configuration.swift
//  depnotify_commander
//
//  Created by Eric Summers on 4/16/22.
//

import Foundation

class Configuration: Decodable {
    
    init() {
        steps = []
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
    var title: String?
    
    var text: String?
    
    var image: String?
    
    var video: String?
    
    var youTube: String?
    
    var website: String?
}
