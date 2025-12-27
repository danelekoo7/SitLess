import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Application;
import Toybox.Application.Storage;

// Background service delegate for periodic step monitoring
// Runs approximately every 5 minutes to collect step samples
(:background)
class SitlessServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    // Called when temporal event fires (every ~5 minutes)
    function onTemporalEvent() as Void {
        // Get current step count
        var info = ActivityMonitor.getInfo();
        var steps = 0;
        if (info != null && info.steps != null) {
            steps = info.steps as Number;
        }

        // Get current timestamp
        var now = Time.now();

        // Load existing buffer from storage
        var storedData = Storage.getValue("stepBuffer") as Array<Application.PropertyValueType>?;
        var samples = [] as Array<Application.PropertyValueType>;

        if (storedData != null) {
            samples = storedData;
        }

        // Add new sample as Dictionary with PropertyValueType compatible types
        var newSample = {
            "time" => now.value() as Application.PropertyValueType,
            "steps" => steps as Application.PropertyValueType
        } as Dictionary<Application.PropertyKeyType, Application.PropertyValueType>;
        samples.add(newSample);

        // Keep only required number of samples based on timeWindow setting
        var maxSamples = 15; // default
        var storedMaxSamples = Storage.getValue("maxSamples");
        if (storedMaxSamples != null && storedMaxSamples instanceof Number) {
            maxSamples = storedMaxSamples as Number;
        }
        while (samples.size() > maxSamples) {
            samples = samples.slice(1, null) as Array<Application.PropertyValueType>;
        }

        // Save updated buffer to storage
        Storage.setValue("stepBuffer", samples as Application.PropertyValueType);

        // Log for debugging (visible in simulator)
        System.println("SitLess BG: Added sample - steps=" + steps + ", samples=" + samples.size());

        // Calculate steps in window and check if alert should be triggered
        var stepsInWindow = calculateStepsInWindow(samples);
        System.println("SitLess BG: Steps in window = " + stepsInWindow);

        // Determine if alert should be triggered
        var shouldTriggerAlert = false;
        if (stepsInWindow >= 0) {
            shouldTriggerAlert = AlertManager.shouldAlert(stepsInWindow);
        }

        // If alert should be triggered, request application wake
        // This displays a notification asking user to open the app
        // On some devices, this also triggers a tone/vibration
        if (shouldTriggerAlert) {
            System.println("SitLess BG: Requesting application wake");
            Background.requestApplicationWake("Time to move!");
        }

        // CRITICAL: Register next temporal event BEFORE exiting
        // Temporal events are one-shot - must re-register each time
        registerNextTemporalEvent();

        // Exit and pass data to main app
        // Data will be delivered to onBackgroundData() if app is active
        // Include shouldAlert flag so foreground can trigger vibration (if app was already open)
        var result = {
            "steps" => steps as Application.PropertyValueType,
            "sampleCount" => samples.size() as Application.PropertyValueType,
            "timestamp" => now.value() as Application.PropertyValueType,
            "shouldAlert" => shouldTriggerAlert as Application.PropertyValueType
        } as Dictionary<Application.PropertyKeyType, Application.PropertyValueType>;

        Background.exit(result as Application.PersistableType);
    }

    // Calculate steps taken within the configured time window
    // Returns -1 if not enough samples to calculate
    private function calculateStepsInWindow(samples as Array<Application.PropertyValueType>) as Number {
        if (samples.size() < 2) {
            return -1; // Not enough data
        }

        // Get time window from storage (set by main app from settings)
        var timeWindowMinutes = 60; // default
        var storedTimeWindow = Storage.getValue("timeWindow");
        if (storedTimeWindow != null && storedTimeWindow instanceof Number) {
            timeWindowMinutes = storedTimeWindow as Number;
        }

        var now = Time.now();
        var windowStart = now.subtract(new Time.Duration(timeWindowMinutes * 60));
        var windowStartValue = windowStart.value();

        // Find oldest sample within window and newest sample
        var oldestStepsInWindow = -1 as Number;
        var newestSteps = -1 as Number;

        for (var i = 0; i < samples.size(); i++) {
            var sample = samples[i] as Dictionary<Application.PropertyKeyType, Application.PropertyValueType>;
            var sampleTime = sample["time"] as Number;
            var sampleSteps = sample["steps"] as Number;

            if (sampleTime >= windowStartValue) {
                if (oldestStepsInWindow < 0) {
                    oldestStepsInWindow = sampleSteps;
                }
                newestSteps = sampleSteps;
            }
        }

        if (oldestStepsInWindow < 0 || newestSteps < 0) {
            return -1; // No samples in window
        }

        // Handle midnight reset (daily step count resets to 0)
        var stepsInWindow = newestSteps - oldestStepsInWindow;
        if (stepsInWindow < 0) {
            // Midnight reset occurred, just use newest value
            stepsInWindow = newestSteps;
        }

        return stepsInWindow;
    }

    // Register for next temporal event (5 minutes from now)
    private function registerNextTemporalEvent() as Void {
        // 5 minutes in seconds - minimum interval enforced by Connect IQ
        var interval = new Time.Duration(5 * 60);
        var nextEvent = Time.now().add(interval);
        try {
            Background.registerForTemporalEvent(nextEvent);
            System.println("SitLess BG: Registered next event in 5 min");
        } catch (e) {
            System.println("SitLess BG: Failed to register next event");
        }
    }
}
