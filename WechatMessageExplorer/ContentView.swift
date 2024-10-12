//
//  ContentView.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WechatViewModel()
    @State private var isShowingFullDiskAccessPrompt = false
    @State private var hasFullDiskAccess = false
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationView {
            VStack {
                ContactListView()
                controlBar
            }
            .frame(minWidth: 200)
            
            Group {
                if let selectedContact = viewModel.selectedContact {
                    MessageView(contact: selectedContact)
                } else {
                    Text("请选择一个联系人")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("微信消息查看器")
        .sheet(isPresented: $viewModel.isShowingPasswordPrompt) {
            PasswordPromptView()
        }
        .sheet(isPresented: $viewModel.isShowingDonationPrompt) {
            DonationView()
        }
        .alert(isPresented: $isShowingFullDiskAccessPrompt, content: fullDiskAccessAlert)
        .onAppear(perform: checkFullDiskAccess)
    }
    
    private var controlBar: some View {
        HStack(spacing: 8) {
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("退出", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.borderless)
            .help("退出")
            
            Spacer(minLength: 0)
            
            Button(action: requestFullDiskAccess) {
                Label(hasFullDiskAccess ? "已获得" : "磁盘权限",
                    systemImage: hasFullDiskAccess ? "checkmark.shield" : "lock.shield")
            }
            .buttonStyle(.borderless)
            .help(hasFullDiskAccess ? "已获得磁盘权限" : "请求磁盘权限")
            .foregroundColor(hasFullDiskAccess ? .green : .primary)
            .disabled(hasFullDiskAccess)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: 28)
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func fullDiskAccessAlert() -> Alert {
        Alert(
            title: Text("需要完全磁盘访问权限"),
            message: Text("为了访问 WeChat 数据，我们需要完全磁盘访问权限。请在系统偏好设置中授予权限。"),
            primaryButton: .default(Text("打开系统偏好设置"), action: openSystemPreferences),
            secondaryButton: .cancel()
        )
    }
    
    private func checkFullDiskAccess() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            hasFullDiskAccess = WechatMsg.canAccessWeChatDirectory()
            print("应用程序\(hasFullDiskAccess ? "已" : "没") 有完全磁盘访问权限")
        }
    }
    
    private func requestFullDiskAccess() {
        if !hasFullDiskAccess {
            isShowingFullDiskAccessPrompt = true
        }
    }
    
    private func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            openURL(url)
        }
    }
}
