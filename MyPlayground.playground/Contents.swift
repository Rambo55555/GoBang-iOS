import UIKit
import SocketIO
import GoBang

let token = "73935335-3f28-45dd-bac6-64ce170fbad1"


import UIKit
struct Message: Codable {
    
    var to = ""
    var from = ""
    var data = ""
    var token = ""
    var type = 0
    var messageId = 0
    
    init() {
        
    }
    
    init?(json: Data?) {
        if json != nil, let newMesage = try? JSONDecoder().decode(Message.self, from: json!) {
            self = newMesage
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
    
    mutating func setRandomMessageId() {
        self.messageId = Int(arc4random())
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
}

protocol ChatRoomDelegate: class {
  func received(message: Message)
}



class ChatRoom: NSObject {
    //1
    var inputStream: InputStream!
    var outputStream: OutputStream!

    weak var delegate: ChatRoomDelegate?
  
    //2
    private var username  = ""
    private var token  = ""

    private var messageListeners  = [Int : (message:Message)->()]()

    private var messageQueue = [Message]()
    private var messageList  = [Int : Message]()
  
    //3
    let maxReadLength = 4096
    // - MARK: connect
    // 建立连接
    func establishConnection(username: String, token: String) {
        self.username = username
        self.token = token
        var message = Message()
        message.token = token
        message.from = username
        message.type = MessageType.ESTABLISH
        send(message: message)
    }
    // 发送消息
    func sendMessage( message: inout Message){
        message.setRandomMessageId()
        if (message.type != MessageType.RECONNECT && message.type != MessageType.ESTABLISH) {
            messageList[message.messageId] = message
        }
        messageQueue.append(message)
    }
    
    func send(message: Message) {
        //let data = "msg:\(message)".data(using: .utf8)!
        //let data = message.json!
//        val str :String = gson.toJson(message)
//        Log.d(TAG, "sendMessage: $str")
//        val strBytes = str.toByteArray()
//        val sizeBytes = ByteBuffer.allocate(4).putInt(strBytes.size).array()
//        out?.write(sizeBytes)
//        out?.write(strBytes)
        //let messageJson = message.json!
        //print("message: \(messageJson) type: \(type(of: messageJson))")
        var jsonSize = message.json!.count
        //print("jsonSize: \(jsonSize) type: \(type(of: jsonSize))")
        let sizeBytes = Data(bytes: &jsonSize, count: 4)
        //print("sizeBytes: \(sizeBytes) type: \(type(of: sizeBytes))")
        let data = sizeBytes + message.json!
        //print("data: \(data) type: \(type(of: data))")
        
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                print("Error joining chat")
                return
            }
            outputStream.write(pointer, maxLength: data.count)
            let str = String(decoding: data, as: UTF8.self)
            print("发送成功 \(str)")
        }
    }
    
    func setupNetworkCommunication() {
        // 1
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        // 2
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           "localhost" as CFString,
                                           55556,
                                           &readStream,
                                           &writeStream)

        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        inputStream.delegate = self

        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)

        inputStream.open()
        outputStream.open()
    }
  
    func joinChat(username: String) {
        //1
        let data = "iam:\(username)".data(using: .utf8)!

        //2
        self.username = username

        //3
        data.withUnsafeBytes {
          guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
            print("Error joining chat")
            return
          }
          //4
          outputStream.write(pointer, maxLength: data.count)
        }
    }

    func send(message: String) {
        let data = "msg:\(message)".data(using: .utf8)!

        data.withUnsafeBytes {
              guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                print("Error joining chat")
                return
              }
              outputStream.write(pointer, maxLength: data.count)
            }
    }

    func stopChatSession() {
        inputStream.close()
        outputStream.close()
    }

}

