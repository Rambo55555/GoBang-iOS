//
//  GoBangModel.swift
//  GoBang
//
//  Created by Rambo on 2021/4/8.
//

import Foundation

struct GoBangModel {
    var rows: Int
    var columns: Int
    var pieces: Array<Piece>
    var board: [[Piece?]] = []
    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        pieces = Array<Piece>()
        for row in 0..<rows {
            board.append([])
            for col in 0..<columns {
                let piece = Piece(id: col + row * columns, row: row, col: col, state: .out, confirmed: false)
                pieces.append(piece)
                board[row].append(piece)
            }
        }

        //pieces = GoBangModel.shufflePieces(pieces: pieces)
        
    }
    
    mutating func setPiece(row: Int, col: Int, state: Piece.pieceState, order: Int, confirmed: Bool) {
        pieces[col + row * columns].state = state
        board[row][col]?.state = state
        pieces[col + row * columns].order = order
        pieces[col + row * columns].confirmed = confirmed
    }
    
    mutating func isConfirmed(row: Int, col: Int) -> Bool {
        return pieces[col + row * columns].confirmed
    }
    
    func hasPiece(row: Int, col: Int) -> Bool {
        return pieces[col + row * columns].state != .out
    }
    
    static func shufflePieces(pieces: Array<Piece>) -> Array<Piece> {
        var data: Array<Piece> = pieces
        for i in 0..<pieces.count {
            let index: Int = Int(arc4random()) % 3
            if index == 0 {
                data[i].state = .black
            } else if index == 1 {
                data[i].state = .white
            } else {
                data[i].state = .out
            }
        }
        return data
    }
    struct Piece: Identifiable {
        var id: Int
        var row: Int
        var col: Int
        var state: pieceState
        var order: Int?
        var confirmed: Bool
        enum pieceState {
            case black
            case white
            case out
        }
    }
}

