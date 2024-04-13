//
//  ViewUtils.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/11/24.
//

import Foundation
import SwiftUI
import RealityKit

struct UserUtilsView: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 220)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .glassBackgroundEffect()
            .allowsHitTesting(false) // Prevent the tooltip from blocking spatial tap gestures.
    }
}

#Preview {
    UserUtilsView(text: "put it on a plane")
}
