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
    
    private var mChessColor: Piece.pieceState = .black;//自己的棋子的颜色
    private var pointSequence: [Piece] = [Piece]();//保存下棋的顺序

//    private OnChessDownListener mOnChessDownListener;
//    private OnWinListener mOnWinListener;
    //private var mChessRadius;//棋子半径

    //private int mNewPosX,mNewPosY;//新棋子的坐标  用于在该棋子上画点标注
    //private int mWidth; //view的宽度
    private var canLuoZi: Bool = false//能否落子

    private var needShowSequence = true//是否需要下棋的显示顺序
    private var needShowNewestCircle = false//是否需要显示最新棋子的圆点

    var winPoints: [[Int]] = []//用来保存胜利的5颗棋子的坐标
    //private Paint mTextPaint;//绘制棋子上面顺序的画笔
    private var isWin = false
    //private Paint mLinePaint;//划线
    //private Paint mCirclePaint;//画移动棋子外面的环
    //private boolean mHasChess = false;//棋盘上面是否有棋子
    
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
        for _ in 1...5 {
            var row = [Int]()
            for _ in 1...5 {
                row.append(0)
            }
            winPoints.append(row)
        }

        //pieces = GoBangModel.shufflePieces(pieces: pieces)
        
    }
    
    mutating func setPiece(row: Int, col: Int, state: Piece.pieceState, order: Int, confirmed: Bool) {
        pieces[col + row * columns].state = state
        board[row][col]?.state = state
        pieces[col + row * columns].order = order
        pieces[col + row * columns].confirmed = confirmed
        // 如果确认下了，加到序列中
        if confirmed {
            pointSequence.append(pieces[col + row * columns])
            if isWin(x: col, y: row, chessColor: state) {
                print("Win!!!!!!!")
            }
        }
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
    
    func getChessColor(row: Int, col: Int) -> Piece.pieceState {
        return pieces[col + row * columns].state
    }
    //x is col, y is row
    mutating func isWin(x: Int, y: Int, chessColor: Piece.pieceState) -> Bool {
        //是否赢了
        let startY = y - 4 < 0 ? 0 : y - 4
        let endY =  y + 4 >= 15 ? 15 - 1 : y + 4
        let startX = x - 4 < 0 ? 0 : x - 4
        let endX = x + 4 >= 15 ? 15 - 1 : x + 4
        //print("检查范围: startX \(startX) endX \(endX) startY \(startY) endY \(endY)")
        //横着检查
        var count = 0
        for col in startX...endX {
            if(chessColor == getChessColor(row: y,col: col)){
                winPoints[count][0] = col;
                winPoints[count][1] = y;
                count += 1
                if count == 5 {
                    return true;
                }
            }else{
                count = 0;
            }
        }

        //竖着检查
        count = 0;
        
        for row in startY...endY {
            if(chessColor == getChessColor(row: row,col: x)){
                winPoints[count][0] = x;
                winPoints[count][1] = row;
                count += 1
                if count == 5 { return true }
            }else{
                count = 0
            }
        }

        //右下斜检查
        count = 0;
        var col = x-4;
        var row = y-4;
        while(col<=x+4 && row<=y+4){
            if col < 0 || col >= 15 || row < 0 || row >= 15 {
                col += 1
                row += 1
                continue;
            }
            if chessColor == getChessColor(row: row,col: col) {
                winPoints[count][0] = col;
                winPoints[count][1] = row;
                count += 1
                if count==5 { return true }
            }else{
                count=0;
            }
            col += 1
            row += 1
        }

        //左下斜检查
        count = 0
        col = x+4
        row = y-4
        while(col>=x-4 && row<=y+4){
            if(col<0 || col>=15 || row<0 || row>=15){
                col -= 1;
                row += 1
                continue;
            }
            if(chessColor == getChessColor(row: row,col: col)){
                winPoints[count][0] = col;
                winPoints[count][1] = row;
                count += 1
                if count==5 { return true }
            }else{
                count=0;
            }
            col -= 1;
            row += 1
        }

        return false;
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

