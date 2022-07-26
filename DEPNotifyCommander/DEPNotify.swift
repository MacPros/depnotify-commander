//
//  DEPNotify.swift
//  NotifyCommander
//
//  Created by Eric Summers on 4/15/22.
//

import Foundation
import Files

/// A wrapper class to send commands to DEPNotify.
public class DEPNotify {
    
    public static let shared = try! DEPNotify()
    
    /// The file to log DEPNotify commands to
    private var _logFile: File
    
    /// Close DEPNotify when `notify_commander` exits
    public var closeOnDeinit: Bool = true
    
    public private(set) var logPath: String
        
    public init(logPath: String = "/var/tmp/depnotify.log", deleteExistingLog: Bool = true) throws {
        self.logPath = logPath
        let logURL = URL(fileURLWithPath: logPath)
        let logFileName = logURL.lastPathComponent
        let logFolderPath = logURL.deletingLastPathComponent().path
        let logFolder = try! Folder(path: logFolderPath)
        
        if deleteExistingLog {
            // Delete an existing DEPNotify log. Silently ignore errors.
            try? logFolder.file(named: logFileName).delete()
        }
        
        _logFile = try logFolder.createFile(named: logFileName)
    }
    
    deinit {
        if closeOnDeinit {
            quit()
        }
    }
    
    /// Run a DEPNotify command.
    ///
    /// - Parameter command: The DEPNotify command to run
    private func _command(_ command: String) {
        try? _logFile.append("Command: \(command)\n")
    }
    
    private func _status(_ status: String) {
        try? _logFile.append("Status: \(status)\n")
    }
    
    // MARK: Main Content
    
    public enum Image {
        case path(String)
        case url(URL)
    }
    
    public enum Video {
        case path(String)
        case url(URL)
        case youTube(id: String)
    }
    
    public enum MainContent {
        /// Change the main body to text
        case text(String)
        /// Change the main body to an icon
        case image(Image)
        /// Plays a video from a stream or local source. Video formats accepted: .m4v, .mp4, .m3u8
        case video(Video)
        /// Loads a website in DEPNotify
        case website(URL)
    }
    
    /// Change the default DEPNotify logo
    public var image: Image? = nil {
        didSet {
            switch image {
            case .path(let path):
                _command("Image: \(path)")
            case .url(let url):
                _command("Image: \(url.absoluteString)")
            case .none:
                _command("Image: ")
            }
        }
    }
    
    /// The main title of text in the application
    public var title: String = "" {
        didSet {
            _command("MainTitle: \(title)")
        }
    }
    
    public var content: MainContent? = nil {
        didSet {
            switch content {
            case .text(let text):
                _command("MainText: \(text)")
            case .image(let image):
                switch image {
                case .path(let path):
                    _command("MainTextImage: \(path)")
                case .url(let url):
                    _command("MainTextImage: \(url.absoluteString)")
                }
            case .video(let video):
                switch video {
                case .path(let path):
                    _command("Video: \(path)")
                case .url(let url):
                    _command("Video: \(url.absoluteString)")
                case .youTube(id: let id):
                    _command("YouTube: \(id)")
                }
            case .website(let url):
                _command("Website: \(url.absoluteString)")
            case .none:
                _command("MainText: ")
            }
        }
    }
    
    /// The status text
    public var status: String = "" {
        didSet {
            _status(status)
        }
    }
    
    // MARK: Progress Bar Management
    
    public enum ProgressBarMode {
        /// Disables a deterministic state for the progress bar. Note that the steps already occurred in the bar will remain, allowing you to move between a
        /// deterministic behavior and non-deterministic without loosing your place.
        case indeterminate
        /// This makes the progress bar be determinate instead of just a spinny bar. You need to follow this with the number of stages you'd like to have in the
        /// bar. Once set, you will need to manually tell DEPNotify when to update instead of relying on status updates or information from the various log files.
        /// This allows you to create a progress bar independent of status updates.
        case determinate(steps: Int)
        /// This makes the progress bar be determinate instead of just a spinny bar. You need to follow this with the number of stages you'd like to have in the
        /// bar. Once set, every status update that you send DEPNotify will increment the bar by one stage.
        case determinateAuto(steps: Int)
    }
    
    /// The progress bar mode
    public var progressBarMode: ProgressBarMode = .indeterminate {
        didSet {
            switch progressBarMode {
            case .indeterminate:
                _command("DeterminateOff:")
            case .determinate(let steps):
                _command("DeterminateManual: \(steps)")
            case .determinateAuto(let steps):
                _command("Determinate: \(steps)")
            }
        }
    }
    