extension ChatRoom: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
            case .hasBytesAvailable:
              print("new message received")
              readAvailableBytes(stream: aStream as! InputStream)
            case .endEncountered:
              print("new message received")
              stopChatSession()
            case .errorOccurred:
              print("error occurred")
            case .hasSpaceAvailable:
              print("has space available")
            default:
              print("some other event...")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        while stream.hasBytesAvailable {
          let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
          
          if numberOfBytesRead < 0, let error = stream.streamError {
            print(error)
            break
          }
          
          // Construct the message object
          if let message = processedMessageString(buffer: buffer, length: numberOfBytesRead) {
            // Notify interested parties
            delegate?.received(message: message)
          }
        }
    }

    private func processedMessageString(buffer: UnsafeMutablePointer<UInt8>, length: Int) -> Message? {
        let bufferPoint = UnsafeMutableBufferPointer(start: buffer, count: length)
        let data = Data(buffer: bufferPoint)
        //data[0..<4].lyz_4BytesToInt()
        let removeData = data.advanced(by: 4)
//        print("buffer: \(data) type: \(type(of: data))")
//        print("removeData: \(removeData) type: \(type(of: removeData))")
        let message = Message(json: removeData)
        //1
//        guard
//          let stringArray = String(
//            bytesNoCopy: buffer,
//            length: length,
//            encoding: .utf8,
//            freeWhenDone: true)?.components(separatedBy: ":")
////          let name = stringArray.first,
////          let message = stringArray.last
//          else {
//            return nil
//        }
        print("接收成功：\(message!.jsonStr ?? "")")
        //2
        //let messageSender: MessageSender = (name == self.username) ? .ourself : .someoneElse
        //3
        var newMessage = Message()
        newMessage.setFrom(from: "Rambo")
        newMessage.setTo(to: "张三")
        newMessage.setData(data: "hhh")
        newMessage.setToken(token: token)
        newMessage.setType(type: MessageType.CREATE_ROOM)
        //chatRoom.send(message: newMessage)
        return message
    }
}

extension Int {
    // MARK:- 转成 2位byte
    func hw_to2Bytes() -> [UInt8] {
        let UInt = UInt16.init(Double.init(self))
        return [UInt8(truncatingIfNeeded: UInt >> 8),UInt8(truncatingIfNeeded: UInt)]
    }
    // MARK:- 转成 4字节的bytes
    func hw_to4Bytes() -> [UInt8] {
        let UInt = UInt32.init(Double.init(self))
        return [UInt8(truncatingIfNeeded: UInt >> 24),
                UInt8(truncatingIfNeeded: UInt >> 16),
                UInt8(truncatingIfNeeded: UInt >> 8),
                UInt8(truncatingIfNeeded: UInt)]
    }
    // MARK:- 转成 8位 bytes
    func intToEightBytes() -> [UInt8] {
        let UInt = UInt64.init(Double.init(self))
        return [UInt8(truncatingIfNeeded: UInt >> 56),
            UInt8(truncatingIfNeeded: UInt >> 48),
            UInt8(truncatingIfNeeded: UInt >> 40),
            UInt8(truncatingIfNeeded: UInt >> 32),
            UInt8(truncatingIfNeeded: UInt >> 24),
            UInt8(truncatingIfNeeded: UInt >> 16),
            UInt8(truncatingIfNeeded: UInt >> 8),
            UInt8(truncatingIfNeeded: UInt)]
    }
}
extension Data {
    //1bytes转Int
    func lyz_1BytesToInt() -> Int {
        var value : UInt8 = 0
        let data = NSData(bytes: [UInt8](self), length: self.count)
        data.getBytes(&value, length: self.count)
        value = UInt8(bigEndian: value)
        return Int(value)
    }
    
    //2bytes转Int
    func lyz_2BytesToInt() -> Int {
        var value : UInt16 = 0
        let data = NSData(bytes: [UInt8](self), length: self.count)
        data.getBytes(&value, length: self.count)
        value = UInt16(bigEndian: value)
        return Int(value)
    }
    
    //4bytes转Int
    func lyz_4BytesToInt() -> Int {
        var value : UInt32 = 0
        let data = NSData(bytes: [UInt8](self), length: self.count)
        data.getBytes(&value, length: self.count)
        value = UInt32(bigEndian: value)
        return Int(value)
    }
    
}

//let chatRoom = ChatRoom()
//var message = Message()
//
//chatRoom.setupNetworkCommunication()
//chatRoom.establishConnection(username: "Rambo", token: token)
struct Position: Codable {
    var x: Int = 0
    var y: Int = 0
    var chessColor: Int = 0 // black 0
    
    init() {
        
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


var position = Position()


//do {
//    let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: [])
//
//    let jsonString = String(data: jsonData!, encoding: String.Encoding.utf8)!
//
//    print("jsonString: \(jsonString)")
//} catch {
//    print(error.localizedDescription)
//}


/// 字典转json字符串
func getJSONStringFromDictionary(dictionary: NSMutableDictionary) -> String {
    if !JSONSerialization.isValidJSONObject(dictionary) {
        return "\"{}\""
    }
    do {
        let data: Data = try JSONSerialization.data(withJSONObject: dictionary, options: []) as Data
        let jsonString = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) ?? ""
        return jsonString as String
    } catch {
        return "\"{}\""
    }
}
var dictionary: NSMutableDictionary = NSMutableDictionary()
dictionary["roomId"] = 3
dictionary["position"] = ["x": position.x, "y": position.y, "chessColor": position.chessColor]
let str = getJSONStringFromDictionary(dictionary: dictionary)
print("str: \(str)")





