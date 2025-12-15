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

        // Keep only last 15 samples (~75 min of data)
        var maxSamples = 15;
        while (samples.size() > maxSamples) {
            samples = samples.slice(1, null) as Array<Application.PropertyValueType>;
        }

        // Save updated buffer to storage
        Storage.setValue("stepBuffer", samples as Application.PropertyValueType);

        // Log for debugging (visible in simulator)
        System.println("SitLess BG: Added sample - steps=" + steps + ", samples=" + samples.size());

        // Exit and pass data to main app
        // Data will be delivered to onBackgroundData() if app is active
        var result = {
            "steps" => steps as Application.PropertyValueType,
            "sampleCount" => samples.size() as Application.PropertyValueType,
            "timestamp" => now.value() as Application.PropertyValueType
        } as Dictionary<Application.PropertyKeyType, Application.PropertyValueType>;

        Background.exit(result as Application.PersistableType);
    }
}
