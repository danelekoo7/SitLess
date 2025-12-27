import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;

//! Module responsible for alert decision logic
//! Determines whether an alert should be triggered based on step count and settings
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

        // 3. Check if steps are below threshold
        var minSteps = SettingsManager.getMinSteps();
        var shouldTrigger = stepsInWindow < minSteps;

        if (shouldTrigger) {
            System.println("SitLess: Alert triggered - " + stepsInWindow + " < " + minSteps);
        }

        return shouldTrigger;
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

}
