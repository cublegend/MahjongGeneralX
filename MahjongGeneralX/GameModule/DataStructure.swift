//
//  DataStructure.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/10/24.
//

import Foundation

struct PlayerDecision {
    let label: PlayerCommand
    let decision: () -> Void

    init(_ label: PlayerCommand, decision: @escaping () -> Void) {
        self.label = label
        self.decision = decision
    }
}

/// This enum encapsulates common actions a player needs to do when making a decision
enum PlayerCommand: String {
    case draw
    case discard
    case hu
    case zimo
    case kang
    case selfKang
    case pong
    case pass

    var name: String { rawValue }
}

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
            return [.initialDraw, .gameWaitToStart].contains(phase)
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

/// This enum labels player state changes for outer logic to observe.
/// However, the state changes shoud NOT directly activate any PlayerController actions,
/// it merely labels the state change and should be mutated ONLY inside PlayerController.
public enum PlayerState: String, Codable, Sendable, Equatable {
    case playerWaitToStart
    case initDraw
    case decideSwitchTiles
    case decideDiscardSuit
    case roundDraw
    case roundDiscard
    case roundDecision
    case idle
    case end

    /// Returns `True` if it's possible to transition to the specified phase from the currrent one.
    func canProgress(to phase: PlayerState) -> Bool {
        switch self {
        case .playerWaitToStart:
            return [.initDraw, .playerWaitToStart].contains(phase)
        case .initDraw:
            return [.decideSwitchTiles, .playerWaitToStart].contains(phase)
        case .decideSwitchTiles:
            return [.idle, .decideDiscardSuit, .playerWaitToStart].contains(phase)
        case .decideDiscardSuit:
            return [.idle, .roundDraw, .roundDecision, .playerWaitToStart].contains(phase)
        case .roundDraw:
            return [.idle, .roundDiscard, .roundDraw, .end, .playerWaitToStart].contains(phase)
        case .roundDiscard:
            return [.idle, .roundDecision, .playerWaitToStart].contains(phase)
        case .roundDecision:
            return [.idle, .roundDraw, .roundDiscard, .end, .playerWaitToStart].contains(phase)
        case .end:
            return [.end, .playerWaitToStart].contains(phase)
        case .idle:
            return true
        }
    }

    /// Requests a phase transition.
    @discardableResult
    mutating public func transition(to newPhase: PlayerState) -> Bool {
        guard canProgress(to: newPhase) else {
            print("Requested transition to \(newPhase.rawValue), but that's not a valid transition.")
            return false
        }
        self = newPhase
        return true
    }
}
