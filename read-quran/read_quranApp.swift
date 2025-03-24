//
//  read_quranApp.swift
//  read-quran
//
//  Created by husam saleh on 25/03/2025.
//

import SwiftUI

@main
struct read_quranApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the popover for displaying verses
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView().environmentObject(QuranVerseManager()))
        self.popover = popover
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "Quran"
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Make the popover active
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
