//
//  Configuration.swift
//  depnotify_commander
//
//  Created by Eric Summers on 4/16/22.
//

import Foundation

class Configuration: Decodable {
    
    var steps: [DEPNotifyStep]
    
    // The initial content.
    var content: DEPNotifyContent?
    
    // The initial status.
    var status: String?
    
    // Replace the default DEPNotify icon.
    var icon: String?
    
    // The content to show on completion.
    var completionContent: DEPNotifyContent?
    
    // Show a completion button after the last step.
    var completionButton: String?
    
    // Run a policy before exiting. This will run before the button is pressed.
    var completionEvent: String?
}

class DEPNotifyStep: Decodable {
    
    /// The custom trigger to invoke.
    var event: String?
    
    var status: String?
    
    var content: DEPNotifyContent?
    
}

class DEPNotifyContent: Decodable {
    var title: String?
    
    var text: String?
    
    var image: String?
    
    var video: String?
    
    var youTube: String?
    
    var website: String?
}
