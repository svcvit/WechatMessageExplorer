//
//  Models.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import Foundation

struct Contact: Identifiable, Hashable {
    let id = UUID()
    let m_nsUsrName: String
    let m_nsNickName: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
}

struct Message: Identifiable {
    let id = UUID()
    let from: String
    let type: String
    let datetime: String  // 注意这里变成了 String 类型
    let content: String
}

