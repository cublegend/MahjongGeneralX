//
//  GameManager.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/9/24.
//

import Foundation
import RealityKit
import MahjongCore
import MahjongCommons

protocol IDecisionProcessor {
    func submitDecision(for player: PlayerController, decision: PlayerDecision)
}

class GameManager: IDecisionProcessor {
    let style: IMahjongStyle
    let mahjongSet: MahjongSet
    let table: TableEntity
    var gameState: GameState = .gameWaitToStart
    var players: [PlayerController] = []
    var playerDecisions: [String:PlayerDecision] = [:]
    
    init(players: [PlayerController], mahjongSet: MahjongSet, style: IMahjongStyle, table: TableEntity) {
        self.mahjongSet = mahjongSet
        self.players = players
        self.style = style
        self.table = table
    }
    
    // MARK: starts game
    
    /// This method is called once per game when entering game room
    /// NOT once per new mahjong game inside a room
    func startGame() {
        // Initialize bots if not enough players
        fillSeatsWithBots()
    }
    
    // FIXME: put into bot manager logic
    func fillSeatsWithBots() {
        let nonBotCount = players.count
        if nonBotCount < 4 {
            for i in nonBotCount..<4 {
                let seat = getPlayerSeat(withIndex: i)
                let id = "Bot\(i)"
                mahjongSet.discardPile[id] = []
                let newPlayer = Player(playerId: id, seat: seat, table: table, mahjongSet: mahjongSet, discardPile: mahjongSet.discardPile[id]!, style: style)
                let newController = PlayerController(basePlayer: newPlayer, decisionProcessor: self)
                players.append(newController)
            }
        }
    }
    
    // MARK: .waitToStart
    
    func enterWaitToStartState() {
        gameState.transition(to: .gameWaitToStart)
        initializeGameData()
        
        enterInitialDrawState()
    }
    
    func initializeGameData() {
        for player in players {
            mahjongSet.discardPile[player.playerID] = []
        }
        playerDecisions.removeAll()
    }
    
    // MARK: .initialDraw
    
    func enterInitialDrawState() {
        guard gameState == .gameWaitToStart else {
            return
        }
        gameState.transition(to: .initialDraw)
        
    }
    
    
    
    
    
    func submitDecision(for player: PlayerController, decision: PlayerDecision) {
        playerDecisions[player.playerID] = decision
        if playerDecisions.count == players.count {
            // process decisions
        }
    }
}
