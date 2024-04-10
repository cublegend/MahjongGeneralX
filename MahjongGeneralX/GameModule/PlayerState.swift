//
//  PlayerState.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/9/24.
//

import Foundation

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
