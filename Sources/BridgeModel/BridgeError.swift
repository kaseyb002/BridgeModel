import Foundation

public enum BridgeError: Error, Equatable, Sendable {
    case invalidPlayerCount
    case notYourTurn
    case biddingNotInProgress
    case playingNotInProgress
    case invalidBid
    case cannotDouble
    case cannotRedouble
    case cardNotInHand
    case mustFollowSuit
    case roundAlreadyComplete
    case playerNotFound
    case roundPassedOut
}
