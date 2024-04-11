//
//  GameManager.swift
//  MahjongGeneralX
//
//  Created by Rex Ma on 4/9/24.
//

import Foundation
import MahjongCore
import MahjongCommons
import MahjongAnalyzer

protocol IDecisionProcessor {
    func submitDecision(for player: IPlayerController, decision: PlayerDecision)
    func submitCompletion(for player: IPlayerController)
}

class GameManager: IDecisionProcessor {
    let style: IMahjongStyle
    let mahjongSet: MahjongSet
    let table: TableEntity
    var currentTurn = 0
    var gameState: GameState = .gameWaitToStart
    var players: [IPlayerController] = []
    var playerDecisions: [String: PlayerDecision] = [:]
    var playerCompletions: Set<String> = []
    var currentPlayerIndex: Int = 0
    
    // TODO: Bloody only stuff
    var switchOrder: SwitchOrder = .switchOrderFront

    init(players: [IPlayerController], mahjongSet: MahjongSet, style: IMahjongStyle, table: TableEntity) {
        self.mahjongSet = mahjongSet
        self.players = players
        self.style = style
        self.table = table
    }

    // MARK: Core logic

    func nextTurn(_ completion: @escaping () -> Void) {
        currentTurn += 1
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        players[currentPlayerIndex].takeTurn(state: PlayerState.roundDraw, completion: completion)
    }

    /// Used for players to submit their decision
    /// When all decisions are received, they will be filtered.
    /// If only hu decisions are submitted, all hu decisions are process
    /// If hu and pong both exists, pongs will be ignored
    /// else process pong
    func submitDecision(for player: IPlayerController, decision: PlayerDecision) {
        playerDecisions[player.playerID] = decision

        // When all decisions have been submitted, process them
        if playerDecisions.count == players.count {
            // Determine the presence of specific decisions
            let hasHu = playerDecisions.values.contains { $0.label == .hu }
            // Filter decisions based on the rules
            let filteredDecisions: [PlayerDecision]
            if hasHu {
                // If only hu decisions are submitted or hu is present, keep only hu decisions
                filteredDecisions = playerDecisions.values.filter { $0.label == .hu }
            } else {
                // If neither hu nor pong, proceed with kang or whatever is left
                filteredDecisions = Array(playerDecisions.values)
            }

            // Execute actions for the filtered decisions
            for decision in filteredDecisions {
                decision.decision()
            }

            playerDecisions.removeAll()
        }
    }

    func submitCompletion(for player: any IPlayerController) {
        playerCompletions.insert(player.playerID)
        if playerCompletions.count == players.count {
            if gameState == .switchTiles {
                performSwitchTilesAction()
            } else if gameState == .decideDiscard {
                enterRoundState()
            } else if gameState == .initialDraw {
                enterSwitchTileState()
            } else {
                print("\(gameState) complete! But not handled")
            }
            playerCompletions.removeAll()
        }
    }

    func otherPlayerDecides(current: IPlayerController) {
        for player in players {
            if player.playerID == current.playerID { continue }
            // ask players to decide
            // all players should submit a decision using submitDecision(...)
            current.askPlayerToDecide(discarded: mahjongSet.lastTileDiscarded!)
        }
    }

    // MARK: starts game

    /// This method is called once per game when entering game room
    /// NOT once per new mahjong game inside a room
    func startGame() {
        // Initialize bots if not enough players
        fillSeatsWithBots()
    }

    // TODO: put into bot manager logic
    func fillSeatsWithBots() {
        let nonBotCount = players.count
        if nonBotCount < 4 {
            for idx in nonBotCount..<4 {
                let seat = getPlayerSeat(withIndex: idx)
                let id = "Bot\(idx)"
                mahjongSet.discardPile[id] = []
                let newPlayer = Player(playerId: id, seat: seat, 
                                       table: table, mahjongSet: mahjongSet,
                                       discardPile: mahjongSet.discardPile[id]!,
                                       style: style)
                let newController = BotController(basePlayer: newPlayer, decisionProcessor: self)
                players.append(newController)
            }
        }
    }
}
