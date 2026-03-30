import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("burpJarPath") private var burpJarPath: String = ""
    @State private var licenseName: String = "add us on qTox, ObludaTeam"
    @State private var activationRequest: String = ""
    @State private var activationResponse: String = ""
    @State private var rotation: Double = 0
    @State private var showGuide: Bool = false
    @State private var typingTask: Task<Void, Never>? = nil
    
    let gybeOrange = Color(red: 1.0, green: 0.45, blue: 0.0)
    let strawYellow = Color(red: 0.94, green: 0.76, blue: 0.20)
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow).ignoresSafeArea()
           
            HStack {
                ActionButton(icon: "folder", action: selectBurpJar)
                    .padding(.leading, 50)
                Spacer()
                ActionButton(icon: "play.fill", action: launchBurp, disabled: burpJarPath.isEmpty)
                    .padding(.trailing, 50)
            }
            .offset(y: -95)
            
            VStack(spacing: 0) {
                // Vinyl Circle UI
                ZStack {
                    Circle()
                        .stroke(gybeOrange, lineWidth: 0.8)
                        .frame(width: 300, height: 300)
                        .opacity(0.6)
                    
                    CircularText(text: "this one was our second difficult one, and help was really needed, thanks sdmrf (github), still, with (♥ω♥ ) ~♪, obluda. ", radius: 135, color: gybeOrange)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .rotationEffect(.degrees(rotation))
                    
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 175, height: 175)
                        
                        NativeVideoPlayer(fileName: "magic")
                            .frame(width: 170, height: 170)
                            .clipShape(Circle())
                            .opacity(0.9)
                    }
                }
                .padding(.top, 25)
                .padding(.bottom, 20)
                
                // KeyGen Interactions
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("License Name").font(.system(size: 10, weight: .regular, design: .monospaced))
                            Button(action: {
                                withAnimation(.spring(response: 1.0, dampingFraction: 0.9)) { showGuide.toggle() }
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(strawYellow.opacity(0.9))
                            }.buttonStyle(PlainButtonStyle())
                        }.foregroundColor(.primary.opacity(0.8))
                        
                        TextField("", text: $licenseName).textFieldStyle(.plain).padding(8)
                            .background(.ultraThinMaterial) // Pure native refraction
                            .foregroundColor(.primary)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                            .onChange(of: licenseName) { _ in updateOutputs() }
                    }
                    
                    minimalInput(label: "Activation Request", text: $activationRequest)
                        .onChange(of: activationRequest) { _ in updateOutputs() }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(activationRequest.isEmpty ? "License Key" : "Activation Response")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.8))
                        
                        TextEditor(text: .constant(activationResponse))
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(10)
                            .frame(height: 65)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                            .scrollContentBackground(.hidden)
                    }
                }
                .padding(.horizontal, 75)
                Spacer(minLength: 20)
            }
            
            // Instructions Modal
            if showGuide {
                VisualEffectView(material: .popover, blendingMode: .withinWindow)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 35) {
                            Text("Instructions")
                                .font(.custom("Savoye LET", size: 52))
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 20) {
                                GuideStep(num: "1.", text: "Locate burpsuite_pro.jar using the file icon.")
                                GuideStep(num: "2.", text: "Launch the environment via the play icon.")
                                GuideStep(num: "3.", text: "Inject the generated License Key into Burp.")
                                GuideStep(num: "4.", text: "Select 'Manual Activation' in the Burp Suite UI.")
                                GuideStep(num: "5.", text: "Paste the request back into the Burp Suite Key.")
                                GuideStep(num: "6.", text: "Transmit the final Activation Response to Burp.")
                                GuideStep(num: "7.", text: "This is your Burp Suite Launcher from now on.")
                            }
                            .padding(.horizontal, 55)
                            .font(.custom("American Typewriter", size: 14))
                            .foregroundColor(.primary.opacity(0.9))
                            
                            Button("Dismiss") {
                                withAnimation(.spring(response: 1.0, dampingFraction: 0.9)) { showGuide = false }
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .foregroundColor(.primary)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.2), lineWidth: 0.5))
                            .buttonStyle(PlainButtonStyle())
                        }
                    )
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .frame(width: 600, height: 600)
        .onAppear {
            updateOutputs()
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) { rotation = 360 }
        }
    }
    
    private func updateOutputs() {
        typingTask?.cancel()
        typingTask = Task {
            guard let loaderURL = Bundle.main.url(forResource: "loader", withExtension: "jar") else {
                await MainActor.run { activationResponse = "loader.jar not found" }
                return
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            let req = activationRequest.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = licenseName
            let path = loaderURL.path
            
            let response = await Task.detached(priority: .userInitiated) {
                if req.isEmpty {
                    return KeyGenLogic.generateLicense(name: name, loaderPath: path)
                } else {
                    return KeyGenLogic.generateActivation(requestData: req, loaderPath: path)
                }
            }.value
            
            guard !Task.isCancelled else { return }
            await MainActor.run { self.activationResponse = response }
        }
    }
    
    private func selectBurpJar() {
        let panel = NSOpenPanel()
        panel.treatsFilePackagesAsDirectories = true
        panel.allowedContentTypes = [UTType.applicationBundle, UTType("com.sun.java-archive") ?? .data]
        if panel.runModal() == .OK { burpJarPath = panel.url?.path ?? "" }
    }
    
    private func launchBurp() {
        guard let loaderURL = Bundle.main.url(forResource: "loader", withExtension: "jar") else {
            activationResponse = "Error: loader.jar not found."
            return
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        // fetch native icon
        let appBundlePath = URL(fileURLWithPath: burpJarPath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let iconPath = appBundlePath.appendingPathComponent("Contents/Resources/app.icns").path
        
        let dockNameArg = "-Xdock:name=\"Burp Suite Professional\""
        let dockIconArg = "-Xdock:icon=\"\(iconPath)\""
        
        // execution string
        let javaCommand = "java \(dockNameArg) \(dockIconArg) --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:\"\(loaderURL.path)\" -noverify -jar \"\(burpJarPath)\""
        
        task.arguments = ["-l", "-c", javaCommand]
        
        do {
            try task.run()
        } catch {
            activationResponse = "Error: \(error.localizedDescription)"
        }
    }
    
    @ViewBuilder
    func minimalInput(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.primary.opacity(0.8))
            TextField("", text: text).textFieldStyle(.plain).padding(8)
                .background(.ultraThinMaterial) // Pure native refraction
                .foregroundColor(.primary)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
        }
    }
}

// MARK: Cute elements ლ(´ ❥ `ლ)

struct ActionButton: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let action: () -> Void
    var disabled: Bool = false
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(disabled ? .primary.opacity(0.2) : .primary.opacity(0.85))
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 5)
                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(PlainButtonStyle()).disabled(disabled)
    }
}

struct GuideStep: View {
    let num: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(num).foregroundColor(.primary.opacity(0.6)).bold()
            Text(text)
        }
    }
}

struct CircularText: View {
    let text: String
    let radius: Double
    let color: Color
    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { index, letter in
                Text(String(letter))
                    .foregroundColor(color)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) * (360 / Double(text.count))))
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct NativeVideoPlayer: NSViewRepresentable {
    let fileName: String
    func makeNSView(context: Context) -> NSView {
        let playerView = NSView()
        let cleanName = fileName.replacingOccurrences(of: ".mp4", with: "")
        guard let url = Bundle.main.url(forResource: cleanName, withExtension: "mp4") else { return playerView }
        let player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerView.layer = playerLayer
        playerView.wantsLayer = true
        player.play()
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        return playerView
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
