//
//  GameInfo.swift
//  PlacingOnTable
//
//  Created by Katherine Xiong on 3/17/24.
//

import Foundation
import RealityKit
import MahjongCore

@Observable
final class GameInfo {
//    static var dealerID = playerIDs[0]
//
//    static var winnersID: [String] = []
//    static var discardPile: [String: [MahjongEntity]] = [:]
//    static var lastTileDiscarded: MahjongEntity?
//
//    static var playerIDs: [String] = ["Xiong1", "Xiong2", "Xiong3", "Xiong4"]
//
//    static let TOTAL_TILES: Int = 108
//
//    // Table Location
//    static var TABLE_LOCATION: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0)
//    static var TABLE_ORIENTATION: simd_quatf = simd_quatf()
//
//    static func setTablePosition(pos: SIMD3<Float>, ori: simd_quatf) {
//        self.TABLE_LOCATION = pos
//        self.TABLE_ORIENTATION = ori
//    }

//    // Player Location
//    static func getPlayerPosition() -> [SIMD3<Float>]{
//        let playerPositions = [
//            SIMD3<Float>(0, 0, 0 + TABLE_LENGTH / 2), // Player 1 facing user
//            SIMD3<Float>(0 + TABLE_WIDTH / 2, 0, 0),  // Player 2 user right
//            SIMD3<Float>(0, 0, 0 - TABLE_LENGTH / 2), // Player 3 far away
//            SIMD3<Float>(0 - TABLE_WIDTH / 2, 0, 0),  // Player 4 user left
//             // Player 4 user right
//        ]
//        print("playerPositions: ", playerPositions)
//        return playerPositions
//    }

    // Player Orientation
//    static func getPlayerOrientation(playerID: String) -> simd_quatf {
//        let quaternion: simd_quatf
//        if playerID == self.playerIDs[0] {
//            quaternion = simd_quatf(angle: 0, axis: SIMD3<Float>.rotate_y)
//        } else if playerID == self.playerIDs[1] {
//            quaternion = simd_quatf(angle: 90 * .pi / 180, axis: SIMD3<Float>.rotate_y)
//        } else if playerID == self.playerIDs[2] {
//            quaternion = simd_quatf(angle: 180 * .pi / 180, axis: SIMD3<Float>.rotate_y)
//        } else {
//            quaternion = simd_quatf(angle: -90 * .pi / 180, axis: SIMD3<Float>.rotate_y)
//        }
//        return quaternion
//    }
//
//    // Game Data
//    static var switchOrder: SwitchOrder = SwitchOrder.switchOrderRight
//    static var justKanged = false // for kanghua, kangpao, and qiangkang
//
//    static func reset() {
//        winnersID = []
//        for key in discardPile.keys {
//            discardPile[key]?.removeAll()
//        }
//        lastTileDiscarded = nil
//    }
//}
//
///// Enum that tracks the current phase of the game by implementing a simple state machine.
//public enum GameState: String, Codable, Sendable, Equatable {
//    case gameWaitToStart        // Wait for the game to start
//    case gameResetToStart       // Restart the game
//    case startingUp         // Starting game
//    case switchTiles        // Switch tiles with other player
//    case decideDiscard      // Decide which suit to discard
//    case round              // Playing rounds
//    case gameEnd            // The end of the game
//
//    /// Returns `True` if it's possible to transition to the specified phase from the currrent one.
//    func canProgress(to phase: GameState) -> Bool {
//        switch self {
//        case .gameWaitToStart, .gameResetToStart:
//            return phase == .startingUp
//        case .startingUp:
//            return [.switchTiles, .gameResetToStart].contains(phase)
//        case .switchTiles:
//            return [.decideDiscard, .gameResetToStart].contains(phase)
//        case .decideDiscard:
//            return [.round, .gameResetToStart].contains(phase)
//        case .round:
//            return [.gameEnd, .gameResetToStart].contains(phase)
//        case .gameEnd:
//            return [.gameEnd, .startingUp, .gameResetToStart].contains(phase)
//        }
//    }
//
//    /// Requests a phase transition.
//    @discardableResult
//    mutating public func transition(to newPhase: GameState) -> Bool {
//        guard self != newPhase else {
//            logger.info("Attempting to change player state to \(newPhase.rawValue) but already in that state. Treating as a no-op.")
//            return false
//        }
//        guard canProgress(to: newPhase) else {
//            logger.info("Requested transition to \(newPhase.rawValue), but that's not a valid transition.")
//            return false
//        }
//        logger.info("Player state change to \(newPhase.rawValue)")
//        self = newPhase
//        return true
//    }
}
