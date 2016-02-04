//
//  AppDelegate.swift
//  CrashReports
//
//  Created by Nicolas Seriot on 18/11/15.
//  Copyright © 2015 seriot.ch. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        checkForUpdates()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func checkForUpdates() {
        
        let url = NSURL(string:"http://www.seriot.ch/crashreports/crashreports.json")
        
        NSURLSession.sharedSession().dataTaskWithURL(url!) { (optionalData, response, error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(),{
                
                guard let data = optionalData,
                    optionalDict = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String:AnyObject],
                    d = optionalDict,
                    latestVersionString = d["latest_version_string"] as? String,
                    latestVersionURL = d["latest_version_url"] as? String
                    else {
                        return
                }
                
                print("-- latestVersionString: \(latestVersionString)")
                print("-- latestVersionURL: \(latestVersionURL)")
                
                let currentVersionString = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String
                
                let needsUpdate = currentVersionString < latestVersionString
                
                print("-- needsUpdate: \(needsUpdate)")
                if needsUpdate == false { return }
                
                let alert = NSAlert()
                alert.messageText = "CrashReports \(latestVersionString) is Available"
                alert.informativeText = "Please download it and replace the current version.";
                alert.addButtonWithTitle("Download")
                alert.addButtonWithTitle("Cancel")
                alert.alertStyle = .CriticalAlertStyle
                
                let modalResponse = alert.runModal()
                
                if modalResponse == NSAlertFirstButtonReturn {
                    if let downloadURL = NSURL(string:latestVersionURL) {
                        NSWorkspace.sharedWorkspace().openURL(downloadURL)
                    }
                }
                
            })
            }.resume()
    }
    
}
