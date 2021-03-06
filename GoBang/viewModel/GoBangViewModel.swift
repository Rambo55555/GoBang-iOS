//
//  GoBangViewModel.swift
//  GoBang
//
//  Created by Rambo on 2021/4/12.
//

import SwiftUI
import Combine

class GoBangViewModel: ObservableObject{

    @Published private var goBangModel: GoBangModel = GoBangModel(rows: 15, columns: 15)
    @Published var user: User? = User()
    private let defaultKey = "userInfo"
    private var autosaveCancellable: AnyCancellable?
    var socketHelper: SocketHelper = SocketHelper()
    //var roomNumber: String = ""
    @Published var room: Room = Room()
    
    @Published var loginStatus: Bool = false
    @Published var isPlayer1TimerAble: Bool = false
    @Published var isPlayer2TimerAble: Bool = false
    @Published var player1TimeRemaining: Int = 60
    @Published var player2TimeRemaining: Int = 60
    var timer: Timer?
        //.publish(every: 1, on: .main, in: .common).autoconnect()
    @objc func onTimer1Fires()
    {
        player1TimeRemaining -= 1
        if player1TimeRemaining <= 0 {
            timer?.invalidate()
            self.timer = nil
        }
    }
    @objc func onTimer2Fires()
    {
        player2TimeRemaining -= 1
        if player2TimeRemaining <= 0 {
            timer?.invalidate()
            self.timer = nil
        }
    }
    func startTimer1() {
        timer?.invalidate()
        player1TimeRemaining = 60
        isPlayer1TimerAble = true
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(onTimer1Fires), userInfo: nil, repeats: true)
    }
    func startTimer2() {
        timer?.invalidate()
        player2TimeRemaining = 60
        isPlayer2TimerAble = true
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(onTimer2Fires), userInfo: nil, repeats: true)
    }
    
    init() {
        
        //UserDefaults.standard.removeObject(forKey: defaultKey)
        user = User(json: UserDefaults.standard.data(forKey: defaultKey)) ?? nil
        
        socketHelper.setupNetworkCommunication()
        if user != nil {
            socketHelper.establishConnection(username: user!.username, token: user!.token)
            self.loginStatus = true
        }
        
    }
    
    // MARK: - Intent(s)
    func logout() {
        UserDefaults.standard.removeObject(forKey: defaultKey)
        self.user = nil
        self.loginStatus = false
        socketHelper.stopChatSession()
    }

    func setPiece(row: Int, col: Int, state: GoBangModel.Piece.pieceState, order: Int, confirmed: Bool) {
        goBangModel.setPiece(row: row, col: col, state: state, order: order, confirmed: confirmed)
    }
    
    func hasPiece(row: Int, col: Int) -> Bool {
        return goBangModel.hasPiece(row: row, col: col)
    }
    
    func isConfirmed(row: Int, col: Int) -> Bool {
        return goBangModel.isConfirmed(row: row, col: col)
    }
    
    func login(username: String, password: String, onSuccess:  @escaping () -> Void, onError:  @escaping (String) -> Void) {
        socketHelper.setupNetworkCommunication()
        // Prepare URL
        let url = URL(string: Configuration.shared.address + "user/login")
        guard let requestUrl = url else { fatalError() }

        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
         
        // HTTP Request Parameters which will be sent in HTTP Request Body
        let postString = "username=" + username + "&password=" + password;

        // Set HTTP Request Body
        request.httpBody = postString.data(using: String.Encoding.utf8);
        
        // Perform HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async { [self] in
                // Check for Error
                if let error = error {
                    print("Error took place \(error)")
                    onError("request error")
                    return
                }
         
                // Convert HTTP Response Data to a String
                if let data = data {
                    //print("Response data string:\n \(dataString)")
                    
                    do {
                        // make sure this JSON is in the format we expect
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            if let statusCode = json["statusCode"] as? Int{
                                if statusCode == 200 {
                                    let jsonData: NSDictionary = json["data"] as! NSDictionary
                                    self.user = User(username: username, password: password, token: jsonData["token"] as! String)
                                    self.loginStatus = true
                                    
                                    print("login success")
                                    autosaveCancellable = $user.sink { user in
                                        //print("\(emojiArt.json?.utf8 ?? "nil")")
                                        if user != nil {
                                            UserDefaults.standard.set(user!.json, forKey: defaultKey)
                                        }
                                    }
                                    
                                    onSuccess()
                                    socketHelper.establishConnection(username: user!.username, token: user!.token)
                                } else {
                                    onError("????????????")
                                }
                            }
                        }
                    } catch let error as NSError {
                        print("Failed to load: \(error.localizedDescription)")
                        onError("json error")
                    }
                    
                }
            }
                
        }
//        URLSession.shared.dataTaskPublisher(for: request)
//            .map { data, uRLResponse in UIImage(data: data)}
//            .receive(on: DispatchQueue.main)
//            .replaceError(with: nil)
//            .assign(to: \.backgroundImage, on: self)
//
        task.resume()
    }
    
    func isLogin() -> Bool {
        self.user != nil
    }
    
