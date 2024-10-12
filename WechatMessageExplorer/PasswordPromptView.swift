//
//  PasswordPromptView.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import SwiftUI

struct PasswordPromptView: View {
    @EnvironmentObject var viewModel: WechatViewModel
    @State private var password = ""
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("请输入数据库密码")
                .font(.headline)
            
            SecureField("密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("确认") {
                    initializeDatabase()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(password.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
        .onAppear {
            checkFullDiskAccess()
        }
    }
    
    private func checkFullDiskAccess() {
        if !WechatMsg.canAccessWeChatDirectory() {
            WechatMsg.requestFullDiskAccess()
            errorMessage = "需要完全磁盘访问权限，请在系统设置中授予权限后重试。"
        }
    }
    
    private func initializeDatabase() {
        do {
            if WechatMsg.canAccessWeChatDirectory() {
                try viewModel.initializeWechatMsg(with: password)
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = "需要完全磁盘访问权限，请在系统设置中授予权限后重试。"
            }
        } catch {
            errorMessage = "初始化失败：\(error.localizedDescription)"
        }
    }
}

