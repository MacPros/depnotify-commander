//
//  Caffeinate.swift
//  depnotify_commander
//
//  Created by Eric Summers on 4/28/22.
//

import IOKit.pwr_mgt

var noSleepAssertionID: IOPMAssertionID = 0
var noSleepReturn: IOReturn? // Could probably be replaced by a boolean value, for example 'isBlockingSleep', just make sure 'IOPMAssertionRelease' doesn't get called, if 'IOPMAssertionCreateWithName' failed.

func disableScreenSleep(reason: String = "Unknown reason") -> Bool? {
    print("Preventing sleep. Reason: \(reason)")
    guard noSleepReturn == nil else { return nil }
    noSleepReturn = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                            IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                            reason as CFString,
                                            &noSleepAssertionID)
    return noSleepReturn == kIOReturnSuccess
}

func enableScreenSleep() -> Bool {
    print("Allowing sleep.")
    if noSleepReturn != nil {
        _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
        noSleepReturn = nil
        return true
    }
    return false
}
