//
//  GameLobbyIView.swift
//  GoBang
//
//  Created by Rambo on 2021/4/13.
//

import SwiftUI

struct GameLobbyView: View {
    @EnvironmentObject var viewModel: GoBangViewModel
    @State var addRoomAlertIsPresented: Bool = false
    @State var alertIsPresented: Bool = false
    @State var matchIsPresented: Bool = false
    @State var text: String?
    @State var willMoveToBoardView = false
    @State var errorMessage = ""
    var body: some View {
        
            Text("GameLobby")
            NavigationView {
                VStack {
                    Button("随机匹配") {
                        matchIsPresented = true
                        viewModel.socketHelper.matchRoom { message in
                            if message.data == "ERROR" {
                                errorMessage = "匹配失败"
                                alertIsPresented = true
                            } else {
                                print("匹配成功：\(message)")
                                matchIsPresented = false
                                viewModel.setRoomInfo(message: message)
                                willMoveToBoardView = true
                            }
                        }
                    }
                    .alert(isPresented: $matchIsPresented) {
                        Alert(title: Text("匹配中"), message: Text("请稍等......"), dismissButton: .default(Text("取消")){ viewModel.cancelMatch() })
                    }
                    Button("创建房间") {
                        viewModel.socketHelper.createRoom(onResponse: { message in
                            if message.data == "ERROR" {
                                errorMessage = "创建房间失败"
                                alertIsPresented = true
                            } else {
                                print(message)
                                viewModel.createRoom(message: message)
                                willMoveToBoardView = true
                            }
                        })
                    }
                    Button("加入房间") {
                        addRoomAlertIsPresented = true
                    }
                    .textFieldAlert(isPresented: $addRoomAlertIsPresented) { () -> TextFieldAlert in
                        TextFieldAlert(
                            title: "输入房间号",
                            message: "",
                            text: self.$text,
                            doneAction: {inputText in
                                //viewModel.socketHelper.joinRoom(roomId: Int(inputText), isPlayer: true){ repMessage in print(repMessage) }
                                //self.viewModel.socketHelper.joinRoom(roomId: Int(text), isPlayer: true, onResponse: <#T##(Message) -> ()#>)
                                if let roomId = Int(inputText!) {
                                    viewModel.socketHelper.joinRoom(roomId: roomId, isPlayer: true) { message in
                                        if message.data == "ERROR" {
                                            print("房间号错误")
                                            errorMessage = "房间号错误"
                                            alertIsPresented = true
                                            
                                        } else {
                                            print(message)
                                            //viewModel.setRoomNumber(roomNumber: String(roomId))
                                            viewModel.joinRoom(message: message)
                                            willMoveToBoardView = true
                                        }
                                        
                                    }
                                }
                            
                                
                            })
                    }
                    
                    
                        //BoardView().environmentObject(self.viewModel)
                    NavigationLink(destination: ImageView().environmentObject(ImageViewModel())) {
                        Text("看图")
                    }
                    
                }.navigate(to: BoardView().environmentObject(self.viewModel), when: $willMoveToBoardView, navBarHiden: false)
                
            }
            .alert(isPresented: $alertIsPresented) {
                Alert(title: Text("错误"), message: Text("房间号错误"), dismissButton: .default(Text("Got it!")))
            }
        
        
    }
}

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

extension View {

    /// Navigate to a new view.
    /// - Parameters:
    ///   - view: View to navigate to.
    ///   - binding: Only navigates when this condition is `true`.
    func navigate<NewView: View>(to view: NewView, when binding: Binding<Bool>, navBarHiden: Bool) -> some View {
        NavigationView {
            ZStack {
                self
                    .navigationBarTitle("")
                    .navigationBarHidden(true)

                NavigationLink(
                    destination: view
                        //.navigationBarTitle("返回")
                        .navigationBarHidden(navBarHiden),
                        //.navigationBarBackButtonHidden(true),
                        
                    isActive: binding
                ) {
                    EmptyView()
                }
            }
        }
    }
}

//struct GameLobbyIView_Previews: PreviewProvider {
//    static var previews: some View {
//        GameLobbyView()
//    }
//}
