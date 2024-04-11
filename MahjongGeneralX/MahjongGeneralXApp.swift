//
//  MahjongGeneralXApp.swift
//  MahjongGeneralX
//
//  Created by Katherine Xiong on 4/9/24.
//

import SwiftUI

@main
struct MahjongGeneralXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
