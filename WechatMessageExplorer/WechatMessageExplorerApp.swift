//
//  WechatMessageExplorerApp.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !WechatMsg.canAccessWeChatDirectory() {
            DispatchQueue.main.async {
                WechatMsg.requestFullDiskAccess()
            }
        }
    }
}

@main
struct WechatMessageExplorerApp: App {
    @StateObject private var viewModel = WechatViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
