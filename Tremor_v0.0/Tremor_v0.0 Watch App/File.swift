
import Foundation
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
            }
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
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTremorSituation()
        }
    }
    
    // Stop the timer
    internal func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Update the tremor situation based on the current intensity
    private func updateTremorSituation() {
        switch tremorIntensity {
        case 0:
            tremorSituation = "No tremor"
        case 1:
            tremorSituation = "Low intensity tremor"
        case 2:
            tremorSituation = "Medium intensity tremor"
        case 3:
            tremorSituation = "High intensity tremor"
        case 4:
            tremorSituation = "Extra high intensity tremor"
        default:
            tremorSituation = "Unknown"
        }
        
        // Print the tremor intensity and situation
        print("Tremor Intensity: \(tremorIntensity)")
        print("Tremor Situation: \(tremorSituation)")
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
                    tremorDetector.startTimer() // Start the timer
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
