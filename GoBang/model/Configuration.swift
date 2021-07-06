//
//  Configuration.swift
//  GoBang
//
//  Created by Rambo on 2021/5/9.
//

import Foundation

struct Configuration {
    static let shared = Configuration(context: "lan")
    
    private static let remoteAddress = "http://123.60.49.45:8080/"
    private static let localAddress = "http://localhost:8080/"
    private static let remoteServerIP = "123.60.49.45"
    private static let remoteServerPort: UInt32 = 55555
    private static let localServerIP = "localhost"
    private static let localServerPort: UInt32 = 55556
    
    private static let lanAddress = "http://10.10.100.10:8080/"
    private static let lanServerIP = "10.10.100.10"
    private static let lanServerPort: UInt32 = 55556
    
    
    var address: String
    var IP: String
    var port: UInt32
    
    init(context: String) {
        if context == "local" {
            self.address = Configuration.localAddress
            self.IP = Configuration.localServerIP
            self.port = Configuration.localServerPort
        } else if context == "remote" {
            self.address = Configuration.remoteAddress
            self.IP = Configuration.remoteServerIP
            self.port = Configuration.remoteServerPort
        } else {
            self.address = Configuration.lanAddress
            self.IP = Configuration.lanServerIP
            self.port = Configuration.lanServerPort
        }
    }
}
