//
//  Position.swift
//  GoBang
//
//  Created by Rambo on 2021/5/6.
//

import Foundation

struct Position: Codable {
    var x: Int = 0
    var y: Int = 0
    var chessColor: Int = 0 // black 0
    
    init() {
        
    }
    init(row: Int, col: Int, state: GoBangModel.Piece.pieceState) {
        self.x = col
        self.y = row
        self.chessColor = state == GoBangModel.Piece.pieceState.black ? 0 : 1
    }
    init?(json: Data?) {
        if json != nil, let new = try? JSONDecoder().decode(Position.self, from: json!) {
            self = new
        } else {
            return nil
        }
    }
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    var jsonStr: String? {
        return try? String(data: json!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
    }
}
