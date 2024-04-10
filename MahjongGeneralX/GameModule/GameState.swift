//
//  GameState.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/10/24.
//

import Foundation

/// Enum that tracks the current phase of the game by implementing a simple state machine.
public enum GameState: String, Codable, Sendable, Equatable {
    case gameWaitToStart        // Wait for the game to start
    case initialDraw         // initial draw phase for players to draw hand
    case switchTiles        // Switch tiles with other player
    case decideDiscard      // Decide which suit to discard
    case round              // Playing rounds
    case gameEnd            // The end of the game
    
    /// Returns `True` if it's possible to transition to the specified phase from the currrent one.
    func canProgress(to phase: GameState) -> Bool {
        switch self {
        case .gameWaitToStart:
            return phase == .initialDraw
        case .initialDraw:
            return [.switchTiles, .gameWaitToStart].contains(phase)
        case .switchTiles:
            return [.decideDiscard, .gameWaitToStart].contains(phase)
        case .decideDiscard:
            return [.round, .gameWaitToStart].contains(phase)
        case .round:
            return [.gameEnd, .gameWaitToStart].contains(phase)
        case .gameEnd:
            return [.gameEnd, .initialDraw, .gameWaitToStart].contains(phase)
        }
    }
    
    /// Requests a phase transition.
    @discardableResult
    mutating public func transition(to newPhase: GameState) -> Bool {
        print("Game state change to \(newPhase.rawValue)")
        guard canProgress(to: newPhase) else {
            print("Requested transition to \(newPhase.rawValue), but that's not a valid transition.")
            return false
        }
        self = newPhase
        return true
    }
}
