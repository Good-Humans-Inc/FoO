import CoreHaptics
import UIKit

// A manager to handle playing custom haptic patterns.
class HapticManager {
    private var engine: CHHapticEngine?

    // Initialize the haptic engine. Fails if the device doesn't support Core Haptics.
    init?() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device does not support Core Haptics.")
            return nil
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // The engine can stop for various reasons (e.g., backgrounding).
            // This closure restarts it when needed.
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
            engine?.resetHandler = { [weak self] in
                print("Haptic engine reset. Restarting...")
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Haptic engine creation error: \(error)")
            return nil
        }
    }

    /// Plays a haptic pattern that gradually increases in intensity and slows down over 2 seconds.
    func playRampUp() {
        guard let engine = engine else { return }

        var events = [CHHapticEvent]()
        let duration: TimeInterval = 1.0 // Shortened for quicker feedback
        
        // A continuous event that lasts for the full duration
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let continuousEvent = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: duration
        )
        events.append(continuousEvent)
        
        // A curve that ramps intensity from low to high
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: 0.2),
                .init(relativeTime: duration, value: 1.0)
            ],
            relativeTime: 0
        )
        
        // A curve that ramps sharpness from high (crisp) to low (dull)
        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                .init(relativeTime: 0, value: 1.0),
                .init(relativeTime: duration, value: 0.5)
            ],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: [intensityCurve, sharpnessCurve])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play custom haptic pattern: \(error)")
        }
    }
    
    /// Plays a short, sharp, and celebratory haptic pattern for special reveals.
    func playSpecialReveal() {
        guard let engine = engine else { return }

        // 1. A very sharp, intense tap.
        let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness1], relativeTime: 0)

        // 2. A softer, fading rumble immediately after.
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharpness2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        let event2 = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity2, sharpness2],
            relativeTime: 0.05, // Starts just after the first tap
            duration: 0.5
        )
        
        // 3. A parameter curve to make the rumble fade out.
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: 0.6),
                .init(relativeTime: 0.5, value: 0)
            ],
            relativeTime: 0.05 // Apply this curve to the continuous event
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event1, event2], parameterCurves: [intensityCurve])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play special reveal haptic pattern: \(error)")
        }
    }
}