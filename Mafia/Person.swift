import SwiftUI

enum Role {
    case civilian
    case mafia
    case police
    case doctor
    // Add more roles as needed
}

protocol PlayerDecorator: AnyObject {
    var decoratedPlayer: Person { get }
    func handleAction()
}

class RoleModifierDecorator: PlayerDecorator {
    private var basePlayer: Person

    init(player: Person) {
        self.basePlayer = player
    }

    var decoratedPlayer: Person {
        return basePlayer
    }

    func handleAction() {
        if basePlayer.id > 3 {
            basePlayer.role = .police
        }
    }
}

class Person: ObservableObject, Identifiable, Equatable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }

    let id: Int
    @Published var role: Role
    @Published var isAlive: Bool
    @Published var vote: Int?
    @Published var voteCount: Int = 0

    init(id: Int, role: Role, isAlive: Bool = true) {
        self.id = id
        self.role = role
        self.isAlive = isAlive
        self.vote = nil
    }

    func receiveVote() {
        voteCount += 1
    }
}

class Doctor: Person {
    @Published var savedPlayer: Person?

    func heal(persons: inout [Person]) {
        let deadPlayers = persons.filter { !$0.isAlive }
        if let randomDeadPlayer = deadPlayers.randomElement() {
            if randomDeadPlayer.isAlive {
                savedPlayer = nil
            } else {
                randomDeadPlayer.isAlive = true
                savedPlayer = randomDeadPlayer
            }
        } else {
            savedPlayer = nil
        }
    }
}

class Mafia: Person {
    @Published var killedPlayer: Person?

    func attack(persons: inout [Person]) {
        let alivePlayers = persons.filter { $0.isAlive && $0.role != .mafia }
        if let randomIndex = alivePlayers.indices.randomElement() {
            let randomAlivePlayer = alivePlayers[randomIndex]
            randomAlivePlayer.isAlive = false
            killedPlayer = randomAlivePlayer
        }
    }
}

class Police: Person {
    @Published var foundMafia: Person?

    func investigate(persons: [Person]) {
        let alivePlayers = persons.filter { $0.isAlive && $0.role != .police }
        let mafiaPlayers = alivePlayers.filter { $0.role == .mafia }
        
        if let randomMafia = mafiaPlayers.randomElement() {
            foundMafia = randomMafia
        } else {
            foundMafia = nil
        }
    }
}

