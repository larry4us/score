//
//  AuthCoordinator.swift
//  DominoScore
//

import SwiftUI

/// Rotas do fluxo de autenticação.
/// Cada caso pode carregar valores associados necessários pela tela de destino.
enum Pages: Hashable {
    case emailSignIn(authService: AuthService)
}

/// Coordinator que gerencia a navegação
@Observable
final class Coordinator {
    var path = NavigationPath()

    func navigate(to route: Pages) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    // MARK: - View Builder

    @ViewBuilder
    func build(_ route: Pages) -> some View {
        switch route {
        case .emailSignIn(let authService):
            EmailSignInView(authService: authService)
        }
    }
}
// MARK: - CoordinatorView

/// View raiz que encapsula o NavigationStack e delega a resolução de rotas ao Coordinator.
struct CoordinatorView: View {
    @State private var coordinator = Coordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            AuthenticationView(authService: AuthService(), coordinator: coordinator)
                .navigationDestination(for: Pages.self) { route in
                    coordinator.build(route)
                }
        }
    }
}

