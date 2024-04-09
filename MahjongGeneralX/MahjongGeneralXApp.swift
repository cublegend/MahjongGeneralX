//
//  MahjongGeneralXApp.swift
//  MahjongGenerallX
//
//  Created by Katherine Xiong on 4/9/24.
//

import SwiftUI

@main
struct MahjongGenerallXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