struct ThirdContentView: View {
    @StateObject private var doctor = Doctor(id: 1, role: .doctor)
    @StateObject private var mafia = Mafia(id: 2, role: .mafia)
    @StateObject private var police = Police(id: 3, role: .police)
    @State private var players = [Person]()
    @State private var shouldShowPlayers = false
    @State private var deathMessage: String?
    @State private var savedMessage: String?
    @State private var foundMafiaMessage: String?
    @State private var isGameOver = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                Group {
                    if isGameOver {
                        GameOverView()
                            .background(Color.black)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        gameView()
                            .overlay(deathOverlay)
                            .overlay(savedOverlay)
                            .overlay(foundMafiaOverlay)
                            .onAppear {
                                startGame()
                                shouldShowPlayers = true
                            }
                            .background(Color.black)
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            }
            .navigationTitle("")
            .onChange(of: players) { _ in
                checkGameOver()
                countVotesAndEliminate()
            }
        }
    }

    @ViewBuilder
    func gameView() -> some View {
        VStack {
            Text("")
                .font(.title)
                .padding()

            if shouldShowPlayers {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(players) { player in
                            VStack {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.red)
                                Text(displayPlayerInfo(player))
                                    .foregroundColor(.red)
                                    .opacity(player.isAlive ? 1 : 0.5)
                                    .animation(.easeInOut(duration: 0.5))
                                    .padding()
                            }
                            .transition(.opacity)
                            .onTapGesture {
                                handlePlayerTap(player)
                            }
                        }
                    }
                    .padding()
                }

                HStack {
                    Button("Doctor Heal") {
                        handleDoctorAction()
                    }
                    .padding()
                    .foregroundColor(.white)
                    Button("Mafia Attack") {
                        handleMafiaAction()
                    }
                    .padding()
                    .foregroundColor(.white)
                    Button("Police Investigate") {
                        handlePoliceAction()
                    }
                    .padding()
                    .foregroundColor(.white)
                    Button("Count Votes & Eliminate") {
                        countVotesAndEliminate()
                    }
                    .padding()
                    .foregroundColor(.white)

                }
            }
        }
    }

    func startGame() {
        players = PersonFactory.createPeople()
        
        // Set the third player as a Mafia
        if players.indices.contains(2) {
            players[2].role = .mafia
        }
    }

    func displayPlayerInfo(_ player: Person) -> String {
        var info = "ID: \(player.id)"
        if player.isAlive {
            info += "\nRole: \(player.role)"
            if let vote = player.vote {
                info += "\nVote: \(vote)"
            }
        } else {
            info += "\nStatus: Eliminated"
        }
        return info
    }

    func handlePlayerTap(_ player: Person) {
        guard player.isAlive else { return }

        let target = players.filter { $0.isAlive && $0.id != player.id }.randomElement()
        guard let targetPlayer = target, targetPlayer.isAlive else { return }

        player.vote = targetPlayer.id
        targetPlayer.receiveVote()
    }

    func handleDoctorAction() {
        if let savedPlayer = doctor.savedPlayer {
            if savedPlayer.isAlive {
                savedMessage = nil
            } else {
                savedMessage = "Player \(savedPlayer.id) was saved by Doctor!"
            }
        } else {
            savedMessage = "Doctor tried to save a life but there was no one to save."
        }
        doctor.heal(persons: &players)
    }

    func handleMafiaAction() {
        if let killedPlayer = mafia.killedPlayer {
            deathMessage = "Player \(killedPlayer.id) was killed by Mafia!"
        }
        mafia.attack(persons: &players)
    }

    func handlePoliceAction() {
        if let foundMafia = police.foundMafia {
            foundMafiaMessage = "Police found Mafia: Player \(foundMafia.id)"
        } else {
            foundMafiaMessage = "Police couldn't find Mafia."
        }
        police.investigate(persons: players)
    }

    func countVotesAndEliminate() {
        var maxVotes = 0
        var playerToEliminate: Person?

        for player in players {
            if player.isAlive && player.voteCount > maxVotes {
                maxVotes = player.voteCount
                playerToEliminate = player
            }
        }

        if let player = playerToEliminate {
            player.isAlive = false
            player.voteCount = 0
            handleElimination(player)
        }
    }

    func handleElimination(_ player: Person) {
        // Custom logic for the elimination event
        print("Player \(player.id) has been eliminated!")
        // You can perform additional actions here based on the elimination.
    }

    func checkGameOver() {
        let aliveCivilians = players.filter { $0.isAlive && $0.role == .civilian }
        let aliveMafia = players.contains(where: { $0.isAlive && $0.role == .mafia })
        
        if aliveCivilians.isEmpty || !aliveMafia {
            isGameOver = true
        } else {
            isGameOver = false
        }
    }

    var deathOverlay: some View {
        Group {
            if let message = deathMessage {
                Text(message)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.deathMessage = nil
                        }
                    }
            }
        }
    }

    var savedOverlay: some View {
        Group {
            if let message = savedMessage {
                Text(message)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                    .transition(.move(edge: .top))
                    .animation(.easeInOut)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.savedMessage = nil
                        }
                    }
            }
        }
    }

    var foundMafiaOverlay: some View {
        Group {
            if let message = foundMafiaMessage {
                Text(message)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
                    .transition(.move(edge: .top))
                    .animation(.easeInOut)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.foundMafiaMessage = nil
                        }
                    }
            }
        }
    }
}

struct GameOverView: View {
    var body: some View {
        VStack {
            Text("Game Over!")
                .font(.largeTitle)
                .foregroundColor(.red)
                .padding()
            Text("All civilians have died.")
                .font(.title)
                .foregroundColor(.black)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ThirdContentView()
    }
}

struct PersonFactory {
    static func createPeople() -> [Person] {
        var people = [Person]()

        for i in 1...6 {
            let citizen = Person(id: i, role: .civilian)
            people.append(citizen)
        }

        return people
    }
}
