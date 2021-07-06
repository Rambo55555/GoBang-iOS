//
//  SocketHelper.swift
//  GoBang
//
//  Created by Rambo on 2021/4/16.
//


import Foundation

protocol ChatRoomDelegate: class {
  func received(message: Message)
}



class SocketHelper: NSObject {
    
    static let shared = SocketHelper()

    //1
    var inputStream: InputStream!
    var outputStream: OutputStream!

    weak var delegate: ChatRoomDelegate?
  
    //2
    private var username  = ""
    private var token  = ""

    private var messageListeners  = [Int : (message:Message)->()]()
    private var messageHandler: ((_ message: Message)->())? = nil
    private var messageQueue = [Message]()
    private var messageList  = [Int : Message]()
    
    //3
    let maxReadLength = 4096
    let messageReadLength = 4
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
    // 重连
    func reconnect(onResponse:@escaping (Message)->()){
        messageQueue = []
        //startListening()
        var message = Message()
        message.setFrom(from: username)
        message.setType(type: MessageType.RECONNECT)
        
        sendMessage(message: &message, onResponse: onResponse)
        for mutableEntry in messageList {
            resendMessage(message: mutableEntry.value)
            //break
        }
    }
    // 得到房间列表
    func getRoomList(onResponse:@escaping (Message)->()){
        var message = Message(from: username)
        message.setType(type: MessageType.GET_ROOM_LIST)
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 创建房间
    func createRoom(onResponse:@escaping (Message)->()) {
        var message = Message(from: username)
        message.setType(type: MessageType.CREATE_ROOM)
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 准备
    func ready(roomId:Int, onResponse:@escaping (Message)->()){
        var message = Message(from: username)
        message.setType(type: MessageType.READY)
        message.data = String(roomId)
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 加入房间
    func joinRoom(roomId: Int, isPlayer: Bool, onResponse: @escaping (Message)->()){
        var message = Message(from: username)
        if isPlayer {
            message.setType(type: MessageType.ENTER_ROOM_AS_PLAYER)
        } else {
            message.setType(type: MessageType.ENTER_ROOM_AS_WATCHER)
        }
        message.data = String(roomId)
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 移动棋子
    func moveChess(position: Position, roomId: Int, onResponse:@escaping (Message)->()){
        var message = Message(from: username)
        message.setType(type: MessageType.MOVE)
        // map to json
        //message.data = gson.toJson(mapOf("roomId" to roomId, "position" to gson.toJson(position)))
        let dictionary: NSMutableDictionary = NSMutableDictionary()
        dictionary["roomId"] = roomId
        dictionary["position"] = position.jsonStr
        let str = getJSONStringFromDictionary(dictionary: dictionary)
        message.data = str
        print("移动棋子: \(str)")
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 聊天
    func chat(roomId: Int, msg: String, filename: String, onResponse: @escaping (Message)->()){
        var message = Message(from: username)
        message.setType(type: MessageType.CHAT)
        let dictionary: NSMutableDictionary = NSMutableDictionary()
        dictionary["roomId"] = roomId
        dictionary["message"] = msg
        dictionary["filename"] = filename
        let str = getJSONStringFromDictionary(dictionary: dictionary)
        message.data = str
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 投降
    func giveUp(roomIdVal: Int,  onResponse: @escaping (Message)->()) {
        var message = Message(from: username)
        message.setType(type: MessageType.GIVE_UP)
        message.data = String(roomIdVal)
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 退出房间
    func exitRoom(roomId: Int, isPlayer: Bool, onResponse: @escaping (Message)->()){
        var message = Message(from: username)
        message.setType(type: MessageType.EXIT_ROOM)
        let dictionary: NSMutableDictionary = NSMutableDictionary()
        dictionary["roomId"] = roomId
        dictionary["isPlayer"] = isPlayer
        let str = getJSONStringFromDictionary(dictionary: dictionary)
        message.data = str
        sendMessage(message: &message, onResponse: onResponse)
    }
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
    // 重发消息
    private func resendMessage(message: Message) {
        messageQueue.append(message)
    }
    // 取消准备
    func cancelReady(roomId: Int,  onResponse:@escaping (Message)->()) {
        var message = Message(from: username)
        message.setType(type: MessageType.CANCEL_READY)
        message.data = String(roomId)
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 匹配房间
    func matchRoom(onResponse:@escaping (Message)->()) {
        var message = Message(from: username)
        message.setType(type: MessageType.MATCH_ROOM)
        sendMessage(message: &message, onResponse: onResponse)
    }
    // 取消匹配
    func cancelMatch() {
//        var iterator = messageQueue.iterator()
//        while (iterator.hasNext()){
//            var message = iterator.next()
//            if (message.type == Message.MATCH_ROOM){
//                iterator.remove()
//            }
//        }
        for (index, messageHandler) in messageQueue.enumerated() {
            if messageHandler.type == MessageType.MATCH_ROOM {
                messageQueue.remove(at: index)
            }
        }
        var message = Message(from: username)
        message.type = MessageType.CANCEL_MATCH;
        sendMessage(message: &message, onResponse: { message in })
    }
    
    // 发送消息
    func sendMessage( message: inout Message,  onResponse: @escaping (Message)->()){
        message.setRandomMessageId()
        if (message.type != MessageType.RECONNECT && message.type != MessageType.ESTABLISH) {
            messageList[message.messageId] = message
        }
        messageQueue.append(message)
        messageListeners[message.messageId] = onResponse
        send(message: message)
    }
    //添加消息处理
    func addMessageHandler(onResponse: @escaping (Message)->()){
        messageHandler = onResponse
    }
    // 移除消息处理
    func removeMessageHandler(){
        messageHandler = nil
    }
    
    
    func send(message: Message) {
        //let data = "msg:\(message)".data(using: .utf8)!
        //let data = message.json!
//        var str :String = gson.toJson(message)
//        Log.d(TAG, "sendMessage: $str")
//        var strBytes = str.toByteArray()
//        var sizeBytes = ByteBuffer.allocate(4).putInt(strBytes.size).array()
//        out?.write(sizeBytes)
//        out?.write(strBytes)
        //let messageJson = message.json!
        //print("message: \(messageJson) type: \(type(of: messageJson))")
        
        
        
        // 小端模式转大端
        var jsonSize: Int32 = Int32(message.json!.count).bigEndian
        print("jsonSize: \(jsonSize) type: \(type(of: jsonSize))")
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
//        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
//                                           "localhost" as CFString,
//                                           55556,
//                                           &readStream,
//                                           &writeStream)
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           Configuration.shared.IP as CFString,
                                           Configuration.shared.port,
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

    func stopChatSession() {
        inputStream.close()
        outputStream.close()
    }

}

extension SocketHelper: StreamDelegate {
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
//            let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
//
//            if numberOfBytesRead < 0, let error = stream.streamError {
//                print(error)
//                break
//            }
//
//            // Construct the message object
//            if let message = processedMessageString(buffer: buffer, length: numberOfBytesRead) {
//                // Notify interested parties
//                delegate?.received(message: message)
//            }
            
            // 1. get the message length
            let lengthBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: messageReadLength)
            inputStream.read(lengthBuffer, maxLength: messageReadLength)
            let messageLength = Data(buffer: UnsafeMutableBufferPointer(start: lengthBuffer, count: messageReadLength)).lyz_4BytesToInt()
            //print("messageLength: \(messageLength)")
            // 2. Construct the message object
            let numberOfBytesRead = inputStream.read(buffer, maxLength: messageLength)

            if numberOfBytesRead < 0, let error = stream.streamError {
                print(error)
                break
            }
            
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
        // 把消息按照4个字节分开
        print("data : \(data)")
        //let removeData = data.advanced(by: 4)
//        print("buffer: \(data) type: \(type(of: data))")
//        print("removeData: \(removeData) type: \(type(of: removeData))")
        //print("removeData: \(String(data: removeData, encoding: String.Encoding.utf8))")
        let message = Message(json: data)
        //print("Data: \(String(data: data, encoding: String.Encoding.utf8))")
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
        print("接收 message: \(message)")
        if message != nil {
            if message!.type == MessageType.HEART_BEAT {
                print("心跳包")
                return message
            }
            print("接收成功：\(message!.jsonStr ?? "")")
            //2
            //let messageSender: MessageSender = (name == self.username) ? .ourself : .someoneElse
            
            //3 处理消息对应的回调函数并移除该消息回调函数
            if messageListeners.keys.contains(message!.messageId), let message = message, let messageResponse = messageListeners[message.messageId]{
                
                print("消息回调处理开始  ")
                messageResponse(message)
                messageListeners.removeValue(forKey: message.messageId)
                print("消息回调处理完成  ")
            } else {
                if let message = message, let messageHandler = messageHandler {
                    print("自动消息回调处理开始  ")
                    messageHandler(message)
                    print("自动消息回调处理结束  ")
                }
                
            }
        }
        
//        for messageResponse in messageListeners {
//            if messageResponse.key == message!.messageId {
//                print("消息回调处理开始  ")
//                messageResponse.value(message!)
//                messageListeners.removeValue(forKey: messageResponse.key)
//                print("消息回调处理完成  ")
//                break
//            }
//        }
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
