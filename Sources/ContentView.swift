import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "circle")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("floats")
                .font(.largeTitle)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
