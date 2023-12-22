import SwiftUI

struct IntroductionView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Image("Mafia")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 680, height: 500)
                
                Text("Welcome to My Game")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white) // Set text color to white
                    .padding()
                
                Text("Get ready to exciting adventure to Almaty🍷")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red) // Set text color to white
                    .padding()
                
                NavigationLink(destination: ContentView()) { // Replace GameView() with your game view
                    Text("")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                }
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
           
        }
        .navigationBarHidden(true) // Hide navigation bar if using NavigationView
    }
}

struct IntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionView()
    }
}
