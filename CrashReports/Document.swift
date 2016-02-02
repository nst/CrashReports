//
//  Document.swift
//  CrashReports
//
//  Created by Nicolas Seriot on 18/11/15.
//  Copyright © 2015 seriot.ch. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    @IBOutlet var textView: NSTextView!
    var crashReportPath: String?
    var crashReportInterpreted: String?
    var font: NSFont
    
    override init() {
        self.font = NSFont.userFixedPitchFontOfSize(11)!
        super.init()
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.

        guard let scriptPath = NSBundle.mainBundle().pathForResource("symbolicatecrash", ofType: "pl") else { return }
        guard self.crashReportPath != nil else { return }

        self.textView.selectable = true
        self.textView.editable = false
        
        self.textView.font = self.font
        self.textView.textColor = NSColor.disabledControlTextColor()

        do {
            self.textView.string = try NSString(contentsOfFile: self.crashReportPath!, encoding: NSUTF8StringEncoding) as String
        } catch let error as NSError {
            let alert = NSAlert(error:error)
            alert.runModal()
            return
        }
        
        var taskHasReceivedData = false
        
        let task = NSTask()
        task.launchPath = "/usr/bin/perl"
        task.arguments = [scriptPath, self.crashReportPath! as String]
        task.standardOutput = NSPipe()
//        task.standardError = task.standardOutput
        
        let readabilityHandler: (NSFileHandle!) -> Void = { file in

            let data = file.availableData
            let s = NSString(data: data, encoding: NSUTF8StringEncoding)
            let mas = NSMutableAttributedString(string: s as! String)
            
            mas.addAttribute(NSFontAttributeName, value: self.font, range: NSMakeRange(0, s!.length))

            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                if(taskHasReceivedData == false) {
                    self.textView.string = ""
                    taskHasReceivedData = true
                }

                self.textView.textColor = NSColor.controlTextColor()
                self.textView.textStorage?.appendAttributedString(mas)
            }
        }

        let terminationHandler: (NSTask!) -> Void = { task in
            
            dispatch_async(dispatch_get_main_queue()) {
                task.standardOutput?.fileHandleForReading.readabilityHandler = nil
                print("-- task terminated")
            }
        }

        task.standardOutput?.fileHandleForReading.readabilityHandler = readabilityHandler
        task.terminationHandler = terminationHandler
        
        task.launch()
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }
    
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        self.crashReportPath = url.path;
    }
}

