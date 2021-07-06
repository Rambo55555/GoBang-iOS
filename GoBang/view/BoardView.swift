//
//  BoardView.swift
//  GoBang
//
//  Created by Rambo on 2021/4/8.
//

import SwiftUI

struct BoardView: View {
    
    private let boardColor: Int = 0xbe933a
    private static let rows: Int = 15
    private static let columns: Int = 15
    private static let boardWidth: CGFloat = 350
    private static let boardHeight: CGFloat = 350
    private static let radius: CGFloat = 10
    
    //private var model = GoBangModel(rows: rows, columns: columns)
    private var boardInfo: BoardInfo = BoardInfo(size: CGSize(width: boardWidth, height: boardHeight), rows: rows, columns: columns)
    private var rectWidth: CGFloat = 380
    private var rectHeight: CGFloat = 400
    @State var tapLocation: CGPoint?
    @State var dragLocation: CGPoint?
    @State var row: Int?
    @State var col: Int?
    @State var curOrderNum = 1
    @State var cancelIsAble = false
    @State var confirmIsAble = false
    //@State var canPut = true
    @State var pieceScale: CGFloat = 1
    @State var player1: String = ""
    @State var player2: String = ""
    @State var isWhite: Bool = true
    @State var isPlayer1Ready: String = "未准备"
    @State var isPlayer2Ready: String = ""
    @State var readyIsAble: Bool = true
    @State var room: Room = Room()
    @State var noteMessage: String = ""
    @State var canPutPiece: Bool = false
    @State var pieceColor: GoBangModel.Piece.pieceState = .black
    @EnvironmentObject var viewModel: GoBangViewModel
    //@State var isImageAble: Bool = false
    //@State var winState: Bool = false
    @State var readyButtonText = "准备"
//    init(viewModel: GoBangViewModel) {
//        self.viewModel = viewModel
//    }

    
    var locString : String {
        guard let loc = tapLocation else { return "Tap" }
        return "\(Int(loc.x)), \(Int(loc.y))"
    }
    
    func putPiece() -> some Gesture {
        let tap = TapGesture().onEnded {
            withAnimation {
                pieceScale = 1
            }
            tapLocation = dragLocation
        }
        let drag = DragGesture(minimumDistance: 0).onChanged { value in
            dragLocation = value.location
        }
        .sequenced(before: tap)
        .onEnded { value in
            if let row = row, let col = col {
                if viewModel.isConfirmed(row: row, col: col) == false {
                    viewModel.setPiece(row: row, col: col, state: .out, order: curOrderNum, confirmed: false)
                }
            }
            if let loc = tapLocation {
                // compute the row and the col
                var col: Int = 0
                var row: Int = 0
                if loc.x < (rectWidth - BoardView.boardWidth)/2.0{
                    col = 0
                } else if  loc.x > (rectWidth + BoardView.boardWidth)/2.0 {
                    col = boardInfo.columns-1
                } else {
                    let xInSide = loc.x - (rectWidth - BoardView.boardWidth)/2.0
                    //print("xInSide: \(xInSide) columnSize: \(boardInfo.columnSize) size: \(boardInfo.size)")
                    col = Int(ceil(xInSide / boardInfo.columnSize - 0.5))
                }

                if loc.y < (rectHeight - BoardView.boardHeight)/2.0{
                    row = 0
                } else if  loc.y > (rectHeight + BoardView.boardHeight)/2.0 {
                    row = boardInfo.rows-1
                } else {
                    let yInSide = loc.y - (rectHeight - BoardView.boardHeight)/2.0
                    row = Int(ceil(yInSide / boardInfo.rowSize - 0.5))
                }
    //            var col: Int = Int(ceil((loc.x - (rectWidth - BoardView.boardWidth)/2) / boardInfo.columnSize - 1))
    //            let row: Int = Int(ceil((loc.y - (rectHeight - BoardView.boardHeight)/2) / boardInfo.rowSize - 1))
                print("location row: \(row) col: \(col)")
                //print("token: \(viewModel.user!.token)")
                if !viewModel.hasPiece(row: row, col: col) && !viewModel.isConfirmed(row: row, col: col) && canPutPiece {
                    cancelIsAble = true
                    confirmIsAble = true
                    viewModel.setPiece(row: row, col: col, state: pieceColor, order: curOrderNum, confirmed: false)
                }
                self.row = row
                self.col = col
                withAnimation {
                    pieceScale = 1.25
                }
            }
            
        }
        return drag
    }
    
