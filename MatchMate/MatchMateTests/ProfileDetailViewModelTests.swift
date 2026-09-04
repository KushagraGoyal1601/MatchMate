//
//  ProfileDetailViewModelTests.swift
//  MatchMateTests
//
//  Created by Kushagra Goyal on 05/09/26.
//

import Testing
import Foundation
@testable import MatchMate

@MainActor
struct ProfileDetailViewModelTests {

    private func makeViewModel(
        at index: Int = 0
    ) async -> (ProfileDetailViewModel, StubProfileRepository, MatchProfile) {
        let repository = StubProfileRepository()
        let seeded = try! await repository.profiles(page: 1)
        let profile = seeded[index]
        return (ProfileDetailViewModel(profile: profile, repository: repository), repository, profile)
    }

    @Test func acceptUpdatesDetailImmediatelyAndReachesTheRepository() async {
        let (viewModel, repository, profile) = await makeViewModel()

        await viewModel.accept()

        #expect(viewModel.profile.status == .accepted, "detail UI must update right away")
        #expect(repository.status(forID: profile.id) == .accepted)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func declineUpdatesDetailImmediatelyAndReachesTheRepository() async {
        let (viewModel, repository, profile) = await makeViewModel(at: 2)

        await viewModel.decline()

        #expect(viewModel.profile.status == .declined)
        #expect(repository.status(forID: profile.id) == .declined)
    }

    @Test func aFailedDecisionRevertsTheScreenAndReportsTheError() async {
        let (viewModel, repository, _) = await makeViewModel(at: 1)
        repository.updateFailure = AppError.storageFailed("Disk is full")

        await viewModel.accept()

        #expect(viewModel.profile.status == .pending, "an optimistic update must roll back")
        #expect(viewModel.errorMessage == "Disk is full")
    }

    @Test func dismissingTheErrorClearsIt() async {
        let (viewModel, repository, _) = await makeViewModel()
        repository.updateFailure = AppError.storageFailed("Disk is full")
        await viewModel.accept()

        viewModel.dismissError()

        #expect(viewModel.errorMessage == nil)
    }

    @Test func detailReflectsAnUpdateMadeOutsideIt() async throws {
        let (viewModel, repository, profile) = await makeViewModel(at: 1)

        let observation = Task { await viewModel.observeProfileUpdates() }
        await waitUntil("detail subscribes") { repository.subscriberCount == 1 }

        try await repository.updateStatus(.declined, forID: profile.id)
        await waitUntil("detail receives the update") { viewModel.profile.status == .declined }
        observation.cancel()

        #expect(viewModel.profile.status == .declined)
    }

    @Test func updatesForOtherProfilesAreIgnored() async throws {
        let repository = StubProfileRepository()
        let seeded = try await repository.profiles(page: 1)
        let viewModel = ProfileDetailViewModel(profile: seeded[0], repository: repository)

        let observation = Task { await viewModel.observeProfileUpdates() }
        await waitUntil("detail subscribes") { repository.subscriberCount == 1 }

        var probe = await repository.profileUpdates().makeAsyncIterator()
        try await repository.updateStatus(.accepted, forID: seeded[5].id)
        let delivered = await probe.next()

        observation.cancel()

        #expect(delivered?.id == seeded[5].id)
        #expect(viewModel.profile.status == .pending)
    }
}
