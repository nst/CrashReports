//
//  AppDelegate.swift
//  CrashReports
//
//  Created by Nicolas Seriot on 18/11/15.
//  Copyright © 2015 seriot.ch. All rights reserved.
//

import Cocoa
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        checkForUpdates()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func checkForUpdates() {
        
        let url = URL(string:"http://www.seriot.ch/crashreports/crashreports.json")
        
        URLSession.shared.dataTask(with: url!, completionHandler: { (optionalData, response, error) -> Void in
            
            DispatchQueue.main.async(execute: {
                
                guard let data = optionalData,
                    let optionalDict = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:AnyObject],
                    let d = optionalDict,
                    let latestVersionString = d["latest_version_string"] as? String,
                    let latestVersionURL = d["latest_version_url"] as? String
                    else {
                        return
                }
                
                print("-- latestVersionString: \(latestVersionString)")
                print("-- latestVersionURL: \(latestVersionURL)")
                
                let currentVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                
                let needsUpdate = currentVersionString < latestVersionString
                
                print("-- needsUpdate: \(needsUpdate)")
                if needsUpdate == false { return }
                
                let alert = NSAlert()
                alert.messageText = "CrashReports \(latestVersionString) is Available"
                alert.informativeText = "Please download it and replace the current version.";
                alert.addButton(withTitle: "Download")
                alert.addButton(withTitle: "Cancel")
                alert.alertStyle = .critical
                
                let modalResponse = alert.runModal()
                
                if modalResponse == NSAlertFirstButtonReturn {
                    if let downloadURL = URL(string:latestVersionURL) {
                        NSWorkspace.shared().open(downloadURL)
                    }
                }
                
            })
            }) .resume()
    }
    
}
