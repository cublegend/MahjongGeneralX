//
//  ContentView.swift
//  MahjongDemo2
//
//  Created by Katherine Xiong on 4/6/24.
// r

import SwiftUI
import RealityKit
import RealityKitContent

struct Welcome: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @Environment(\.dismissWindow) private var dismissWindow

    @State var isPresentingMainMenu = false

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            if !isPresentingMainMenu {
                HStack {
                    Spacer()
                    VStack {
                        Spacer(minLength: 250)
                        VStack {
                            Text("Welcome")
                                .monospaced()
                                .font(.system(size: 50, weight: .bold))
                            Text("Discover a new way of playing Mahjong.")
                                .font(.title)
                                .padding(.vertical, 6)
                        }
                        Spacer()
                        Group {
                            VStack {
                                InfoLabel(appState: appState)
                                    .padding(.horizontal, 30)
                                    .frame(width: 400)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button("Enter") {
                                    appState.appPhase = .mainMenu
                                    isPresentingMainMenu.toggle()
                                }
                                .padding(.vertical, 10)
                            }
                        }
                        Spacer(minLength: 170)
                    }
                    Spacer()
                }
            } else {
                MainMenu()
            }
        }
        .glassBackgroundEffect()
        .onChange(of: appState.providersStoppedWithError, { _, providersStoppedWithError in
            // Immediately close the immersive space if there was an error.
            if providersStoppedWithError {
                if appState.immersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.cleanUpAfterLeavingImmersiveSpace()
                    }
                }

                appState.providersStoppedWithError = false
            }
        })
        .task {
            // Request authorization before the user attempts to open the immersive space;
            // this gives the app the opportunity to respond gracefully if authorization isn’t granted.
            if appState.allRequiredProvidersAreSupported {
                await appState.requestWorldSensingAuthorization()
            }
        }
        .task {
            // Monitors changes in authorization. For example, the user may revoke authorization in Settings.
            await appState.monitorSessionEvents()
        }
    }
}

#Preview {
    Welcome(isPresentingMainMenu: false)
        .environment(AppState())
}
