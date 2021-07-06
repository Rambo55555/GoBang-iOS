//
//  ContentView.swift
//  GoBang
//
//  Created by Rambo on 2021/4/7.
//

import SwiftUI
class Model: ObservableObject {
    @Published var pushed = false
}
struct ContentView: View {
    @State var showLoginView: Bool = true
    @ObservedObject var viewModel: GoBangViewModel
    @EnvironmentObject var model: Model
    var body: some View {
        ZStack {
            if !viewModel.loginStatus {
                LoginView(showLoginView: $showLoginView).environmentObject(self.viewModel)
            } else {
                GameLobbyView().environmentObject(self.viewModel)
            }
        }
        
//        NavigationView {
//                    VStack {
//                        Button("Push") {
//                            self.model.pushed = true
//                        }
//
//                        NavigationLink(destination: DetailView(), isActive: $model.pushed) { EmptyView() }
//                    }
//                }
    }
    
}
struct DetailView: View {
    @EnvironmentObject var model: Model

    var body: some View {
        Button("Bring me Back") {
            self.model.pushed = false
        }
    }
}
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
