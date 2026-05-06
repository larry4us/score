//
//  CoordinatorTests.swift
//  DominoScoreTests
//

import Testing
import SwiftUI
@testable import DominoScore

// MARK: - Helpers

private func makeSampleSession() -> Session {
    Session(code: "AB3K7", hostUid: "host-1", status: .waiting)
}

// MARK: - isAuthenticated

@Suite("Coordinator – isAuthenticated")
struct CoordinatorAuthStateTests {

    @Test func isAuthenticated_defaultsToFalse() {
        let coordinator = Coordinator()
        #expect(coordinator.isAuthenticated == false)
    }

    @Test func isAuthenticated_respectsInitParameter() {
        let coordinator = Coordinator(authenticated: true)
        #expect(coordinator.isAuthenticated == true)
    }
}

// MARK: - rootRoute()

@Suite("Coordinator – rootRoute")
struct CoordinatorRootRouteTests {

    @Test func rootRoute_whenNotAuthenticated_returnsAuthEmailSignIn() {
        let coordinator = Coordinator(authenticated: false)
        #expect(coordinator.rootRoute() == .auth(.emailSignIn))
    }

    @Test func rootRoute_whenAuthenticated_returnsScoreHome() {
        let coordinator = Coordinator(authenticated: true)
        #expect(coordinator.rootRoute() == .score(.home))
    }
}

// MARK: - navigate(to:)

@Suite("Coordinator – navigate")
struct CoordinatorNavigateTests {

    @Test func navigate_appendsToPath() {
        let coordinator = Coordinator()

        coordinator.navigate(to: .auth(.emailSignIn))

        #expect(coordinator.path.count == 1)
    }

    @Test func navigateMultiple_incrementsPath() {
        let coordinator = Coordinator(authenticated: true)
        let session = makeSampleSession()

        coordinator.navigate(to: .score(.lobby(session: session)))
        coordinator.navigate(to: .score(.scoreboard(session: session)))

        #expect(coordinator.path.count == 2)
    }
}

// MARK: - pop()

@Suite("Coordinator – pop")
struct CoordinatorPopTests {

    @Test func pop_removesLastRoute() {
        let coordinator = Coordinator()

        coordinator.navigate(to: .auth(.emailSignIn))
        #expect(coordinator.path.count == 1)

        coordinator.pop()
        #expect(coordinator.path.count == 0)
    }

    @Test func pop_whenPathEmpty_doesNotCrash() {
        let coordinator = Coordinator()

        coordinator.pop()
        #expect(coordinator.path.count == 0)
    }

    @Test func pop_removesOnlyLastRoute() {
        let coordinator = Coordinator(authenticated: true)
        let session = makeSampleSession()

        coordinator.navigate(to: .score(.lobby(session: session)))
        coordinator.navigate(to: .score(.scoreboard(session: session)))
        #expect(coordinator.path.count == 2)

        coordinator.pop()
        #expect(coordinator.path.count == 1)
    }
}

// MARK: - popToRoot()

@Suite("Coordinator – popToRoot")
struct CoordinatorPopToRootTests {

    @Test func popToRoot_clearsEntirePath() {
        let coordinator = Coordinator()

        coordinator.navigate(to: .auth(.emailSignIn))
        coordinator.navigate(to: .auth(.emailSignIn))
        #expect(coordinator.path.count == 2)

        coordinator.popToRoot()
        #expect(coordinator.path.count == 0)
    }

    @Test func popToRoot_whenAlreadyEmpty_staysEmpty() {
        let coordinator = Coordinator()

        coordinator.popToRoot()
        #expect(coordinator.path.count == 0)
    }
}

// MARK: - Mixed routes

@Suite("Coordinator – mixed routes")
struct CoordinatorMixedRouteTests {

    @Test func mixedRoutes_allShareSamePath() {
        let coordinator = Coordinator()
        let session = makeSampleSession()

        coordinator.navigate(to: .auth(.emailSignIn))
        coordinator.navigate(to: .score(.scoreboard(session: session)))

        #expect(coordinator.path.count == 2)

        coordinator.pop()
        #expect(coordinator.path.count == 1)

        coordinator.popToRoot()
        #expect(coordinator.path.count == 0)
    }
}
