//
//  HMSObservablePeerListIterator.swift
//  HMSRoomKitDevelopmentProject
//
//  Created by Dmitry Fedoseyev on 22.09.2023.
//

import Foundation
import HMSSDK

@MainActor
public final class HMSObservablePeerListIterator: ObservableObject {
    @Published public private(set) var peers: [HMSPeerModel]
    @Published public private(set) var hasNext: Bool
    @Published public private(set) var isLoading: Bool

    public var options: HMSPeerListIteratorOptions {
        iterator.options
    }
    
    private var iterator: HMSPeerListIterator
    private var modelBuilder: ((HMSPeer) -> HMSPeerModel)
    
    init(iterator: HMSPeerListIterator, modelBuilder: @escaping ((HMSPeer) -> HMSPeerModel)) {
        self.peers = []
        self.hasNext = true
        self.isLoading = false
        self.modelBuilder = modelBuilder
        self.iterator = iterator
    }
    
    public func loadNext() async throws {
        isLoading = true
        return try await withCheckedThrowingContinuation { continuation in
            iterator.next() { [weak self] newPeers, error in
                guard let self = self else { return }
                if let error = error {
                    self.isLoading = false
                    continuation.resume(throwing: error)
                } else {
                    if let newPeers = newPeers {
                        let newModels = newPeers.map { self.modelBuilder($0) }
                        self.peers.append(contentsOf: newModels)
                    }
                    self.hasNext = iterator.hasNext
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
}
