//
//  ProfileListDetailSyncTests.swift
//  MatchMateTests
//
//  Created by Kushagra Goyal on 05/09/26.
//

import Testing
import Foundation
@testable import MatchMate

@MainActor
struct ProfileListDetailSyncTests {

    @Test func acceptingOnDetailUpdatesTheListCardWithoutRefreshing() async {
        let repository = StubProfileRepository()

        let list = ProfileListViewModel(repository: repository)
        await list.loadInitialIfNeeded()
        let observation = Task { await list.observeProfileUpdates() }
        await waitUntil("list subscribes") { repository.subscriberCount == 1 }

        let target = list.profiles[3]
        #expect(target.status == .pending)

        let detail = ProfileDetailViewModel(profile: target, repository: repository)
        await detail.accept()
        await waitUntil("list card updates") { list.profiles[3].status == .accepted }
        observation.cancel()

        #expect(detail.profile.status == .accepted)
        #expect(list.profiles[3].status == .accepted, "list must not need a reload")
        #expect(list.profiles[3].id == target.id, "the right card must have changed")
    }

    @Test func decliningOnTheListReachesAnOpenDetailScreen() async {
        let repository = StubProfileRepository()

        let list = ProfileListViewModel(repository: repository)
        await list.loadInitialIfNeeded()
        let target = list.profiles[6]

        let detail = ProfileDetailViewModel(profile: target, repository: repository)
        let observation = Task { await detail.observeProfileUpdates() }
        await waitUntil("detail subscribes") { repository.subscriberCount == 1 }

        await list.decline(target)
        await waitUntil("detail follows the list") { detail.profile.status == .declined }
        observation.cancel()

        #expect(list.profiles[6].status == .declined)
        #expect(detail.profile.status == .declined, "detail must follow the list")
    }

    @Test func aSyncedDecisionIsStillThereForAFreshListViewModel() async {
        let repository = StubProfileRepository()

        let list = ProfileListViewModel(repository: repository)
        await list.loadInitialIfNeeded()
        let target = list.profiles[8]

        let detail = ProfileDetailViewModel(profile: target, repository: repository)
        await detail.accept()

        let reopened = ProfileListViewModel(repository: repository)
        await reopened.loadInitialIfNeeded()

        #expect(reopened.profiles[8].status == .accepted)
    }
}
