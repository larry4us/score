//
//  Coordinator.swift
//  DominoScore
//

import SwiftUI

// MARK: - Route Definitions

/// Rotas do fluxo de autenticação.
enum AuthRoute: Hashable {
    case login
    case emailSignIn
}

/// Rotas do fluxo de score/sessão.
enum ScoreRoute: Hashable {
    case home
    case lobby(session: Session)
    case scoreboard(session: Session)
}

/// Rota raiz que agrupa os dois domínios de navegação.
enum AppRoute: Hashable {
    case auth(AuthRoute)
    case score(ScoreRoute)
}

// MARK: - Coordinator

/// Coordinator que gerencia a navegação.
@Observable
final class Coordinator {
    private(set) var authService: AuthService?
    let sessionRepository: SessionRepository

    var path = NavigationPath()

    /// Inicializador padrão — usado pelo app com Firebase.
    init(authService: AuthService, sessionRepository: SessionRepository = SessionRepository()) {
        self.authService = authService
        self.sessionRepository = sessionRepository
    }

    /// Inicializador para testes — sem dependência do Firebase.
    init(authenticated: Bool = false) {
        self.authService = nil
        self.sessionRepository = SessionRepository()
        self._isAuthenticated = authenticated
    }

    /// Estado de autenticação. Quando `authService` existe, delega para ele.
    var isAuthenticated: Bool {
        authService?.isAuthenticated ?? _isAuthenticated
    }
    private var _isAuthenticated = false

    // MARK: - Navigation

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    /// Decide a rota raiz com base no estado de autenticação.
    func rootRoute() -> AppRoute {
        isAuthenticated ? .score(.home) : .auth(.login)
    }

    // MARK: - View Builders

    @ViewBuilder
    func build(_ route: AppRoute) -> some View {
        switch route {
        case .auth(let authRoute):
            buildAuth(authRoute)
        case .score(let scoreRoute):
            buildScore(scoreRoute)
        }
    }

    @ViewBuilder
    private func buildAuth(_ route: AuthRoute) -> some View {
        switch route {
        case .login:
            AuthenticationView()
        case .emailSignIn:
            if let authService {
                EmailSignInView(authService: authService)
            }
        }
    }

    @ViewBuilder
    private func buildScore(_ route: ScoreRoute) -> some View {
        switch route {
        case .home:
            CreateSessionView()
        case .lobby(let session):
            LobbyView(session: session)
        case .scoreboard(let session):
            ScoreboardView(session: session)
        }
    }
}

// MARK: - CoordinatorView

/// View raiz que encapsula o NavigationStack e delega a resolução de rotas ao Coordinator.
struct CoordinatorView: View {
    @State private var coordinator = Coordinator(authService: AuthService())

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.build(coordinator.rootRoute())
                .navigationDestination(for: AppRoute.self) { route in
                    coordinator.build(route)
                }
        }
        .environment(coordinator)
        .onAppear {
            coordinator.authService?.restoreSession()
        }
        .onChange(of: coordinator.isAuthenticated) {
            coordinator.popToRoot()
        }
    }
}

