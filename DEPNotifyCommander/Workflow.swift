//
//  main.swift
//  NotifyCommander
//
//  Created by Eric Summers on 4/15/22.
//

import Foundation
import ShellOut
import Version

// TODO: Add support for starting from a launch daemon. Add support for launch daemon self destruct. The installer should check for a custom setting (similar to authchanger) and conditionally deploy the launch daemon configuration.

// TODO: Add support to pull in the SSO user name: https://docs.jamf.com/jamf-connect/2.10.0/documentation/Notify_Screen.html

func executeWorkflow(mockRun: Bool = false) async throws {
    // Note: We currently assume the DEPNotify log is in the default location.
    let depnotify = DEPNotify.shared
    let logPath = await depnotify.logPath
    let path = URL(fileURLWithPath: logPath).deletingLastPathComponent().path
    guard path != "" else { fatalError() } // This shouldn't happen.

    print("depnotify-commander v\(Bundle.main.version.description)")
    
    if FileManager.default.fileExists(atPath: "/private/var/db/.DEPNotifySetupDone") {
        print("No setup required.")
        exit(0)
    }

    let _ = disableScreenSleep(reason: "Deploying packages")

    let defaults = UserDefaults.standard

    // Export images accepting base64 encoded strings or data values
    var images = defaults.dictionary(forKey: "images") as? [String: Data]
    if images == nil {
        if let imageStrings = defaults.dictionary(forKey: "images") as? [String: String] {
            images = imageStrings.compactMapValues { Data(base64Encoded: $0) }
        }
    }
    if let images = images {
        for (imagePath, imageData) in images {
            let imageURL = URL(fileURLWithPath: imagePath)
            let imagePath = imageURL.deletingLastPathComponent().path
            do {
                try shellOut(to: "/bin/mkdir", arguments: ["-p", imagePath])
                try imageData.write(to: imageURL)
            } catch {
                print("Failed to write image: \(imagePath)")
            }
            print("Exported image to: \(imagePath)")
        }
    }

    // Export scripts
    let scripts = defaults.dictionary(forKey: "scripts") as? [String: String]
    if let scripts = scripts {
        for (scriptPath, scriptContent) in scripts {
            let scriptURL = URL(fileURLWithPath: scriptPath)
            let scriptPath = scriptURL.deletingLastPathComponent().path
            do {
                try shellOut(to: "/bin/mkdir", arguments: ["-p", scriptPath])
                try scriptContent.write(to: scriptURL, atomically: false, encoding: .utf8)
            } catch {
                print("Failed to write script: \(scriptPath)")
            }
            print("Exported script to: \(scriptPath)")
        }
    }
    
    // Load DEPNotify configuration
    let configuration: Configuration
    if let jsonConfiguration = defaults.string(forKey: "configuration") ?? defaults.string(forKey: "managedConfiguration"), jsonConfiguration != "" {
        do {
            configuration = try JSONDecoder().decode(Configuration.self, from: Data(jsonConfiguration.utf8))
        } catch {
            fatalError("Invalid configuration. \(error)")
        }
    } else {
        print("No JSON configuration found, using plist configuration instead.")
        // Note: This will return a workflow without any steps if there is no plist or JSON configuration.
        configuration = Configuration(defaults: defaults)
    }

    print("Starting DEPNotify workflow.")

    if let icon = configuration.icon {
        await depnotify.setImage(.path(icon))
    }

    if let content = configuration.content {
        await content.update()
    }

    if let status = configuration.status {
        print("Status: \(status)")
        await depnotify.setStatus(status)
    }
    
    if let eulaButton = configuration.eulaButton {
        print("Showing EULA continue button with label: \(eulaButton)")
        await depnotify.showEULAButton(buttonLabel: eulaButton)
        let fm = FileManager.default
        var seconds = 0
        while !fm.fileExists(atPath: "/var/tmp/com.depnotify.provisioning.done") {
            if (seconds % 120) == 0 {
                print("Waiting for EULA... (\(seconds / 60) minutes)")
            }
            sleep(1)
            seconds = seconds + 1
        }
        print("EULA accepted.")
    }
    
    // Defaults to waiting for JSS connection unless set to false.
    if configuration.waitForJSSConnection ?? true {
        print("Waiting for jamf binary...")
        await depnotify.setStatus("Waiting for MDM agent...")
        let fm = FileManager.default
        var seconds = 0
        while !fm.fileExists(atPath: "/usr/local/bin/jamf") {
            if (seconds % 120) == 0 {
                print("Waiting for \"jamf\" binary... (\(seconds / 60) minutes)")
            }
            sleep(1)
            seconds = seconds + 1
        }
        
        print("Waiting for JSS connection...")
        await depnotify.setStatus("Connecting to MDM server...")
        var tries = 0
        var waitingForConnection = true
        while waitingForConnection {
            print("Waiting for JSS connection... (\(tries) tries)")
            waitingForConnection = false
            do {
                try shellOut(to: "/usr/local/bin/jamf", arguments: ["checkJSSConnection", "-retry", "10"])
            } catch {
                // returns 0 if available or 1 if not available
                tries = tries + 10
                waitingForConnection = true
                sleep(10)
            }
        }
    }

    // NOTE: Currently exceptions are not caught when starting Jamf policies to allow the script to continue if a policy returns an error code. Add an option to retry policies or error out if a step fails.
    //do {
        for step in configuration.steps {
            if let status = step.status {
                print("Status: \(status)")
                await depnotify.setStatus(status)
            }
            
            if let content = step.content {
                await content.update()
            }
            
            if let script = step.runScript {
                print("Running script: \(script)")
                do {
                    let _ = try shellOut(to: script)
                } catch {
                    if let abortOnError = step.abortOnError, !abortOnError {
                        print("Error: \(error)")
                        print("Errors are ignored. Resuming deployment.")
                    } else  {
                        fatalError("Error running script. \(error)")
                    }
                }
            }
            
            if let event = step.event {
                print("Starting policies with event: \(event)")
                if !mockRun {
                    if let skipInventory = step.skipInventory, skipInventory == true {
                        let _ = try? shellOut(to: "/usr/local/bin/jamf", arguments: ["policy", "-event", event, "-forceNoRecon"])
                    } else {
                        let _ = try? shellOut(to: "/usr/local/bin/jamf", arguments: ["policy", "-event", event])
                    }
                }
            }
        }
        
        await depnotify.setStatus("")
        
        if let disableNotify = configuration.disableNotifyOnSuccess, disableNotify {
            if !mockRun {
                let args = configuration.authchangerArguments ?? ["-reset", "-JamfConnect"]
                let _ = try? shellOut(to: "/usr/local/bin/authchanger", arguments: args)
            }
            print("Disabled Jamf Connect DEPNotify script.")
        }
        
        if let completionContent = configuration.completionContent {
            await completionContent.update()
        }
        
        if let completionButton = configuration.completionButton {
            print("Enabling DEPNotify quit button titled \"\(completionButton)\".")
            await depnotify.showQuitButton(buttonLabel: completionButton)
        }
        
        if let completionText = configuration.completionText {
            print("Exiting DEPNotify with completion text: \(completionText)")
            await depnotify.quit(alertText: completionText)
        }
        
        FileManager.default.createFile(atPath: "/private/var/db/.DEPNotifySetupDone", contents: Data())
        
    if let completionEvent = configuration.completionEvent {
        print("Starting policies with completion event: \(completionEvent)")
        if !mockRun {
            let _ = try? shellOut(to: "/usr/local/bin/jamf", arguments: ["policy", "-event", completionEvent])
            
        }
    }
        
        await depnotify.quit()
      
    /*
    } catch {
        depnotify.status = "An error occurred communicating with Jamf Pro."
        fatalError("Error communicating with jamf command line. \(error)")
    }
     */

    let _ = enableScreenSleep()

    print("DEPNotify workflow complete.")
    exit(0)
}


