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
    func submitCompletion(for player: IPlayerController, type: PlayerCommand)
}

@Observable
class GameManager: IDecisionProcessor {
    let style: IMahjongStyle = BloodyMahjong() // TODO: this will be added in later versions
    var mahjongSet: MahjongSet
    var table: TableEntity?
    var currentTurn = 0
    var gameState: GameState = .gameWaitToStart
    
    // MARK: Player attributes
    var localPlayer: LocalPlayerController?
    var players: [IPlayerController] = []
    var playerDecisions: [String: PlayerDecision] = [:]
    var playerCompletions: Set<String> = []
    var currentPlayerIndex: Int = 0
    var winnerIDs: [String] = []
    
    // TODO: Bloody only stuff
    var switchOrder: SwitchOrder = .switchOrderFront

    // TODO: init(players: [IPlayerController], mahjongSet: MahjongSet, style: IMahjongStyle, table: TableEntity)

    init() {
        self.mahjongSet = MahjongSet()
    }
    
    @MainActor
    public func onModelLoaded(table: TableEntity) {
        self.table = table
        mahjongSet = MahjongSet()
        mahjongSet.loadMahjongsIntoMahjongSet()
        table.addChild(mahjongSet.rootEntity)
        
        // initializing players
        createLocalPlayer()
        fillSeatsWithBots()
        print("table has: \(table.children.count) children")
        for child in table.children {
            print(child.name)
        }
        enterWaitToStartState()
    }
    
    public func cleanUpGameData() {
        table?.removeChild(mahjongSet.rootEntity)
        for player in players {
            table?.removeChild(player.basePlayer.rootEntity)
        }
        players.removeAll()
    }

    // TODO: put into bot manager logic
    func fillSeatsWithBots() {
        guard let table = self.table else { return }
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
    
    func createLocalPlayer() {
        guard let table = self.table else { return }
        // FIXME: create local player here for now
        let seat = getPlayerSeat(withIndex: players.count)
        let id = "LocalPlayerXiong"
        mahjongSet.discardPile[id] = []
        let newPlayer = Player(playerId: id, seat: seat,
                               table: table, mahjongSet: mahjongSet,
                               discardPile: mahjongSet.discardPile[id]!,
                               style: style)
        let newController = LocalPlayerController(basePlayer: newPlayer, decisionProcessor: self)
        players.append(newController)
        localPlayer = newController
    }

    // MARK: Core logic

    /// next player take turn
    /// when the player completes their turn action
    /// they should send back a completion notice using submitCompletion
    func nextTurn(state: PlayerState) {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        // ignore player if hu
        if players[currentPlayerIndex].playerState == .end {
            nextTurn(state: state)
        } else {
            currentTurn += 1
            players[currentPlayerIndex].takeTurn(state: state)
        }
    }

    /// Used for players to submit their decision
    /// When all decisions are received, they will be filtered.
    /// If only hu decisions are submitted, all hu decisions are process
    /// If hu and pong both exists, pongs will be ignored
    /// else process pong
    func submitDecision(for player: IPlayerController, decision: PlayerDecision) {
        playerDecisions[player.playerID] = decision
        print("\(player.playerID) submitted decision of type: \(decision.label.name)")
        print("received total of: \(playerDecisions.count) decisions")
        var tempCurrentIndex = currentPlayerIndex // default current player
        // When all decisions have been submitted, process them
        if playerDecisions.count == players.count-1-winnerIDs.count {
            // Determine the presence of specific decisions
            let hasHu = playerDecisions.values.contains { [.hu, .zimo].contains($0.label) }
            // Filter decisions based on the rules
            var filteredDecisions = playerDecisions.filter { $0.value.label != .pass }
            if hasHu {
                // If only hu decisions are submitted or hu is present, keep only hu decisions
                // current player is the first hu because hu players will be skipped automatically
                filteredDecisions = filteredDecisions.filter { $0.value.label == .hu }
                tempCurrentIndex = players.firstIndex(where: {
                    $0.playerID == filteredDecisions.keys.first
                }) ?? tempCurrentIndex
            } else {
                // If no hu, proceed with all
                // no hu there could only be one decision!
                // change nextPlayer to be the one who called pong or kang!
                tempCurrentIndex = players.firstIndex(where: {
                    $0.playerID == filteredDecisions.keys.first
                }) ?? tempCurrentIndex
            }
            
            playerDecisions.removeAll()
            currentPlayerIndex = tempCurrentIndex
            print("current player is: \(players[currentPlayerIndex].playerID)")
            
            if filteredDecisions.isEmpty {
                // go to next turn
                nextTurn(state: .roundDraw)
            } else {
                // Execute actions for the filtered decisions
                for decision in filteredDecisions.values {
                    decision.decision()
                }
                // if people hu, needs to manually handle next turn here
                // normally we handle nextTurn in submitCompletion.
                // However, if multiple player called hu at the same time,
                // multiple .hu completion will be submitted and therefore
                // multiple nextTurn will be called back to back causing unwanted
                // behavior.
                // MARK: solution: don't call nextTurn in submitCompletion .hu and call it here!!
                if hasHu {
                    nextTurn(state: .roundDraw)
                }
            }
        }
    }

    /// used to receive player completion notices
    /// also handles player hu notices
    func submitCompletion(for player: IPlayerController, type: PlayerCommand) {
        switch type {
        case .discard:
            print("\(player.playerID) discarded: \(mahjongSet.lastTileDiscarded!.name)")
            otherPlayerDecides(current: player)
        case .draw: // this should only be called in init draw
            // sanity check
            guard gameState == .initialDraw else { return }
            if currentTurn == 16 {
                enterSwitchTileState()
            } else {
                nextTurn(state: .initDraw)
            }
        case .chooseDiscard:
            playerCompletions.insert(player.playerID)
            print("Player competion count: \(playerCompletions.count)")
            if playerCompletions.count == players.count {
                playerCompletions.removeAll()
                enterRoundState()
            }
        case .switchTile:
            playerCompletions.insert(player.playerID)
            if playerCompletions.count == players.count {
                playerCompletions.removeAll()
                performSwitchTilesAction()
            }
        case .zimo:
            winnerIDs.append(player.playerID)
            if winnerIDs.count == players.count-1 {
                endGame()
                return
            }
            // MARK: case .hu nextTurn() is handled in submitDecision!
            nextTurn(state: .roundDraw)
        case .hu:
            winnerIDs.append(player.playerID)
            if winnerIDs.count == players.count-1 {
                endGame()
                return
            }
        default:
            print("\(gameState) complete! But not handled")
            return
        }
    }

    func otherPlayerDecides(current: IPlayerController) {
//        guard let mahjongSet = self.mahjongSet else { return }
        for player in players {
            if player.playerID == current.playerID { continue }
            if player.playerState == .end { continue }
            // ask players to decide
            // all players should submit a decision using submitDecision(...)
            player.askPlayerToDecide(discarded: mahjongSet.lastTileDiscarded!)
        }
    }
}