    /// The current step in the progress
    public private(set) var progressBarStep: Int = 0
    
    /// Amount to advance a determinate progress bar by
    public func advanceProgressBar(by amount: Int = 1) {
        if amount > 0 {
            _command("DeterminateManualStep: \(amount)")
        }
    }
    
    /// Reset progress bar back to defaults. Set `progressBarMode` after calling.
    public func resetProgressBar() {
        progressBarStep = 0
        progressBarMode = .indeterminate
        _command("DeterminateOffReset:")
    }
    
    // MARK: Windows, Buttons, Alerts, and Notifications
    
    /// This shows a sheet with the specified URL loaded in the sheet.
    public func presentWebViewSheet(_ url: URL, buttonLabel: String) {
        _command("SetWebViewURL: \(url.absoluteString)")
        _command("ContinueButtonWeb: \(buttonLabel)")
    }
    
    /// This creates an alert sheet on the DEPNotify window with an "Ok" button to allow the user to clear the alert.
    public func showAlert(text: String) {
        _command("Alert: \(text)")
    }
    
    /// This will issue a notification to the Mac's notification center and display it.
    public func showNotification(text: String, imagePath: String? = nil) {
        if let imagePath = imagePath {
            _command("NotificationImage: \(imagePath)")
        }
        _command("Notification: \(text)")
    }
    
    /// This will cause all status updates to be sent to the Notification Center as well. It takes no modifiers.
    public func showStatusNotifications() {
        _command("NotificationOn:")
    }
    
    /// This places a Continue button at the bottom of the screen that quits DEPNotify. Creates a bom file
    /// `/var/tmp/com.depnotify.provisioning.done` on successful completion.
    public func showQuitButton(buttonLabel: String = "Continue") {
        _command("ContinueButton: \(buttonLabel)")
    }
    
    /// This places a Continue button at the bottom of the screen that will perform a logout of the Mac. Creates a bom file
    /// `/var/tmp/com.depnotify.provisioning.done` on successful completion.
    public func showLogoutButton(buttonLabel: String = "Continue") {
        _command("ContinueButtonLogout: \(buttonLabel)")
    }
    
    /// This places a Continue button at the bottom of the screen that will perform a soft restart of the Mac. Creates a bom file
    /// `/var/tmp/com.depnotify.provisioning.restart` on successful completion.
    public func showRestartButton(buttonLabel: String = "Continue") {
        _command("ContinueButtonRestart: \(buttonLabel)")
    }
    
    public func showEULAButton(buttonLabel: String) {
        _command("ContinueButtonEULA: \(buttonLabel)")
    }
    
    /// This shows a sheet dialog and then log the user out when the "Logout" button is clicked. This is commonly used to log the user out and initiate a
    /// FileVault encryption process.
    public func showLogoutSheet(text: String) {
        _command("Logout: \(text)")
    }
    
    /// This forces the DEPNotify window to the front of all other windows.
    ///
    ///  - Parameter onEachStep: This will force the window to the front for each new progress bar step, so that you don't have to issue the Activate
    ///                          command each time.
    public func activateWindow(onEachStep: Bool = false) {
        if onEachStep {
            _command("WindowStyle: ActivateOnStep")
        } else {
            _command("WindowStyle: Activate")
        }
    }
    
    /// This centers the DEPNotify window and make it unable to be moved.
    public func lockAndCenterWindow() {
        _command("WindowStyle: NotMovable")
    }
    
    // MARK: Other Commands
    
    /// This will change the default key to quit DEPNotify. By default this is the "x" key with the command and control keys held down. Setting `quitKey`
    /// allows you to change "x" to any other single character. Note: you are unable to modify the requirement for the command and control keys.
    public var quitKey: Character = "x" {
        didSet {
            _command("QuitKey: \(quitKey)")
        }
    }
    
    /// Executes an immediate logout of the user session without waiting until the user responds to the alert
    public func logout() {
        _command("LogoutNow:")
    }
    
    /// Quit DEPNotify. If alert text is specified, the alert dialog will be shown prior to quiting.
    public func quit(alertText: String = "", removeCommandFile: Bool = false) {
        if removeCommandFile {
            _command("KillCommandFile:")
        }
        if alertText != "" {
            _command("Quit: \(alertText)")
        } else {
            _command("Quit") // DEPNotify requires no `:` if alert text isn't specified.
        }
    }
    
}
