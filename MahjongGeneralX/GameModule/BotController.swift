//
//  BotController.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/10/24.
//

import Foundation
import MahjongCore

class BotController: PlayerController, IPlayerTurnLogic {
    func takeTurn(completion: @escaping () -> Void) {
        switch playerState {
        case .initDraw:
            for _ in 0..<4 {
                guard let tile = mahjongSet.draw() else {
                    fatalError("init draw not possible to be nil!")
                }
                processPlayerDraw(tile)
            }
        case .roundDraw:
            playerState.transition(to: .roundDraw)
            guard let tile = mahjongSet.draw() else {
                fatalError("init draw not possible to be nil!")
            }
            processPlayerDraw(tile)
            checkThenProcessBotDrawDecision()
        default:
            print("\(playerID) has nothing to take turn in \(playerState)!")
            break
        }
        completion()
    }
    
    func checkThenProcessBotDrawDecision() {
        guard playerState == .roundDraw else {
            print("\(playerID) \(playerState) Not equal roundDraw state!")
            return
        }
        
        let decision: PlayerDecision
        if basePlayer.canZimo() {
            decision = PlayerDecision.zimo(self, nil)
        } else if basePlayer.canSelfKang() {
            decision = PlayerDecision.selfKang(self, nil)
        } else {
            decision = PlayerDecision.pass(self, nil)
        }
        processDecision(decision)
    }
    
    func checkThenProcessBotDiscardDecisions(discarded: MahjongEntity) {
        guard playerState == .roundDecision else {
            print("\(playerID) \(playerState) Not equal roundDecision state!")
            return
        }
        
        let decision: PlayerDecision
        if basePlayer.canHu(discarded) {
            decision = PlayerDecision.hu(self, discarded)
        } else if basePlayer.canKang(discarded) {
            decision = PlayerDecision.kang(self, discarded)
        } else if basePlayer.canPong(discarded) {
            decision = PlayerDecision.pong(self, discarded)
        } else {
            decision = PlayerDecision.pass(self, nil)
        }
        processDecision(decision)
    }
}
