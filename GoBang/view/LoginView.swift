//
//  LoginView.swift
//  GoBang
//
//  Created by Rambo on 2021/4/13.
//

import SwiftUI

import SwiftUI

let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)

struct LoginView : View {
    
    @State var username: String = ""
    @State var password: String = ""
    @Binding var showLoginView: Bool
    @State private var shouldShowLoginAlert: Bool = false
    @EnvironmentObject var viewModel: GoBangViewModel
    //@State var shouldShowLeaderboardView = false
    var body: some View {
        
        VStack {
            WelcomeText()
            UserImage()
            TextField("Username", text: $username)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Password", text: $password)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            Button(action: {
                // - MARK: login
                viewModel.login(username: username, password: password, onSuccess: {
                    self.showLoginView = false
                }, onError: { error in
                    self.shouldShowLoginAlert = true
                })
                
            }) {
               LoginButtonContent()
            }
//            RoundedNavigationLink(
//                label: "Leaderboard",
//                destination: AnyView(GameLobbyView()),
//                isActive: $shouldShowLeaderboardView,
//                disabled: false
//            )
        }
        .padding()
        .alert(isPresented: $shouldShowLoginAlert) {
                Alert(title: Text("User Name/Password incorrect"))
              }
    }
}



struct WelcomeText : View {
    var body: some View {
        return Text("GoBang!")
            .font(.largeTitle)
            .fontWeight(.semibold)
            .padding(.bottom, 20)
    }
}

struct UserImage : View {
    var body: some View {
        return Image("userImage")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 150, height: 150)
            .clipped()
            .cornerRadius(150)
            .padding(.bottom, 75)
    }
}

struct LoginButtonContent : View {
    var body: some View {
        return Text("LOGIN")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.green)
            .cornerRadius(15.0)
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        return LoginView(showLoginView: .constant(false))
    }
}
#endif

