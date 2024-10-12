//
//  MessageView.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import SwiftUI

struct MessageView: View {
    @EnvironmentObject var viewModel: WechatViewModel
    let contact: Contact
    
    var body: some View {
        VStack {
            Table(viewModel.messages[contact] ?? []) {
                TableColumn("发送者", value: \.from)
                TableColumn("类型", value: \.type)
                TableColumn("时间") { message in
                    Text(message.datetime)
                }
                TableColumn("内容", value: \.content)
            }
            .frame(minWidth: 500, minHeight: 300)
            
            HStack {
                Button(action: {
                    viewModel.getUserMessages(for: contact)
                }) {
                    Label("刷新聊天记录", systemImage: "arrow.clockwise")
                }
                
                Button(action: {
                    viewModel.refreshData()
                }) {
                    Label("刷新数据", systemImage: "arrow.clockwise")
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
        }
        .navigationTitle(contact.m_nsNickName)
    }
}

