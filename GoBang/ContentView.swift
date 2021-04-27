//
//  ContentView.swift
//  GoBang
//
//  Created by Rambo on 2021/4/7.
//

import SwiftUI

struct ContentView: View {
    @State var showLoginView: Bool = true
    @ObservedObject var viewModel: GoBangViewModel
    
    var body: some View {
//        GeometryReader { geometry in
//            VStack(alignment: .center) {
//                Spacer().frame(height: 100)
//                Divider()
//                BoardView()
//                    .environmentObject(self.viewModel)
//                Divider()
//                Spacer().frame(height: 200)
//                Button("New Game") {}
//            }
//            .padding()
//            .frame(minWidth: 0, maxWidth: .infinity, minHeight:0, alignment: Alignment.center)
//        }

        if !viewModel.isLogin() {
            LoginView(showLoginView: $showLoginView).environmentObject(self.viewModel)
        } else {
            GameLobbyView().environmentObject(self.viewModel)
//                    GeometryReader { geometry in
//                        VStack(alignment: .center) {
//                            Spacer().frame(height: 100)
//                            Divider()
//                            BoardView()
//                                .environmentObject(self.viewModel)
//                            Divider()
//                            Spacer().frame(height: 200)
//                            Button("New Game") {}
//                        }
//                        .padding()
//                        .frame(minWidth: 0, maxWidth: .infinity, minHeight:0, alignment: Alignment.center)
//                    }
        }
    }
    
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