    var body: some View {
        
        VStack(spacing: 50) {
            
            RoomView(readyIsAble: $readyIsAble, noteMessage: $noteMessage, readyButtonText: $readyButtonText).environmentObject(viewModel)
            ZStack{
                Group {
                    Checkerboard(rows: BoardView.rows-1, columns: BoardView.columns-1)
                        .stroke(lineWidth: 2)
                    ForEach(viewModel.pieces) { piece in
                        ChessView(boardInfo: self.boardInfo, piece: piece, pieceScale: $pieceScale)
                    }
                }
                .frame(width: BoardView.boardWidth, height: BoardView.boardHeight)
            }
                .frame(width: rectWidth, height: rectHeight)
                .background(Color.orange)
                .gesture(putPiece())
            
            ChessButton(cancelIsAble: $cancelIsAble, confirmIsAble: $confirmIsAble, tapLocation: $tapLocation, dragLocation: $dragLocation, row: $row, col: $col, curOrderNum: $curOrderNum, pieceScale: $pieceScale, pieceColor: $pieceColor, noteMessage: $noteMessage, canPutPiece: $canPutPiece)
        }
        .navigate(to: ImageView(winState: $viewModel.winState).environmentObject(ImageViewModel()), when: $viewModel.isImageAble, navBarHiden: false)
        .onAppear(){
            viewModel.winState = false
            viewModel.addMessageHandler(onResponse: messageHandler)
        }
        .onDisappear(){
            viewModel.exitRoom(roomId: room.roomId, onResponse: {message in })
            viewModel.clearRoomInfo()
        }


    }
    func messageHandler(message: Message) -> () {
        switch message.type {
        case MessageType.OPPONENT_ENTER_ROOM:
            print("对手进入房间")
            onOpponentEnterRoom(message: message)
        case MessageType.OPPONENT_READY:
            onOpponentReady(message: message)
            print("对手已经准备 \(viewModel.room)")
        case MessageType.BEGIN_GAME:
            print("游戏开始")
            // 游戏开始动画
            onBeginGame(message: message)
        case MessageType.MOVE:
            print("移动棋子")
            onMove(message: message)
        case MessageType.CANCEL_READY:
            onOpponentCancelReady(message: message)
            print("对手取消准备 \(viewModel.room)")
        case MessageType.OPPONENT_EXIT_ROOM:
            print("退出房间")
            noteMessage = "对手退出房间"
        case MessageType.WIN:
            print("胜利: \(message)")
            onWin(message: message)
        default:
            print("default ")
        }
    }
    func onWin(message: Message) {
        let winnerString = message.data!
        
        let index = winnerString.index(winnerString.startIndex, offsetBy: 1)
        let winner = winnerString[index...]
        print("winner: \(winner)")
        if winner == viewModel.user!.username {
            noteMessage = "你赢了"
            canPutPiece = false
            viewModel.isImageAble = true
            viewModel.winState = true
        } else {
            noteMessage = "你输了"
            canPutPiece = false
            viewModel.isImageAble = true
            viewModel.winState = false
        }
    }
    func onMove(message: Message) {
        viewModel.onMovePiece(message: message, order: curOrderNum) { isWin in
            if isWin {
                curOrderNum += 1
                noteMessage = "你输了"
                canPutPiece = false
                viewModel.isImageAble = true
                viewModel.winState = false
            } else {
                curOrderNum += 1
                canPutPiece = true
            }
        }
        if viewModel.user!.username == viewModel.room.player1!.username {
            viewModel.isPlayer1TimerAble = true
            viewModel.player1TimeRemaining = 60
            viewModel.isPlayer2TimerAble = false
            viewModel.startTimer1()
        } else {
            viewModel.isPlayer2TimerAble = true
            viewModel.player2TimeRemaining = 60
            viewModel.isPlayer1TimerAble = false
            viewModel.startTimer2()
        }
        
    }
    func onOpponentEnterRoom(message: Message) {
        viewModel.onOpponentJoinRoom(message: message)
        setRoomInfo()
    }
    func onOpponentReady(message: Message) {
//        viewModel.onOpponentJoinRoom(message: message)
//        isPlayer1Ready = viewModel.room.isPlayer1Ready() ? "已准备" : "未准备"
//        isPlayer2Ready = viewModel.room.isPlayer2Ready() ? "已准备" : "未准备"
//        isWhite = viewModel.room.player1?.chessColor == 0
//        player1 = viewModel.room.player1!.username
//        player2 = viewModel.room.player2!.username
        viewModel.onOpponentReady(message: message)
        //setRoomInfo()
    }
    func onOpponentCancelReady(message: Message) {
        viewModel.onOpponentCancelReady(message: message)
        //setRoomInfo()
    }
    // 游戏开始动画
    func onBeginGame(message: Message) {
        readyIsAble = false
        noteMessage = "游戏开始 你是"
        // 黑棋是 0
        if Int(message.data!) == 0 {
            noteMessage += "黑棋先手"
            pieceColor = .black
            canPutPiece = true
            if viewModel.user!.username == viewModel.room.player1!.username {
                viewModel.isPlayer1TimerAble = true
                viewModel.player1TimeRemaining = 60
                viewModel.startTimer1()
            } else {
                viewModel.isPlayer2TimerAble = true
                viewModel.player2TimeRemaining = 60
                viewModel.startTimer2()
            }
            
        } else {
            noteMessage += "白棋后手"
            pieceColor = .white
            if viewModel.user!.username != viewModel.room.player1!.username {
                viewModel.isPlayer1TimerAble = true
                viewModel.player1TimeRemaining = 60
                viewModel.startTimer1()
            } else {
                viewModel.isPlayer2TimerAble = true
                viewModel.player2TimeRemaining = 60
                viewModel.startTimer2()
            }
        }
    }
    
