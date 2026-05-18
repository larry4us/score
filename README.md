# DominoScore

Aplicativo iOS para controle de pontuacao em partidas de domino, com suporte a partidas online (tempo real) e offline (local).

## Tech Stack

| Tecnologia | Uso |
|---|---|
| **Swift / SwiftUI** | Linguagem e framework de UI |
| **Firebase Auth** | Autenticacao (e-mail/senha + Sign in with Apple) |
| **Firebase Firestore** | Banco de dados em tempo real para sessoes online |
| **AuthenticationServices** | Sign in with Apple nativo |
| **CryptoKit** | Hash SHA-256 para nonce do Apple Sign-In |
| **CoreImage** | Geracao de QR Codes |
| **Swift Package Manager** | Gerenciamento de dependencias |

## Arquitetura

O projeto segue um padrao **Coordinator** com estado reativo via `@Observable`:

```
Coordinator (@Observable)
├── AuthService        → autenticacao (Firebase Auth + Apple)
├── SessionRepository  → sessoes de jogo (Firestore ou in-memory)
└── NavigationPath     → navegacao via NavigationStack
```

- **Coordinator** gerencia rotas (`AuthRoute`, `ScoreRoute`) e constroi as views correspondentes.
- **SessionRepository** abstrai o acesso ao Firestore, servindo como unica fonte de verdade para a sessao atual. No modo offline, manipula o estado em memoria.
- **FirestoreClient** encapsula as operacoes CRUD do Firestore.
- **AuthService** lida com autenticacao, restauracao de sessao e sincronizacao do perfil com o Firestore.

## Estrutura do Projeto

```
DominoScore/
├── App/
│   ├── DominoScoreApp.swift          # Entry point
│   └── AppDelegate.swift             # Firebase.configure()
│
├── Core/
│   ├── Coordinator/
│   │   └── Coordinator.swift         # Navegacao e rotas
│   ├── Models/
│   │   ├── Session.swift             # Sessao (waiting/active/finished, online/offline)
│   │   ├── Participant.swift         # Jogador com time e score
│   │   ├── Team.swift                # Agrupamento por cor (computed, nao persistido)
│   │   ├── AppUser.swift             # Perfil no Firestore
│   │   └── ScoreButton.swift         # Botoes de pontuacao configuraveis
│   ├── Repositories/
│   │   └── SessionRepository.swift   # Estado da sessao (online + offline)
│   └── Services/
│       ├── AuthService.swift         # Firebase Auth + Apple Sign-In
│       ├── FirestoreClient.swift     # CRUD Firestore
│       ├── QRCodeService.swift       # Geracao de QR Code
│       ├── CodeGenerator.swift       # Codigos de 5 caracteres
│       └── HapticsService.swift      # Feedback haptico
│
├── Features/
│   ├── Authentication/
│   │   ├── AuthenticationView.swift  # Tela inicial (Apple + Email)
│   │   └── EmailSignInView.swift     # Login/cadastro por email
│   ├── Home/
│   │   └── CreateSessionView.swift   # Criar ou entrar em partida
│   ├── Session/
│   │   ├── LobbyView.swift           # Coordena waiting/active/finished
│   │   ├── WaitingView.swift         # Sala de espera com selecao de times
│   │   ├── ActiveGameView.swift      # Placar ao vivo + botoes de score
│   │   └── FinishedGameView.swift    # Resultado final
│   └── Components/
│       ├── QRCodeSheet.swift         # Exibicao do QR Code
│       ├── QRScannerView.swift       # Scanner de QR Code via camera
│       └── ScoreButtonsConfigSheet.swift  # Config dos botoes de score
│
└── Resources/
    ├── Assets.xcassets               # Cores customizadas, icone
    └── GoogleService-Info.plist      # Config Firebase
```

## Funcionalidades

### Autenticacao
- Sign in with Apple (async/await via continuation)
- Email e senha (criacao de conta + login)
- Restauracao de sessao automatica

### Modos de Jogo
- **Online** — sessao compartilhada via Firestore com sync em tempo real. Jogadores entram por codigo de 5 caracteres ou QR Code.
- **Offline** — sessao local gerenciada em memoria. O host controla todos os times e scores pelo proprio dispositivo.

### Partida
- 4 cores de time: Vermelho, Azul, Verde, Amarelo
- Maximo de 2 jogadores por time
- Botoes de pontuacao configuraveis (3 a 5 botoes, multiplos de 5)
- Botao especial "Galo" (50 pontos)
- Toggle +/- para adicionar ou subtrair pontos
- Deteccao de mudancas remotas com flash + haptic feedback

### UI
- Liquid Glass (`.glassEffect`, `.glassEffectUnion`)
- Animacoes com `matchedGeometryEffect` e `contentTransition(.symbolEffect)`
- Feedback haptico via `sensoryFeedback`

## Como Rodar

1. Clone o repositorio
2. Abra `DominoScore.xcodeproj` no Xcode
3. Certifique-se de que as dependencias do SPM foram resolvidas (Firebase)
4. Configure o `GoogleService-Info.plist` com seu projeto Firebase
5. Habilite **Sign in with Apple** no target (Signing & Capabilities)
6. Build e rode no dispositivo ou simulador
