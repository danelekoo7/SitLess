import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;
import Toybox.Activity;
import Toybox.Attention;
import Toybox.SensorHistory;
import Toybox.Application.Storage;

//! Module responsible for alert decision logic
//! Determines whether an alert should be triggered based on step count and settings
//! Note: shouldAlert() can run in background context, but triggerAlert() must run in foreground
(:background)
module AlertManager {

    //! Determines if an alert should be triggered
    //! @param stepsInWindow Number of steps in the current time window
    //! @return true if alert should be triggered, false otherwise
    function shouldAlert(stepsInWindow as Number) as Boolean {
        // 1. Check if notifications are enabled
        if (!SettingsManager.getNotificationsEnabled()) {
            System.println("SitLess: Alert skipped - notifications disabled");
            return false;
        }

        // 2. Check if snooze is active
        if (isInSnoozeMode()) {
            System.println("SitLess: Alert skipped - snooze active");
            return false;
        }

        // 3. Check if we're within active hours
        if (!isWithinActiveHours()) {
            System.println("SitLess: Alert skipped - outside active hours");
            return false;
        }

        // 4. Check exclusion conditions (DND, activity in progress, sleep mode)
        if (isExcludedByConditions()) {
            return false;
        }

        // 5. Check if steps are below threshold
        var minSteps = SettingsManager.getMinSteps();
        var shouldTrigger = stepsInWindow < minSteps;

        if (shouldTrigger) {
            System.println("SitLess: Alert triggered - " + stepsInWindow + " < " + minSteps);
        }

        return shouldTrigger;
    }

    //! Checks if any exclusion condition is active that should block alerts
    //! @return true if alerts should be blocked, false if alerts are allowed
    function isExcludedByConditions() as Boolean {
        var deviceSettings = System.getDeviceSettings();

        // 1. Check Do Not Disturb mode
        if (deviceSettings.doNotDisturb) {
            System.println("SitLess: Alert blocked - Do Not Disturb is active");
            return true;
        }

        // 2. Check if activity recording is in progress
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null) {
            var timerState = activityInfo.timerState;
            // TIMER_STATE_OFF (0) means no active recording
            // Any other state (ON=3, STOPPED=1, PAUSED=2) means activity in progress
            if (timerState != null && timerState != Activity.TIMER_STATE_OFF) {
                System.println("SitLess: Alert blocked - activity recording in progress (timerState: " + timerState + ")");
                return true;
            }
        }

        // 3. Check sleep mode (if available on device)
        // Note: Sleep mode detection via System.getDeviceSettings() is limited
        // Some devices expose this through different APIs
        if (deviceSettings has :isSleepModeEnabled) {
            if (deviceSettings.isSleepModeEnabled) {
                System.println("SitLess: Alert blocked - sleep mode is active");
                return true;
            }
        }

        // 4. Check if watch is off-wrist using heart rate history
        // Use recent HR samples instead of instant reading - more reliable
        // Instant HR is often null during sensor warmup, but history shows pattern
        if (isLikelyOffWrist()) {
            System.println("SitLess: Alert blocked - likely off-wrist (no recent HR)");
            return true;
        }

