import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.System;

(:background)
class sitlessApp extends Application.AppBase {
    // Step buffer instance shared across app
    // 15 samples = ~75 min coverage at 5min intervals
    // Initialized lazily to avoid background context issues
    private var _stepBuffer as StepBuffer?;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up (both foreground AND background)
    function onStart(state as Dictionary?) as Void {
        // Don't do anything here that requires foreground-only classes
        // Background service will handle its own initialization
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    // This is ONLY called for foreground app, never for background
    (:typecheck(disableBackgroundCheck))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        // Sync settings to storage for background service
        syncSettingsToStorage();

        // Load step buffer from storage (persisted by background service)
        loadStepBufferFromStorage();

        // Register for next temporal event (background service)
        registerNextTemporalEvent();

        return [new sitlessView(), new SitlessInputDelegate()] as [Views, InputDelegates];
    }

    // Get the step buffer instance (creates lazily if needed)
    (:typecheck(disableBackgroundCheck))
    function getStepBuffer() as StepBuffer {
        if (_stepBuffer == null) {
            _stepBuffer = new StepBuffer(SettingsManager.getRequiredBufferSize());
        }
        return _stepBuffer as StepBuffer;
    }

    // Sync settings to storage for background service access
    (:typecheck(disableBackgroundCheck))
    private function syncSettingsToStorage() as Void {
        var bufferSize = SettingsManager.getRequiredBufferSize();
        var timeWindow = SettingsManager.getTimeWindow();
        Storage.setValue("maxSamples", bufferSize);
        Storage.setValue("timeWindow", timeWindow);
        System.println("SitLess: Synced maxSamples=" + bufferSize + ", timeWindow=" + timeWindow);
    }

    // Return the service delegate for background processing
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new SitlessServiceDelegate()];
    }

    // Called when background service exits with data
    (:typecheck(disableBackgroundCheck))
    function onBackgroundData(data) as Void {
        if (data != null && data instanceof Dictionary) {
            var dict = data as Dictionary;
            var stepsValue = dict["steps"] as Number;
            System.println("SitLess: Received background data - steps=" + stepsValue.toString());

            // Check if alert should be triggered (vibration must happen in foreground)
            var shouldAlert = dict["shouldAlert"];
            if (shouldAlert != null && shouldAlert instanceof Boolean && shouldAlert as Boolean) {
                AlertManager.triggerAlert();
            }

            // Reload buffer from storage to get latest data
            loadStepBufferFromStorage();
            // Request UI update to show new data
            WatchUi.requestUpdate();
        }
    }

    // Register for next temporal event (5 minutes from now)
    private function registerNextTemporalEvent() as Void {
        var fiveMinutes = new Time.Duration(5 * 60);
        var nextEvent = Time.now().add(fiveMinutes);
        try {
            Background.registerForTemporalEvent(nextEvent);
            System.println("SitLess: Registered temporal event for 5 min");
        } catch (e) {
            System.println("SitLess: Failed to register temporal event");
        }
    }

    // Load step buffer data from persistent storage
    (:typecheck(disableBackgroundCheck))
    private function loadStepBufferFromStorage() as Void {
        // Ensure buffer exists
        var buffer = getStepBuffer();

        var storedData = Storage.getValue("stepBuffer");
        if (storedData != null && storedData instanceof Array) {
            var samples = storedData as Array<Dictionary>;
            // Convert stored format (time as Number) to StepBuffer format (time as Moment)
            var convertedSamples = [] as Array<Dictionary>;
            for (var i = 0; i < samples.size(); i++) {
                var sample = samples[i] as Dictionary;
                var timeValue = sample["time"];
                var steps = sample["steps"] as Number;

                // Convert timestamp back to Moment
                var timeMoment = new Time.Moment(timeValue as Number);
                convertedSamples.add({
                    "time" => timeMoment,
                    "steps" => steps
                } as Dictionary);
            }
            buffer.fromArray(convertedSamples);
            System.println("SitLess: Loaded " + convertedSamples.size() + " samples from storage");
        }
    }

}

function getApp() as sitlessApp {
    return Application.getApp() as sitlessApp;
}