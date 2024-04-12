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

    @State var isShowingSettings = false
    
    var body: some View {
        VStack {
            VStack {
                Spacer(minLength: 90)
                VStack {
                    if !appState.immersiveSpaceOpened {
                        Text("Ready to start a new game?")
                            .font(.title)
                        
                        Button("Enter") {
                            Task {
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
                        }.disabled(!appState.canEnterImmersiveSpace)
                        
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
            .glassBackgroundEffect(in: .rect(cornerRadius: 40))

            // Display the settings view conditionally
            if isShowingSettings {
                Settings()
                    .padding(20)
                    .glassBackgroundEffect(in: .rect(cornerRadius: 40))
                    .frame(width: 400)
            }
        }
        .opacity(appState.immersiveSpaceOpened ? 0 : 1)
    }

}

// #Preview {
//    MainMenu(isShowingSettings: false)
//        .environment(AppState())
// }
