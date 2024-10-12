//
//  WechatMsg.swift
//  WechatMessageExplorer
//
//  Created by Ron Liu on 2024/10/12.
//

import Foundation
import SQLCipher
import AppKit
import CryptoKit

extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i*2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}

class WechatMsg {
    static let WECHAT_DIR = "/Users/\(NSUserName())/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/2.0b4.0.9"
    
    private let rawKey: String
    private var correctUserId: String?
    private var chatDb: [[String: String]]?
    
    static func canAccessWeChatDirectory() -> Bool {
        let fileManager = FileManager.default
        let testPath = WechatMsg.WECHAT_DIR
        
        do {
            _ = try fileManager.contentsOfDirectory(atPath: testPath)
            return true
        } catch {
            print("无法访问 TCC 目录：\(error)")
            return false
        }
    }
    
    static func requestFullDiskAccess() {
        let alert = NSAlert()
        alert.messageText = "需要完全磁盘访问权限"
        alert.informativeText = "为了访问 WeChat 数据，我们需要完全磁盘访问权限。请按照以下步骤操作：\n\n1. 点击 '打开系统偏好设置'\n2. 转到 '安全性与隐私' > '隐私' > '完全磁盘访问权限'\n3. 点击锁图标并输入密码以进行更改\n4. 在列表中找到并勾选本应用\n5. 重启应用以使更改生效"
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
        }
    }
    
    init(rawKey: String) throws {
        self.rawKey = rawKey
            print("Raw key: \(rawKey)")  // 添加这行
        
        if !WechatMsg.canAccessWeChatDirectory() {
            WechatMsg.requestFullDiskAccess()
            throw NSError(domain: "WechatMsg", code: 3, userInfo: [NSLocalizedDescriptionKey: "需要完全磁盘访问权限"])
        }
        
        print("Initializing WechatMsg")
        print("WECHAT_DIR: \(WechatMsg.WECHAT_DIR)")
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: WechatMsg.WECHAT_DIR) {
            print("WECHAT_DIR exists")
        } else {
            print("WECHAT_DIR does not exist")
            throw NSError(domain: "WechatMsg", code: 2, userInfo: [NSLocalizedDescriptionKey: "WeChat directory not found"])
        }
        
        print("Attempting to get user")
        if getUser() {
            print("User found, getting chat DB number")
            do {
                self.chatDb = try getChatDbNumber()
                print("Chat DB number retrieved successfully")
            } catch {
                print("Error getting chat DB number: \(error)")
                throw error
            }
        } else {
            print("No valid user found")
            throw NSError(domain: "WechatMsg", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Invalid key for any user DB"])
        }
        
        print("WechatMsg initialized successfully")
    }
    
    private func connectDb(dbPath: String) -> OpaquePointer? {
    print("尝试连接数据库：\(dbPath)")
    var dbPointer: OpaquePointer?

    if sqlite3_open(dbPath, &dbPointer) == SQLITE_OK {
        print("成功打开数据库")

        let key = processRawKey(rawKey)
        print("处理后的密钥：\(key)")

        // 尝试 SQLCipher 3 兼容模式
        let pragmas = [
            "PRAGMA cipher_compatibility = 3",
            "PRAGMA key = 'x''\(key)'''",
            "PRAGMA cipher_page_size = 1024",
            "PRAGMA kdf_iter = 64000",
            "PRAGMA cipher_hmac_algorithm = HMAC_SHA1",
            "PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1"
        ]

        for pragma in pragmas {
            if sqlite3_exec(dbPointer, pragma, nil, nil, nil) != SQLITE_OK {
                print("设置失败：\(pragma)")
                sqlite3_close(dbPointer)
                return nil
            }
        }

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(dbPointer, "SELECT count(*) FROM sqlite_master", -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int(statement, 0)
                print("连接验证成功，表数量：\(count)")
                sqlite3_finalize(statement)
                return dbPointer
            }
        }
        print("连接验证失败")
        sqlite3_close(dbPointer)
    } else {
        print("无法打开数据库")
    }

    return nil
}

    private func processRawKey(_ key: String) -> String {
        if key.hasPrefix("0x") {
            return String(key.dropFirst(2))
        }
        return key
    }
    
func getUserlist(nickname: String? = nil) -> [[String: String]]? {
    guard let correctUserId = correctUserId else { return nil }
    let dbPath = "\(WechatMsg.WECHAT_DIR)/\(correctUserId)/Contact/wccontact_new2.db"
    guard let db = connectDb(dbPath: dbPath) else { return nil }
    defer { sqlite3_close(db) }
    
    var query = "SELECT m_nsUsrName, nickname FROM WCContact WHERE m_nsUsrName NOT LIKE 'gh_%'"
    if let nickname = nickname {
        query += " AND nickname LIKE '%\(nickname)%'"
    }
    
    return getData(db: db, query: query)
}
    