        return false;
    }

    //! Checks if watch is likely off-wrist based on heart rate history
    //! More reliable than instant HR reading - looks for pattern of no readings
    //! @return true if likely off-wrist, false otherwise
    function isLikelyOffWrist() as Boolean {
        // Check if SensorHistory is available on this device
        if (!(Toybox has :SensorHistory)) {
            return false; // Can't determine, assume on-wrist
        }

        if (!(SensorHistory has :getHeartRateHistory)) {
            return false; // HR history not available
        }

        try {
            // Get last 10 minutes of HR data
            var hrIterator = SensorHistory.getHeartRateHistory({
                :period => 10 * 60  // 10 minutes in seconds
            });

            // Count valid HR samples vs invalid (255 = no reading)
            var validSamples = 0;
            var totalSamples = 0;
            var maxSamples = 20; // Check up to 20 samples

            var sample = hrIterator.next();
            while (sample != null && totalSamples < maxSamples) {
                totalSamples++;
                var hr = sample.data;
                // HR of 255 means invalid/no reading, valid HR is typically 30-220
                if (hr != null && hr != 255 && hr > 0) {
                    validSamples++;
                }
                sample = hrIterator.next();
            }

            // If we have samples but none are valid, watch is likely off-wrist
            // Need at least 5 samples to make a decision
            if (totalSamples >= 5 && validSamples == 0) {
                return true;
            }

            return false;
        } catch (e) {
            System.println("SitLess: Error checking HR history");
            return false; // On error, assume on-wrist
        }
    }

    //! Checks if current time is within configured active hours
    //! @return true if within active hours, false otherwise
    function isWithinActiveHours() as Boolean {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var currentHour = now.hour as Number;
        var startHour = SettingsManager.getStartHour();
        var endHour = SettingsManager.getEndHour();

        // Handle the case where startHour <= endHour (normal range, e.g., 7-21)
        // and where startHour > endHour (overnight range, e.g., 22-6)
        if (startHour <= endHour) {
            // Normal range: active if currentHour >= start AND < end
            return currentHour >= startHour && currentHour < endHour;
        } else {
            // Overnight range: active if currentHour >= start OR < end
            return currentHour >= startHour || currentHour < endHour;
        }
    }

    //! Checks if snooze mode is currently active
    //! @return true if snooze is active, false otherwise
    function isInSnoozeMode() as Boolean {
        try {
            var snoozeUntil = Storage.getValue("snoozeUntil");
            if (snoozeUntil != null && snoozeUntil instanceof Number) {
                var now = Time.now().value();
                return now < (snoozeUntil as Number);
            }
        } catch (e) {
            System.println("SitLess: Error reading snooze state");
        }
        return false;
    }

    //! Activates snooze mode for the configured duration
    //! Saves the snooze end time to Storage
    function activateSnooze() as Void {
        var durationMinutes = SettingsManager.getSnoozeDuration();
        var snoozeUntil = Time.now().value() + (durationMinutes * 60);
        try {
            Storage.setValue("snoozeUntil", snoozeUntil);
            System.println("SitLess: Snooze activated for " + durationMinutes + " minutes");
        } catch (e) {
            System.println("SitLess: Error saving snooze state");
        }
    }

    //! Gets the remaining snooze time in minutes
    //! @return remaining minutes, or 0 if snooze is not active
    function getSnoozeRemainingMinutes() as Number {
        try {
            var snoozeUntil = Storage.getValue("snoozeUntil");
            if (snoozeUntil != null && snoozeUntil instanceof Number) {
                var now = Time.now().value();
                var remaining = (snoozeUntil as Number) - now;
                if (remaining > 0) {
                    return (remaining / 60) + 1;  // Round up
                }
            }
        } catch (e) {
            System.println("SitLess: Error reading snooze remaining time");
        }
        return 0;
    }

    //! Triggers a gentle vibration alert
    //! Uses a soft pattern: two short pulses with a pause between them
    //! NOTE: This function must be called from foreground context only (not from background service)
    //! The Attention API is not available in background context
    (:typecheck(disableBackgroundCheck))
    function triggerAlert() as Void {
        // Check if Attention.vibrate is available on this device
        if (Attention has :vibrate) {
            // Gentle vibration pattern: short pulse, pause, short pulse
            // 50% intensity to avoid being too aggressive
            var vibeData = [
                new Attention.VibeProfile(50, 200),  // 50% intensity, 200ms
                new Attention.VibeProfile(0, 100),   // pause 100ms
                new Attention.VibeProfile(50, 200)   // 50% intensity, 200ms
            ] as Array<Attention.VibeProfile>;

            Attention.vibrate(vibeData);
            System.println("SitLess: Vibration alert triggered");
        } else {
            System.println("SitLess: Vibration not available on this device");
        }
    }

}
