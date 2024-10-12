//
//  DonationView.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import SwiftUI

struct DonationView: View {
    @EnvironmentObject var viewModel: WechatViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("捐助作者，支持项目发展")
                .font(.headline)
            
            Image(systemName: "qrcode")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .foregroundColor(.gray)
            
            Button("关闭", action: closeDonationPrompt)
                .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(width: 300, height: 350)
    }
    
    private func closeDonationPrompt() {
        viewModel.isShowingDonationPrompt = false
        presentationMode.wrappedValue.dismiss()
    }
}
