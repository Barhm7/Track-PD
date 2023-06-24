import SwiftUI
import CoreMotion

class TremorDetector {
    let motionManager = CMMotionManager()
    var tremorIntensity: Int = 0 // Current tremor intensity
    var tremorSituation: String = "" // Tremor situation
    var timer: Timer? // Timer variable

    func startTremorDetection() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1 // Adjust the update interval as needed

            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                // Retrieve accelerometer data
                let acceleration = data.userAcceleration

                // Calculate the magnitude of acceleration
                let accelerationMagnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))

                // Perform tremor detection based on thresholds
                let extraHighThreshold: Double = 1.2
                let highThreshold: Double = 0.8
                let mediumThreshold: Double = 0.5

                if accelerationMagnitude > extraHighThreshold {
                    // Extra high intensity tremor detected
                    self.tremorIntensity = 4
                } else if accelerationMagnitude > highThreshold {
                    // High intensity tremor detected
                    self.tremorIntensity = 3
                } else if accelerationMagnitude > mediumThreshold {
                    // Medium intensity tremor detected
                    self.tremorIntensity = 2
                } else {
                    // Low intensity tremor or no tremor detected
                    self.tremorIntensity = accelerationMagnitude > 0 ? 1 : 0
                }
                
                // Print the tremor intensity and situation
                print("Tremor Intensity: \(self.tremorIntensity)")
                print("Tremor Situation: \(self.tremorSituation)")
                
                // Send tremor data to Python server and Firestore
                self.sendTremorDataToServer()
            }
            
            // Start the timer for periodic updates
            startTimer()
        } else {
            print("Device motion is not available.")
        }
    }

    func stopTremorDetection() {
        motionManager.stopDeviceMotionUpdates()
        stopTimer()
    }

    // Start the timer
    internal func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateTremorSituation()
        }
    }

    // Stop the timer
    internal func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Update the tremor situation based on the current intensity and add the time in minutes
    private func updateTremorSituation() {
        let currentTime = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        tremorSituation = "Tremor detected at \(currentTime)"
    }

    func sendTremorDataToServer() {
        let tremorData: [String: Any] = [
            "intensity": tremorIntensity,
            "situation": tremorSituation
        ]

        guard let url = URL(string: "http://172.20.10.2:8880/tremor") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tremorData, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error creating JSON data: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending tremor data: \(error)")
            } else if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    print("Tremor data sent successfully")
                } else {
                    print("Unexpected status code: \(response.statusCode)")
                }
            }
        }.resume()
    }
}

struct ContentView: View {
    @State private var isDetectionStarted = false
    let tremorDetector = TremorDetector()

    var body: some View {
        VStack {
            Text("Tremor Detection")
                .font(.title)
                .padding()

            if !isDetectionStarted {
                Button(action: {
                    tremorDetector.startTremorDetection()
                    isDetectionStarted = true
                }) {
                    Text("Start Detection")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if isDetectionStarted {
                Button(action: {
                    tremorDetector.stopTremorDetection()
                    isDetectionStarted = false
                }) {
                    Text("Stop Detection")
                        .font(.headline)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Text("Tremor Intensity: \(tremorDetector.tremorIntensity)")
                    .font(.headline)
                    .padding()

                Text("Tremor Situation: \(tremorDetector.tremorSituation)")
                    .font(.headline)
                    .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