    func setRoomInfo() {
        isPlayer1Ready = viewModel.room.isPlayer1Ready() ? "已准备" : "未准备"
        isPlayer2Ready = viewModel.room.isPlayer2Ready() ? "已准备" : "未准备"
        isWhite = viewModel.room.player1?.chessColor == 0
        player1 = viewModel.room.player1!.username
        player2 = viewModel.room.player2!.username
    }
    

}

struct ChessButton: View {
    @Binding var cancelIsAble: Bool
    @Binding var confirmIsAble: Bool
    @Binding var tapLocation: CGPoint?
    @Binding var dragLocation: CGPoint?
    @Binding var row: Int?
    @Binding var col: Int?
    @Binding var curOrderNum: Int
    @Binding var pieceScale: CGFloat
    @Binding var pieceColor: GoBangModel.Piece.pieceState
    @Binding var noteMessage: String
    @Binding var canPutPiece: Bool

    @EnvironmentObject var viewModel: GoBangViewModel
    var body: some View {
        HStack(spacing: 60) {
            Button("认输") {
                viewModel.giveUp { message in
                    if message.data == "ERROR" {
                        print("投降失败")
                    } else {
                        print(message)
                        curOrderNum += 1
                        noteMessage = "你输了"
                        canPutPiece = false
                        viewModel.isImageAble = true
                        viewModel.winState = false
                    }
                }
            }
            Button(action: {
                if viewModel.isConfirmed(row: row!, col: col!) == false {
                    viewModel.setPiece(row: row!, col: col!, state: .out, order: curOrderNum, confirmed: false)
                    confirmIsAble = false
                    cancelIsAble = false
                }
            }, label: {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
            })
            .disabled(cancelIsAble == false)
            Button(action: {
                confirm()
            }, label: {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
            })
            .disabled(confirmIsAble == false)
        }
    }
    
    func confirm() {
        if viewModel.isConfirmed(row: row!, col: col!) == false {
            //viewModel.setPiece(row: row!, col: col!, state: .black, order: curOrderNum, confirmed: true)
            viewModel.putPiece(row: row!, col: col!, state: pieceColor, order: curOrderNum, onResponse: {message in print("落子成功")})
            curOrderNum += 1
        }
        confirmIsAble = false
        cancelIsAble = false
        if viewModel.user!.username == viewModel.room.player1!.username {
            viewModel.isPlayer1TimerAble = false
            viewModel.isPlayer2TimerAble = true
            viewModel.player2TimeRemaining = 60
        } else {
            viewModel.isPlayer2TimerAble = false
            viewModel.isPlayer1TimerAble = true
            viewModel.player1TimeRemaining = 60
        }
        if viewModel.isWin(row: row!, col: col!, state: pieceColor) {
            noteMessage = "你赢了"
            canPutPiece = false
            viewModel.isImageAble = true
            viewModel.winState = false
        } else {
            canPutPiece = false
        }
    }
}

