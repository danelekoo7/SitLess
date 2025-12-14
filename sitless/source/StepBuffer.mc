import Toybox.Lang;
import Toybox.Time;

// StepBuffer maintains a rolling window of step samples
// to calculate steps taken within a configurable time period
class StepBuffer {
    private var _samples as Array<Dictionary>;
    private var _maxSamples as Number;

    // Initialize buffer with maximum number of samples to keep
    // Default: 15 samples (5min interval * 15 = 75min coverage for 60min window)
    function initialize(maxSamples as Number) {
        _samples = [] as Array<Dictionary>;
        _maxSamples = maxSamples;
    }

    // Add a new step sample with timestamp
    // totalSteps: cumulative daily step count from ActivityMonitor
    // time: timestamp of the sample
    function addSample(totalSteps as Number, time as Time.Moment) as Void {
        var sample = {
            "time" => time,
            "steps" => totalSteps
        } as Dictionary;

        _samples.add(sample);

        // Remove old samples if we exceed max
        while (_samples.size() > _maxSamples) {
            _samples = _samples.slice(1, null) as Array<Dictionary>;
        }
    }

    // Calculate steps taken within the specified time window
    // windowMinutes: size of the rolling window in minutes
    // Returns: number of steps in the window, or -1 if insufficient data
    function getStepsInWindow(windowMinutes as Number) as Number {
        if (_samples.size() < 2) {
            return -1; // Not enough data
        }

        var now = Time.now();
        var windowStart = now.subtract(new Time.Duration(windowMinutes * 60));

        // Find the oldest sample within the window
        var oldestInWindow = null as Dictionary?;
        var newestSample = _samples[_samples.size() - 1] as Dictionary;

        var windowStartValue = windowStart.value();
        for (var i = 0; i < _samples.size(); i++) {
            var sample = _samples[i] as Dictionary;
            var sampleTime = sample["time"] as Time.Moment;

            if (sampleTime.value() >= windowStartValue) {
                if (oldestInWindow == null) {
                    oldestInWindow = sample;
                }
            }
        }

        if (oldestInWindow == null) {
            // All samples are older than the window, use the most recent one
            oldestInWindow = _samples[_samples.size() - 2] as Dictionary;
        }

        var oldSteps = oldestInWindow["steps"] as Number;
        var newSteps = newestSample["steps"] as Number;

        // Handle midnight reset (daily steps reset to 0)
        if (newSteps < oldSteps) {
            return newSteps; // After midnight, just return current steps
        }

        return newSteps - oldSteps;
    }

    // Get the number of samples currently stored
    function getSampleCount() as Number {
        return _samples.size();
    }

    // Get the most recent step count (for display purposes)
    function getLatestSteps() as Number {
        if (_samples.size() == 0) {
            return 0;
        }
        var latest = _samples[_samples.size() - 1] as Dictionary;
        return latest["steps"] as Number;
    }

    // Clear all samples (e.g., after device restart)
    function clear() as Void {
        _samples = [] as Array<Dictionary>;
    }

    // Convert buffer to array for storage persistence
    function toArray() as Array<Dictionary> {
        return _samples;
    }

    // Restore buffer from stored array
    function fromArray(data as Array<Dictionary>) as Void {
        _samples = data;
        // Trim if needed
        while (_samples.size() > _maxSamples) {
            _samples = _samples.slice(1, null) as Array<Dictionary>;
        }
    }
}
