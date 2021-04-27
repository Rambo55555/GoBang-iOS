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
    private var autosaveCancellable: AnyCancellable?
    var socketHelper: SocketHelper = SocketHelper()
    var roomNumber: String = ""
    
    init() {
        let defaultKey = "userInfo"
        //UserDefaults.standard.removeObject(forKey: defaultKey)
        user = User(json: UserDefaults.standard.data(forKey: defaultKey)) ?? nil
        
        socketHelper.setupNetworkCommunication()
        if user != nil {
            socketHelper.establishConnection(username: user!.username, token: user!.token)
            autosaveCancellable = $user.sink { user in
                //print("\(emojiArt.json?.utf8 ?? "nil")")
                UserDefaults.standard.set(user!.json, forKey: defaultKey)
            }
        }
        
    }
    
    // MARK: - Intent(s)

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

        // Prepare URL
        let url = URL(string: "http://localhost:8080/user/login")
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
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    //print("Response data string:\n \(dataString)")
                    
                    do {
                        // make sure this JSON is in the format we expect
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            if let statusCode = json["statusCode"] as? Int{
                                if statusCode == 200 {
                                    var jsonData: NSDictionary = json["data"] as! NSDictionary
                                    self.user = User(username: username, password: password, token: jsonData["token"] as! String)
                                    onSuccess()
                                    print("login success")
                                    socketHelper.establishConnection(username: user!.username, token: user!.token)
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
    
    func setRoomNumber(roomNumber: String) {
        self.roomNumber = roomNumber
    }
    
    var pieces: Array<GoBangModel.Piece> {
        goBangModel.pieces
    }
    

}
