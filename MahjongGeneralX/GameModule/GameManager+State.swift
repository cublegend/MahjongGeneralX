//
//  GameManager+State.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/11/24.
//

import Foundation
import MahjongCore

extension GameManager {
    // MARK: .waitToStart
    public func enterWaitToStartState() {
        guard gameState.transition(to: .gameWaitToStart) else { return }
        initializeGameData()
    }

    func initializeGameData() {
        //        guard let mahjongSet = self.mahjongSet else { return }
        for player in players {
            mahjongSet.discardPile[player.playerID] = []
        }
        playerCompletions.removeAll()
        playerDecisions.removeAll()
        winnerIDs.removeAll()
        currentTurn = 0
        currentPlayerIndex = 3 // TODO: change to random dealer
    }

    // MARK: .initialDraw

    public func startGame() {
        guard gameState.transition(to: .initialDraw) else { return }
        nextTurn(state: .initDraw)
    }

    // MARK: .switchTiles

    /// ask all players to choose switch tiles
    /// when a player is ready, they should submit a complete Decision
    /// through submitCompletion(...)
    func enterSwitchTileState() {
        guard gameState.transition(to: .switchTiles) else { return }
        switchOrder = SwitchOrder.allCases.randomElement()!
        for player in players {
            player.askPlayerToChooseSwitchTiles()
        }
    }

    /// performs the switch action for all players in a command
    func performSwitchTilesAction() {
        if gameState != .switchTiles { return }
        // construct switch dictionary
        var dic: [String: [MahjongEntity]] = [:]
        for player in players {
            dic[player.playerID] = player.switchTiles
        }
        let command = SwitchTilesCommand(players: players.map({$0.basePlayer}), switchTiles: dic, order: switchOrder)
        Commands.executeCommand(command)
        enterDecideDiscardState()
    }

    // MARK: .decideDiscardState

    /// ask all players to choose discard type
    /// when a player is ready, they should submit a complete Decision
    /// through submitCompletion(...)
    /// if all players complete, enter round state
    func enterDecideDiscardState() {
        guard gameState.transition(to: .decideDiscard) else { return }
        for player in players {
            player.askPlayerToChooseDiscardType()
        }
    }

    // MARK: .round

    func enterRoundState() {
        guard gameState.transition(to: .round) else { return }
        nextTurn(state: .roundDraw)
    }
    
    func endGame() {
        guard gameState.transition(to: .gameEnd) else { return }
        print("Game ended!")
        // tell every player
        for player in players {
            player.onGameEnded()
        }
    }
}
