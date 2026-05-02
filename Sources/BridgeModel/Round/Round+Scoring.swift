import Foundation

extension Round {
    mutating func calculateScore() {
        guard let contract else { return }

        let declarerPartnership: Partnership = contract.declarerPartnership
        let isVulnerable: Bool = vulnerability.isVulnerable(declarerPartnership)

        let declarerTricksWon: Int = tricks.filter {
            $0.winner?.partnership == declarerPartnership
        }.count
        let defenderTricksWon: Int = 13 - declarerTricksWon
        let tricksNeeded: Int = contract.tricksNeeded
        let made: Bool = declarerTricksWon >= tricksNeeded

        var declarerScore: Int = 0
        var defenderScore: Int = 0

        if made {
            declarerScore = calculateMadeScore(
                contract: contract,
                overtricks: declarerTricksWon - tricksNeeded,
                isVulnerable: isVulnerable
            )
        } else {
            defenderScore = calculateDefeatedScore(
                contract: contract,
                undertricks: tricksNeeded - declarerTricksWon,
                isVulnerable: isVulnerable
            )
        }

        if ruleOptions.honorsScoring {
            let honorsScore: Int = calculateHonorsScore(contract: contract)
            declarerScore += honorsScore
        }

        self.result = .init(
            contract: contract,
            declarerTricksWon: declarerTricksWon,
            defenderTricksWon: defenderTricksWon,
            made: made,
            declarerScore: declarerScore,
            defenderScore: defenderScore
        )

        for i in 0..<playerHands.count {
            if playerHands[i].position.partnership == declarerPartnership {
                playerHands[i].player.points += declarerScore
            } else {
                playerHands[i].player.points += defenderScore
            }
        }
    }

    private func calculateMadeScore(
        contract: Contract,
        overtricks: Int,
        isVulnerable: Bool
    ) -> Int {
        var score: Int = 0
        let bid: Bid = contract.bid

        var trickScore: Int = bid.trickScore
        if contract.isDoubled { trickScore *= 2 }
        if contract.isRedoubled { trickScore *= 4 }
        score += trickScore

        if overtricks > 0 {
            if contract.isRedoubled {
                score += overtricks * (isVulnerable ? 400 : 200)
            } else if contract.isDoubled {
                score += overtricks * (isVulnerable ? 200 : 100)
            } else {
                score += overtricks * bid.denomination.trickValue
            }
        }

        let isGame: Bool = trickScore >= 100
        if isGame {
            score += isVulnerable ? 500 : 300
        } else {
            score += 50
        }

        if bid.isSmallSlam {
            score += isVulnerable ? 750 : 500
        }
        if bid.isGrandSlam {
            score += isVulnerable ? 1500 : 1000
        }

        if contract.isDoubled {
            score += 50
        }
        if contract.isRedoubled {
            score += 100
        }

        return score
    }

    private func calculateDefeatedScore(
        contract: Contract,
        undertricks: Int,
        isVulnerable: Bool
    ) -> Int {
        guard undertricks > 0 else { return 0 }

        if contract.isRedoubled {
            return calculateDoubledUndertrickPenalty(
                undertricks: undertricks,
                isVulnerable: isVulnerable
            ) * 2
        }

        if contract.isDoubled {
            return calculateDoubledUndertrickPenalty(
                undertricks: undertricks,
                isVulnerable: isVulnerable
            )
        }

        return undertricks * (isVulnerable ? 100 : 50)
    }

    private func calculateDoubledUndertrickPenalty(
        undertricks: Int,
        isVulnerable: Bool
    ) -> Int {
        var penalty: Int = 0
        for i in 1...undertricks {
            if isVulnerable {
                penalty += (i == 1) ? 200 : 300
            } else {
                switch i {
                case 1: penalty += 100
                case 2, 3: penalty += 200
                default: penalty += 300
                }
            }
        }
        return penalty
    }

    private func calculateHonorsScore(contract: Contract) -> Int {
        guard let trumpSuit: Suit = contract.bid.denomination.suit else {
            return calculateNoTrumpHonors()
        }
        return calculateTrumpHonors(trumpSuit: trumpSuit)
    }

    private func calculateTrumpHonors(trumpSuit: Suit) -> Int {
        let honorRanks: [Rank] = [.ten, .jack, .queen, .king, .ace]
        for hand in playerHands {
            let trumpHonors: Int = hand.cards.filter { cardID in
                guard let card: Card = cardsMap[cardID] else { return false }
                return card.suit == trumpSuit && honorRanks.contains(card.rank)
            }.count

            if trumpHonors == 5 { return 150 }
            if trumpHonors == 4 { return 100 }
        }
        return 0
    }

    private func calculateNoTrumpHonors() -> Int {
        for hand in playerHands {
            let aces: Int = hand.cards.filter { cardID in
                cardsMap[cardID]?.rank == .ace
            }.count
            if aces == 4 { return 150 }
        }
        return 0
    }
}
