//
//  User.swift
//  GoBang
//
//  Created by Rambo on 2021/4/16.
//

import Foundation

public struct User: Codable {
    var username: String
    var password: String
    var token: String
    
    init(){
        self.username = ""
        self.password = ""
        self.token = ""
    }
    init(username: String, password: String, token: String) {
        self.username = username
        self.password = password
        self.token = token
    }
    
    init?(json: Data?) {
        if json != nil, let newUser = try? JSONDecoder().decode(User.self, from: json!) {
            self = newUser
        } else {
            return nil
        }
    }
    
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
}