//    func setRoomNumber(roomNumber: String) {
//        self.roomNumber = roomNumber
//    }
    
    //??????????????????
    func addMessageHandler(onResponse: @escaping (Message)->()){
        self.socketHelper.addMessageHandler(onResponse: onResponse)
    }
    // ??????????????????
    func removeMessageHandler(){
        self.socketHelper.removeMessageHandler()
    }
    // ????????????
    func createRoom(message: Message){
        //self.setRoomNumber(roomNumber: message.data)
        self.room.player1?.username = message.from!
        self.room.roomId = Int(message.data!)!
        print("?????????????????????????????????\(self.room.roomId)")
    }
    // ??????????????????
    func onOpponentJoinRoom(message: Message){
        //self.setRoomNumber(roomNumber: message.data)
        //self.room.player1?.username = message.from
        let roomInfo: Room? = Room(json: message.data!.data(using: String.Encoding.utf8))
        
        if let roomInfo = roomInfo {
            // - MARK: ???????????????????????????????????????????????????????????????????????????????????????View?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
            //self.room = roomInfo ??????
            self.room = roomInfo

            print("room: \(room)")
            
        }
        
    }
    // ????????????
    func joinRoom(message: Message) {
        let roomInfo: Room? = Room(json: message.data!.data(using: String.Encoding.utf8))
        print("room: \(room)")
        if let roomInfo = roomInfo {
            //self.room = roomInfo ??????
            self.room.roomId = roomInfo.roomId
            self.room.player1 = roomInfo.player1
            self.room.player2 = roomInfo.player2
        }
    }
    // ????????????
    func exitRoom(roomId: Int, onResponse:@escaping (Message)->()) {
        self.socketHelper.exitRoom(roomId: roomId, isPlayer: true, onResponse: onResponse)
    }
    // ??????
    func ready(roomId: Int, onResponse:@escaping (Message)->()){
        socketHelper.ready(roomId: roomId, onResponse: onResponse)
    }
    // ????????????
    func cancelReady(roomId: Int, onResponse:@escaping (Message)->()){
        socketHelper.cancelReady(roomId: roomId, onResponse: onResponse)
    }
    // ????????????
    func onOpponentReady(message: Message){
        //from ???????????????
        if room.player1!.username != message.to {
            room.player1!.status = 1
        } else {
            room.player2!.status = 1
        }
    }
    // ??????????????????
    func onOpponentCancelReady(message: Message){
        //from ?????????????????????
        if room.player1!.username != message.to {
            room.player1!.status = 0
        } else {
            room.player2!.status = 0
        }
    }
    // ????????????????????????
    func setSelfReady(ready: Bool) {
        if user!.username == room.player1!.username {
            room.player1!.status = ready ? 1 : 0
        } else {
            room.player2!.status = ready ? 1 : 0
        }
    }
    // ??????
    func putPiece(row: Int, col: Int, state: GoBangModel.Piece.pieceState, order: Int, onResponse:@escaping (Message)->()) {
        self.setPiece(row: row, col: col, state: state, order: order, confirmed: true)
        let position: Position = Position(row: row, col: col, state: state)
        socketHelper.moveChess(position: position, roomId: room.roomId, onResponse: onResponse)
    }
    // ??????????????????
    func onMovePiece(message: Message, order: Int, isWin: @escaping (Bool)->()) {
        let position: Position = Position(json: message.data?.data(using: String.Encoding.utf8))!
        self.setPiece(row: position.y, col: position.x, state: position.chessColor == 0 ? .black : .white, order: order, confirmed: true)
        isWin(self.isWin(row: position.y, col: position.x, state: position.chessColor == 0 ? .black : .white))
    }
    func clearRoomInfo() {
        self.room = Room()
        self.goBangModel = GoBangModel(rows: 15, columns: 15)
    }
    // ??????????????????
    func isWin(row: Int, col: Int, state: GoBangModel.Piece.pieceState) -> Bool {
        return goBangModel.isWin(x: col, y: row, chessColor: state)
    }
    // ??????????????????
    func setRoomInfo(message: Message) {
        self.room = Room(json: message.data?.data(using: String.Encoding.utf8))!
    }
    // ????????????
    func cancelMatch() {
        self.socketHelper.cancelMatch()
    }
    var pieces: Array<GoBangModel.Piece> {
        goBangModel.pieces
    }

    // ??????
    func chat(roomId: Int, msg: String, filename: String, onResponse: @escaping (Message)->()){
        socketHelper.chat(roomId: roomId, msg: msg, filename: filename, onResponse: onResponse)
    }
    // ??????
    func giveUp(onResponse: @escaping (Message)->()) {
        self.socketHelper.giveUp(roomIdVal: self.room.roomId, onResponse: onResponse)
    }
    
    @Published var isImageAble = false
    @Published var winState = false
    
    func setImage() {
        isImageAble = true
    }
    func setWinState() {
        winState = true
    }
    
    

}
