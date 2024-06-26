//
//  MainMenu.swift
//  MahjongDemo2
//
//  Created by Katherine Xiong on 4/6/24.
//

import SwiftUI
import MahjongCore

struct MainMenu: View {

    @Environment(AppState.self) private var appState
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismiss

    @State var isShowingSettings = false
    @State var isEnterClicked = false
    
    var body: some View {
        VStack {
            VStack {
                Spacer(minLength: 90)
                VStack {
                    if !appState.immersiveSpaceOpened {
                        Text("Ready to start a new game?")
                            .font(.title)
                        
                        if !isEnterClicked {
                            Button("Enter") {
                                isEnterClicked = true
                            }.disabled(!appState.canEnterImmersiveSpace || isShowingSettings)
                        } else {
                            LoadingView()
                        }
                        
                        HStack {
                            Spacer()
                            Button {
                                isShowingSettings.toggle()
                            } label: {
                                Label("Settings", systemImage: "gear")
                                    .labelStyle(.iconOnly)
                            }
                            Spacer(minLength: 330)
                        }.padding()
                    }
                }
            }
            .frame(width: 400, height: 250)

            // Display the settings view conditionally
            if isShowingSettings {
                Settings()
                    .padding(20)
                    .frame(width: 400)
            }
        }
        .opacity(appState.immersiveSpaceOpened ? 0 : 1)
        .onChange(of: isEnterClicked) {
            if isEnterClicked {
                Task {
                    await ModelLoader.loadObjects()
                    switch await openImmersiveSpace(id: UIIdentifier.gameModule) {
                    case .opened:
                        break
                    case .error:
                        print("An error occurred when trying to open the immersive space \(UIIdentifier.gameModule)")
                    case .userCancelled:
                        print("The user declined opening immersive space \(UIIdentifier.gameModule)")
                    @unknown default:
                        break
                    }
                    appState.appPhase.transition(to: .game)
                }
            }
        }
    }

}

 #Preview {
    MainMenu(isShowingSettings: true)
        .environment(AppState())
 }