func getUserMessages(userMd5: String) -> [[String: String]]? {
    let tableName = "Chat_\(userMd5)"
    guard let dbNumber = chatDb?.first(where: { $0["name"] == tableName })?["db_number"] else {
        print("未找到对应的数据库编号")
        return nil
    }
    guard let correctUserId = correctUserId else {
        print("未找到正确的用户 ID")
        return nil
    }
    let dbPath = "\(WechatMsg.WECHAT_DIR)/\(correctUserId)/Message/\(dbNumber)"
    print("尝试连接数据库：\(dbPath)")
    
    guard let db = connectDb(dbPath: dbPath) else {
        print("连接数据库失败")
        return nil
    }
    defer { sqlite3_close(db) }
    
    let query = "SELECT * FROM \(tableName)"
    print("执行查询：\(query)")
    let result = getData(db: db, query: query)
    print("查询结果条数：\(result?.count ?? 0)")
    return result
}
    
    static func prettierMessages(msgs: [[String: String]], msgType: Int = 1) -> [[String: String]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        
        let messageTypeDict: [Int: String] = [
            10000: "系统消息", 1: "普通文本", 3: "图片", 34: "语音",
            43: "视频", 47: "表情包", 48: "位置", 49: "分享消息"
        ]
        
        let messageDesDict: [Int: String] = [1: "user", 0: "assistant"]
        
        let filteredRows = msgs.filter { row in
            guard let messageTypeStr = row["messageType"],
                  let messageType = Int(messageTypeStr),
                  messageTypeDict[messageType] == messageTypeDict[msgType] else {
                return false
            }
            return true
        }
        
        return filteredRows.map { row in
            var newRow: [String: String] = [:]
            if let msgCreateTimeStr = row["msgCreateTime"],
               let msgCreateTime = Double(msgCreateTimeStr) {
                let date = Date(timeIntervalSince1970: msgCreateTime)
                newRow["datetime"] = dateFormatter.string(from: date)
            }
            if let messageTypeStr = row["messageType"],
               let messageType = Int(messageTypeStr) {
                newRow["msg_type"] = messageTypeDict[messageType] ?? messageTypeStr
            }
            if let mesDesStr = row["mesDes"],
               let mesDes = Int(mesDesStr) {
                newRow["msg_from"] = messageDesDict[mesDes] ?? mesDesStr
            }
            newRow["msgContent"] = row["msgContent"]
            return newRow
        }
    }
    
    private func getData(db: OpaquePointer, query: String) -> [[String: String]]? {
        var results: [[String: String]] = []
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String: String] = [:]
                let columns = sqlite3_column_count(statement)
                
                for i in 0..<columns {
                    if let name = sqlite3_column_name(statement, i),
                       let value = sqlite3_column_text(statement, i) {
                        let columnName = String(cString: name)
                        let columnValue = String(cString: value)
                        row[columnName] = columnValue
                    }
                }
                
                results.append(row)
            }
        } else {
            print("Error preparing statement: \(String(cString: sqlite3_errmsg(db)))")
            return nil
        }
        
        sqlite3_finalize(statement)
        return results
    }
    
    private func getChatDbNumber() throws -> [[String: String]] {
        var chatDb: [[String: String]] = []
        
        for i in 0..<10 {
            let dbPath = "\(WechatMsg.WECHAT_DIR)/\(correctUserId!)/Message/msg_\(i).db"
            print("PATH: \(dbPath)")
            guard let db = connectDb(dbPath: dbPath) else { continue }
            defer { sqlite3_close(db) }
            
            if let dfContent = getData(db: db, query: "SELECT * FROM sqlite_sequence") {
                for var row in dfContent {
                    row["db_number"] = "msg_\(i).db"
                    chatDb.append(row)
                }
            }
        }
        
        return chatDb
    }
    
    private func getUser() -> Bool {
        let keyValuePath = "\(WechatMsg.WECHAT_DIR)/KeyValue"
        print("Getting user from: \(keyValuePath)")
        let contents = listAllContents(path: keyValuePath)
        print("Contents of KeyValue directory: \(contents)")
        
        let potentialUsers = contents.filter { !$0.hasPrefix(".") }
        print("Potential users: \(potentialUsers)")
        
        for user in potentialUsers {
            let dbPath = "\(keyValuePath)/\(user)/KeyValue.db"
            print("Attempting to connect to user DB: \(dbPath)")
            if let db = connectDb(dbPath: dbPath) {
                correctUserId = user
                print("Valid user found: \(user)")
                sqlite3_close(db)
                return true
            }
        }
        print("No valid user found")
        return false
    }
    
    private func listAllContents(path: String) -> [String] {
        print("Listing all contents in: \(path)")
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            print("Found contents: \(contents)")
            return contents
        } catch {
            print("Error listing contents of directory: \(error)")
            return []
        }
    }
}

