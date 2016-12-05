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
        self.font = NSFont.userFixedPitchFont(ofSize: 11)!
        super.init()
    }

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.

        guard let scriptPath = Bundle.main.path(forResource: "symbolicatecrash", ofType: "pl") else { return }
        guard let crashReportPath = self.crashReportPath else { return }
        
        self.textView.isSelectable = true
        self.textView.isEditable = false
        
        self.textView.font = self.font
        self.textView.textColor = NSColor.disabledControlTextColor

        do {
            self.textView.string = try NSString(contentsOfFile:crashReportPath, encoding:String.Encoding.utf8.rawValue) as String
        } catch let error as NSError {
            let alert = NSAlert(error:error)
            alert.runModal()
            return
        }
        
        var taskHasReceivedData = false
        
        let task = Process()
        task.launchPath = "/usr/bin/perl"
        task.arguments = [scriptPath, crashReportPath]
        task.standardOutput = Pipe()
//        task.standardError = task.standardOutput
        
        let readabilityHandler: (FileHandle!) -> Void = { file in

            let data = file.availableData
            var mas = NSMutableAttributedString(string: "")

            if let s = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                mas = NSMutableAttributedString(string: s as String)
            }
            
            mas.addAttribute(NSFontAttributeName, value: self.font, range: NSMakeRange(0, mas.length))

            DispatchQueue.main.async { [unowned self] in
                if(taskHasReceivedData == false) {
                    self.textView.string = ""
                    taskHasReceivedData = true
                }

                self.textView.textColor = NSColor.controlTextColor
                self.textView.textStorage?.append(mas)
            }
        }

        let terminationHandler: (Process!) -> Void = { task in
            
            DispatchQueue.main.async {
                guard let output = task.standardOutput as? Pipe else { return }
                output.fileHandleForReading.readabilityHandler = nil
                Swift.print("-- task terminated")
            }
        }

        guard let output = task.standardOutput as? Pipe else { return }
        output.fileHandleForReading.readabilityHandler = readabilityHandler
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
    
    override func read(from url: URL, ofType typeName: String) throws {
        self.crashReportPath = url.path
    }
}

