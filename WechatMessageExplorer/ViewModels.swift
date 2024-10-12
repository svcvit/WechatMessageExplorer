//
//  ViewModels.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import Foundation
import Combine
import CryptoKit

class WechatViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var messages: [Contact: [Message]] = [:]
    @Published var selectedContact: Contact?
    @Published var isShowingPasswordPrompt = true
    @Published var isShowingDonationPrompt = false
    
    private var wechatMsg: WechatMsg?
    
    func getUserMessages(for contact: Contact) {
        let md5Username = MD5(string: contact.m_nsUsrName)
        print("正在获取用户 \(contact.m_nsNickName) 的聊天记录，MD5 用户名：\(md5Username)")
        
        if let messages = wechatMsg?.getUserMessages(userMd5: md5Username) {
            let prettierMessages = WechatMsg.prettierMessages(msgs: messages)
            DispatchQueue.main.async {
                self.messages[contact] = prettierMessages.map { row in
                    Message(from: row["msg_from"] ?? "",
                            type: row["msg_type"] ?? "",
                            datetime: row["datetime"] ?? "",
                            content: row["msgContent"] ?? "")
                }
                print("成功获取到 \(prettierMessages.count) 条聊天记录")
            }
        } else {
            print("获取聊天记录失败")
        }
    }
    
    func initializeWechatMsg(with key: String) throws {
        do {
            wechatMsg = try WechatMsg(rawKey: key)
            loadContacts()
        } catch {
            print("Error initializing WechatMsg: \(error)")
            throw error
        }
    }
    
    func loadContacts() {
        if let userlist = wechatMsg?.getUserlist() {
            contacts = userlist.map { Contact(m_nsUsrName: $0["m_nsUsrName"] ?? "", m_nsNickName: $0["nickname"] ?? "") }
        }
    }
    
    func refreshData() {
        loadContacts()
    }
    
    private func MD5(string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