struct Checkerboard: Shape {
    let rows: Int
    let columns: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // figure out how big each row/column needs to be
        let rowSize = rect.height / CGFloat(rows)
        let columnSize = rect.width / CGFloat(columns)

        // 1. draw the row and column line
        for row in 0...rows {
            let startX = columnSize * CGFloat(0)
            let startY = rowSize * CGFloat(row)
            let endX = rect.width
            let endY = rowSize * CGFloat(row)
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        
        for column in 0...columns {
            let startX = columnSize * CGFloat(column)
            let startY = rowSize * CGFloat(0)
            let endX = columnSize * CGFloat(column)
            let endY = rect.height
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        
        
        // 2. draw the circle
        var leftTop: CGPoint = CGPoint(x: 7 * columnSize, y: 7 * rowSize)
        let radius: CGFloat = 2.5
        leftTop = CGPoint(x: 7 * columnSize, y: 7 * rowSize)
        path.move(to: CGPoint(x: leftTop.x + radius, y: leftTop.y))
        // - MARK: need to fix
        path.addArc(center: leftTop, radius: CGFloat(radius), startAngle: Angle.degrees(0), endAngle: Angle.degrees(1), clockwise: true)
        
        leftTop = CGPoint(x: 3 * columnSize, y: 3 * rowSize)
        path.move(to: CGPoint(x: leftTop.x + radius, y: leftTop.y))
        path.addArc(center: leftTop, radius: CGFloat(radius), startAngle: Angle.degrees(0), endAngle: Angle.degrees(1), clockwise: true)
        
        leftTop = CGPoint(x: 11 * columnSize, y: 3 * rowSize)
        path.move(to: CGPoint(x: leftTop.x + radius, y: leftTop.y))
        path.addArc(center: leftTop, radius: CGFloat(radius), startAngle: Angle.degrees(0), endAngle: Angle.degrees(1), clockwise: true)
        
        leftTop = CGPoint(x: 3 * columnSize, y: 11 * rowSize)
        path.move(to: CGPoint(x: leftTop.x + radius, y: leftTop.y))
        path.addArc(center: leftTop, radius: CGFloat(radius), startAngle: Angle.degrees(0), endAngle: Angle.degrees(1), clockwise: true)
        
        leftTop = CGPoint(x: 11 * columnSize, y: 11 * rowSize)
        path.move(to: CGPoint(x: leftTop.x + radius, y: leftTop.y))
        path.addArc(center: leftTop, radius: CGFloat(radius), startAngle: Angle.degrees(0), endAngle: Angle.degrees(1), clockwise: true)
        
        return path
    }
}

struct BoardInfo {
    var size: CGSize
    let rows: Int
    let columns: Int
    var rowSize: CGFloat {
        size.height / CGFloat(rows-1)
    }
    var columnSize: CGFloat {
        size.width / CGFloat(columns-1)
    }
}

struct ChessView: View {
    var boardInfo: BoardInfo
    var piece: GoBangModel.Piece
    @Binding var pieceScale: CGFloat
    
    var body: some View {
        ZStack {
            if piece.confirmed == true {
                if piece.state == .black {
                    Image(uiImage: UIImage(named: "Black")!)
                        .resizable()
                        .frame(width: 22, height: 22)
                    Text(String(piece.order!))
                        .font(.caption)
                        .foregroundColor(Color.white)
                    
                } else if piece.state == .white{
                    Image(uiImage: UIImage(named: "White")!)
                        .resizable()
                        .frame(width: 22, height: 22)
                    Text(String(piece.order!))
                        .font(.caption)
                        .foregroundColor(Color.black)
                } else {
                    
                }
            } else {
                if piece.state == .black {
                    Image(uiImage: UIImage(named: "Black")!)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .scaleEffect(pieceScale)
                        .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true))
                        
                } else if piece.state == .white{
                    Image(uiImage: UIImage(named: "White")!)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .scaleEffect(pieceScale)
                        .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true))
                }
            }
        }
            .position(location())
    }

    
    func location() -> CGPoint {
        let point: CGPoint = CGPoint(x: CGFloat(piece.col) * boardInfo.columnSize, y: CGFloat(piece.row) * boardInfo.rowSize)
        return point;
    }
    
}

