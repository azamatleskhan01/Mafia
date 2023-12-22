import SwiftUI
import AVKit
import AVFoundation

protocol TimeState {
    var imageName: String { get }
    mutating func toggleState()
}

struct DayState: TimeState {
    var imageName: String { return "basqa" }
    mutating func toggleState() {}
}

struct NightState: TimeState {
    var imageName: String { return "ALAday" }
    mutating func toggleState() {}
}

class SongPlayer {
    static let shared = SongPlayer() // Singleton instance
    private var player: AVPlayer?
    
    private init() {} // Private initializer for Singleton
    
    func playSong(withURL url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print("Failed to set audio session category.")
        }
        
        player?.play()
    }
    
    func stop() {
        player?.pause()
        player = nil
    }
}

struct ContentView: View {
    @State private var pressCount = 0
    @State private var currentState: TimeState = DayState()
    @State private var showIntroduction = false
    @State private var isMusicPlaying = false
    
    let songPlayer = SongPlayer.shared
    
    var body: some View {
        VStack {
            if pressCount == 0 {
                IntroductionView()
            } else {
                ZStack {
                    Image(currentState.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 1700, height: currentState.imageName == "ALAday" ? 816 : 816)
                        .animation(Animation.easeInOut(duration: 1.0))
                    
                    if currentState.imageName == "ALAday" {
                        Text("Welcome to Almaty's ruthless underworld, where power is the \nultimate currency\nand loyalty is a luxury few can afford.\nIn this city of secrets, alliances are forged in shadows\nand broken with a single betrayal.\nAre you cunning enough to rise through the ranks\nand become the unchallenged master of the Kazakh mafia?\nRules of the Mafia Game:\n1. Roles: Assign roles such as Mafia, Detective, \nDoctor, and Innocent Civilians.\n2. Objective: The Mafia's goal is to eliminate all civilians, \nwhile civilians aim to identify and eliminate \nthe Mafia.\n3. Night Phase: The Mafia chooses a victim to eliminate, \nthe Detective investigates a player's allegiance, and the \nDoctor protects a chosen player.\n4. Day Phase: Players discuss and vote to eliminate who they \nbelieve is Mafia. The player with the most votes is removed.\n5. Cycle Continues: The game alternates between night \nand day phases until either all Mafia are eliminated \nor they outnumber the civilians.\n6. Strategy: Deception, deduction, and teamwork are crucial. Mafia \nmust conceal their identity, while civilians work together to \nuncover the Mafia.\n7. Win Conditions: Mafia win if they equal or outnumber civilians; \ncivilians win if they eliminate all Mafia members.\n8. Fair Play: No revealing roles if eliminated, \nand no communication during the night phase")
                            .multilineTextAlignment(.leading)
                            .padding()
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .offset(x: 1, y: 10)
                    }
                }
            }
            
            HStack {
                Button(action: {
                    withAnimation {
                        self.pressCount += 1
                        
                        if self.pressCount == 3 {
                            self.showIntroduction.toggle()
                        }
                        
                        self.toggleState()
                    }
                }) {
                    Text("Kettik barin tasta")
                        .padding()
                        .foregroundColor(.red)
                        .background(Color.black)
                        .cornerRadius(300)
                }
                .padding()
                
                if currentState.imageName == "basqa" {
                    if !isMusicPlaying {
                        Button(action: {
                            if let musicURL = Bundle.main.url(forResource: "Ala", withExtension: "mp3") {
                                self.songPlayer.playSong(withURL: musicURL)
                                self.isMusicPlaying = true
                            }
                        }) {
                            Text("Play Music")
                                .padding()
                                .foregroundColor(.red)
                                .background(Color.black)
                                .cornerRadius(300)
                        }
                        .padding()
                    } else {
                        Button(action: {
                            self.songPlayer.stop()
                            self.isMusicPlaying = false
                        }) {
                            Text("Stop Music")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(300)
                        }
                        .padding()
                    }
                }
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showIntroduction) {
            ThirdContentView()
        }
    }
    
    private func toggleState() {
        if currentState is NightState && currentState.imageName == "basqa" {
            if let musicURL = Bundle.main.url(forResource: "Ala", withExtension: "mp3") {
                songPlayer.playSong(withURL: musicURL)
                isMusicPlaying = true
            }
        } else {
            songPlayer.stop()
            isMusicPlaying = false
        }
        
        if currentState is NightState {
            currentState = DayState()
        } else {
            currentState = NightState()
        }
    }
}

struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
