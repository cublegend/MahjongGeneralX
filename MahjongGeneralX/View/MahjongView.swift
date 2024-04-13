//
//  MahjongView.swift
//  MahjongGeneralX
//
//  Created by Katherine Xiong on 4/12/24.
//

import SwiftUI

struct MahjongView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    var body: some View {
        VStack {
            Spacer()
            Group {
                switch appState.appPhase {
                case .welcome:
                    Welcome()
                case .mainMenu:
                    MainMenu()
                case .game:
                    GameMenu()
                }
            }
            .glassBackgroundEffect(
                in: RoundedRectangle(
                    cornerRadius: 40,
                    style: .continuous
                )
            )
        }
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
    MahjongView()
        .environment(AppState())
}