//struct TapView: View {
//
//    @State var tapLocation: CGPoint?
//
//    @State var dragLocation: CGPoint?
//
//    var locString : String {
//        guard let loc = tapLocation else { return "Tap" }
//        return "\(Int(loc.x)), \(Int(loc.y))"
//    }
//
//    var body: some View {
//
//        let tap = TapGesture().onEnded { tapLocation = dragLocation }
//        let drag = DragGesture(minimumDistance: 0).onChanged { value in
//            dragLocation = value.location
//        }.sequenced(before: tap)
//
//        Text(locString)
//        .frame(width: 200, height: 200)
//        .background(Color.gray)
//        .gesture(drag)
//    }
//}

struct ChessCircle: Shape {
    let row: Int
    let col: Int
    let rows: Int
    let columns: Int
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // figure out how big each row/column needs to be
        let rowSize: CGFloat = rect.height / CGFloat(rows)
        let columnSize: CGFloat = rect.width / CGFloat(columns)
        let leftTop = CGPoint(x: CGFloat(col) * columnSize, y: CGFloat(row) * rowSize)
         
        path.move(to: CGPoint(x: leftTop.x + radius, y: leftTop.y))
        // - MARK: need to fix
        path.addArc(center: leftTop, radius: CGFloat(10), startAngle: Angle.degrees(0), endAngle: Angle.degrees(1), clockwise: true)
        return path
    }
}

struct RoomView: View {
    
    @EnvironmentObject var viewModel: GoBangViewModel
    @Binding var readyIsAble: Bool
    @Binding var noteMessage: String
    @Binding var readyButtonText: String
    
    var body: some View {
        VStack() {
            HStack() {
                VStack(spacing: 20) {
                    if viewModel.room.player1?.chessColor == 0 {
                        Image(systemName: "person")
                            .scaleEffect(4)
                    } else {
                        Image(systemName: "person.fill")
                            .scaleEffect(4)
                    }
                    Text(viewModel.room.player1!.username)
                    Text(viewModel.room.player1!.status == 0 ? "未准备" : "已准备")
                    Text("\(viewModel.player1TimeRemaining)")
                        .opacity(viewModel.isPlayer1TimerAble ? 1 : 0)
//                        .onReceive(viewModel.timer) { input in
//                        if viewModel.player1TimeRemaining > 0 {
//                            viewModel.player1TimeRemaining -= 1
//                            print("计时器：\(input)")
//                        } else {
//                            viewModel.timer.invalidate()
//                        }
//                    }
                        
                }
                VStack(spacing: 25) {
                    Text("房间号")
                    Text(String(viewModel.room.roomId))
                    Button(action: {
                        //准备
                        if readyButtonText == "准备" {
                            viewModel.ready(roomId: viewModel.room.roomId) { message in
                                if message.data == "ERROR" {
                                    print("准备失败")
                                } else {
                                    print(message)
                                    viewModel.setSelfReady(ready: true)
                                    readyButtonText = "取消准备"
                                }
                            }
                        } else {
                            viewModel.cancelReady(roomId: viewModel.room.roomId) { message in
                                if message.data == "ERROR" {
                                    print("取消准备失败")
                                } else {
                                    print(message)
                                    viewModel.setSelfReady(ready: false)
                                    readyButtonText = "准备"
                                }
                            }
                        }
                    }, label: {
                        Text(readyButtonText)
                            .font(Font.system(size:30, design: .rounded))
                            .disabled(readyIsAble == false)
                    })
                    .opacity(readyIsAble ? 1 : 0)
                    
                }
                .frame(width: 150, height: 100)
                VStack(spacing: 25) {
                    if viewModel.room.player1?.chessColor == 1 {
                        Image(systemName: "person")
                            .scaleEffect(4)
                    } else {
                        Image(systemName: "person.fill")
                            .scaleEffect(4)
                    }
                    Text(viewModel.room.player2!.username)
                    Text(viewModel.room.player2!.status == 0 ? "未准备" : "已准备")
                    Text("\(viewModel.player2TimeRemaining)")
//                        .onReceive(viewModel.timer) { input in
//                        if viewModel.player2TimeRemaining > 0 {
//                            viewModel.player2TimeRemaining -= 1
//                        }
//                    }
                        .opacity(viewModel.isPlayer2TimerAble ? 1 : 0)
                }
                
            }
            Text(noteMessage)
        }
        
    }
    
}

//struct BoardView_Previews: PreviewProvider {
//    static var previews: some View {
//        BoardView()
//    }
//}
