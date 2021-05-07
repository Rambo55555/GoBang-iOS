//
//  Room.swift
//  GoBang
//
//  Created by Rambo on 2021/4/28.
//

import Foundation

struct Room: Codable {
    var roomId: Int = 0
    var player1: Player? = Player()
    var player2: Player? = Player()
    
    init(){
        
    }
    init?(json: Data?) {
        if json != nil, let new = try? JSONDecoder().decode(Room.self, from: json!) {
            self = new
        } else {
            return nil
        }
    }
    func isPlayer2Ready() -> Bool {
        return player2!.status != 0
    }
    func isPlayer1Ready() -> Bool {
        return player1!.status != 0
    }
}

struct Player: Codable {
    var username: String = ""
    var chessColor: Int = 0
    var status: Int = 0
    
}
