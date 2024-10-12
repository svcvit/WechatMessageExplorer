//
//  ContactListView.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import SwiftUI

struct ContactListView: View {
    @EnvironmentObject var viewModel: WechatViewModel
    
    var body: some View {
        List(viewModel.contacts, id: \.m_nsUsrName) { contact in
            NavigationLink(
                destination: MessageView(contact: contact),
                tag: contact,
                selection: $viewModel.selectedContact
            ) {
                Text(contact.m_nsNickName)
            }
        }
        .navigationTitle("联系人列表")
        .onAppear {
            viewModel.refreshData()
        }
        .onChange(of: viewModel.selectedContact) { newValue in
            if let contact = newValue {
                viewModel.getUserMessages(for: contact)
            }
        }
    }
}

