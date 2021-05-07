//
//  Message.swift
//  GoBang
//
//  Created by Rambo on 2021/4/16.
//

import Foundation

struct Message: Codable {
    
    var to: String? = ""
    var from: String? = ""
    var data: String? = ""
    var token: String? = ""
    var type = 0
    var messageId: Int = 0
    
    init() {
        
    }
    
    init(from: String) {
        self.from = from
    }
    
    init?(json: Data?) {
        if json != nil, let newMesage = try? JSONDecoder().decode(Message.self, from: json!) {
            self = newMesage
            print("json 字符串转换成功")
        } else {
            print("json 字符串转换失败")
            return nil
        }
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    var jsonStr: String? {
        return try? String(data: json!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
    }
    
    mutating func setRandomMessageId() {
        self.messageId = Int(arc4random_uniform(2147483647))
    }
    
    mutating func setFrom(from: String) {
        self.from = from
    }
    
    mutating func setTo(to: String) {
        self.to = to
    }
    
    mutating func setData(data: String) {
        self.data = data
    }
    
    mutating func setToken(token: String) {
        self.token = token
    }
    
    mutating func setType(type: Int) {
        self.type = type
    }
}

struct MessageType {
    static var CREATE_ROOM = 1
    static var EXIT_ROOM = 2
    static var READY = 3
    static var MOVE = 4
    static var GIVE_UP = 5
    static var CHAT = 6
    static var ENTER_ROOM_AS_WATCHER = 7
    static var ENTER_ROOM_AS_PLAYER = 8
    static var ESTABLISH = 10
    static var OPPONENT_EXIT_ROOM = 11
    static var OPPONENT_READY = 12
    static var WATCHER_EXIT_ROOM = 13
    static var OPPONENT_ENTER_ROOM = 14
    static var WIN = 15
    static var GET_ROOM_LIST = 16
    static var DISCONNECT = 17
    static var BEGIN_GAME = 18
    static var CANCEL_READY = 19
    static var MATCH_ROOM = 20
    static var CANCEL_MATCH = 21
    static var ACK = 22
    static var RECONNECT = 23
    static var HEART_BEAT = 24
}

