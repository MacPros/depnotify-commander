//
//  Configuration.swift
//  depnotify_commander
//
//  Created by Eric Summers on 4/16/22.
//

import Foundation

class Configuration: Decodable {
    
    var steps: [DEPNotifyStep]
    
}

class DEPNotifyStep: Decodable {
    
    /// Change the status.
    var status: String
    
    /// The custom trigger to invoke.
    var event: String
    
}
