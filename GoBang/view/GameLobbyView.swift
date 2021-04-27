//
//  GameLobbyIView.swift
//  GoBang
//
//  Created by Rambo on 2021/4/13.
//

import SwiftUI

struct GameLobbyView: View {
    @EnvironmentObject var viewModel: GoBangViewModel
    @State var alertIsPresented: Bool = false
    @State var text: String?
    @State var willMoveToBoardView = false
    var body: some View {
        
            Text("GameLobby")
            NavigationView {
                VStack {
                    Button("加入房间") {
                        alertIsPresented = true
                    }
                    .textFieldAlert(isPresented: $alertIsPresented) { () -> TextFieldAlert in
                        TextFieldAlert(
                            title: "输入房间号",
                            message: "",
                            text: self.$text,
                            doneAction: {text in
                                
                                willMoveToBoardView = true
                            })
                    }
                        //BoardView().environmentObject(self.viewModel)
                    NavigationLink(destination: BoardView().environmentObject(self.viewModel)) {
                        Text("Random Match")
                    }
                    NavigationLink(destination: Text("Exit View")) {
                        Text("Exit")
                    }
                }.navigate(to: BoardView().environmentObject(self.viewModel), when: $willMoveToBoardView, navBarHiden: true)
                
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
                        .navigationBarTitle("返回")
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
