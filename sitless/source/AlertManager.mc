import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;
import Toybox.Activity;
import Toybox.Sensor;
import Toybox.Attention;

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

        // 2. Check if we're within active hours
        if (!isWithinActiveHours()) {
            System.println("SitLess: Alert skipped - outside active hours");
            return false;
        }

        // 3. Check exclusion conditions (DND, activity in progress, sleep mode)
        if (isExcludedByConditions()) {
            return false;
        }

        // 4. Check if steps are below threshold
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

        // 4. Check if watch is off-wrist using HR sensor (best effort)
        // If HR sensor returns null, the watch is likely not on the wrist
        // This helps avoid alerts while charging or when watch is on a desk
        // Note: HR may also be null briefly when sensor is "warming up"
        var sensorInfo = Sensor.getInfo();
        if (sensorInfo != null && sensorInfo.heartRate == null) {
            System.println("SitLess: Alert blocked - likely off-wrist (no HR reading)");
            return true;
        }

        return false;
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
