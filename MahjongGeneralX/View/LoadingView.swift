//
//  LoadingView.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/11/24.
//

import Foundation
import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.9))
        .edgesIgnoringSafeArea(.all)
    }
}
