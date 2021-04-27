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
    @State var canPut = true
    @State var pieceScale: CGFloat = 1
    @EnvironmentObject var viewModel: GoBangViewModel
    
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
                if viewModel.hasPiece(row: row, col: col) == false && viewModel.isConfirmed(row: row, col: col) == false{
                    cancelIsAble = true
                    confirmIsAble = true
                    viewModel.setPiece(row: row, col: col, state: .black, order: curOrderNum, confirmed: false)
                    
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
//        Rectangle()
//            .fill(Color.init(hex: boardColor))
//            .frame(width: 380, height: 380, alignment: .center)
        
        VStack {
            ZStack{
                Group {
                    Checkerboard(rows: BoardView.rows-1, columns: BoardView.columns-1)
                        .stroke(lineWidth: 2)
                    ForEach(viewModel.pieces) { piece in
                        ChessView(boardInfo: self.boardInfo, piece: piece, pieceScale: $pieceScale)
                    }
                }
                        .frame(width: BoardView.boardWidth, height: BoardView.boardHeight)
                        
    //                ForEach(model.pieces) { piece in
    //                    if piece.state == "B" {
    //                        ChessCircle(row: piece.row, col: piece.col, rows: BoardView.rows-1, columns: BoardView.columns-1, radius: BoardView.radius)
    //                    } else if piece.state == "W" {
    //                        ChessCircle(row: piece.row, col: piece.col, rows: BoardView.rows-1, columns: BoardView.columns-1, radius: BoardView.radius)
    //                            .fill(Color.white)
    //                    } else {
    //                    }
    //                }
                

                //.frame(width: BoardView.boardWidth, height: BoardView.boardHeight)
            }
                .frame(width: rectWidth, height: rectHeight)
                .background(Color.orange)
                .gesture(putPiece())
            ChessButton(cancelIsAble: $cancelIsAble, confirmIsAble: $confirmIsAble, tapLocation: $tapLocation, dragLocation: $dragLocation, row: $row, col: $col, curOrderNum: $curOrderNum, pieceScale: $pieceScale)
        }


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
    @EnvironmentObject var viewModel: GoBangViewModel
    var body: some View {
        HStack(spacing: 60) {
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
            viewModel.setPiece(row: row!, col: col!, state: .black, order: curOrderNum, confirmed: true)
            curOrderNum = curOrderNum + 1
        }
        confirmIsAble = false
        cancelIsAble = false
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

struct TapView: View {
    
    @State var tapLocation: CGPoint?
    
    @State var dragLocation: CGPoint?

    var locString : String {
        guard let loc = tapLocation else { return "Tap" }
        return "\(Int(loc.x)), \(Int(loc.y))"
    }
    
    var body: some View {
        
        let tap = TapGesture().onEnded { tapLocation = dragLocation }
        let drag = DragGesture(minimumDistance: 0).onChanged { value in
            dragLocation = value.location
        }.sequenced(before: tap)
        
        Text(locString)
        .frame(width: 200, height: 200)
        .background(Color.gray)
        .gesture(drag)
    }
}

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

//struct BoardView_Previews: PreviewProvider {
//    static var previews: some View {
//        BoardView()
//    }
//}
