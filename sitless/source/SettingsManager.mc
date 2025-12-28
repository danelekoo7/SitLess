import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.System;

//! Centralized settings management module
//! Provides type-safe access to all application settings with defaults and validation
//! Must be available in background context for AlertManager to use
(:background)
module SettingsManager {
    // Default values
    const DEFAULT_NOTIFICATIONS_ENABLED = true;
    const DEFAULT_MIN_STEPS = 50;
    const DEFAULT_TIME_WINDOW = 60;
    const DEFAULT_START_HOUR = 7;
    const DEFAULT_END_HOUR = 21;
    const DEFAULT_SNOOZE_DURATION = 60;

    //! Get notifications enabled setting
    //! @return true if notifications are enabled
    function getNotificationsEnabled() as Boolean {
        try {
            var value = Properties.getValue("notificationsEnabled");
            if (value != null && value instanceof Boolean) {
                return value as Boolean;
            }
        } catch (e) {
            System.println("SitLess: Error reading notificationsEnabled");
        }
        return DEFAULT_NOTIFICATIONS_ENABLED;
    }

    //! Get minimum steps goal
    //! @return step goal value (10-500)
    function getMinSteps() as Number {
        var value = getNumberSetting("minSteps", DEFAULT_MIN_STEPS);
        if (value < 10) { return 10; }
        if (value > 500) { return 500; }
        return value;
    }

    //! Get time window in minutes
    //! @return time window value (30-120)
    function getTimeWindow() as Number {
        var value = getNumberSetting("timeWindow", DEFAULT_TIME_WINDOW);
        if (value < 30) { return 30; }
        if (value > 120) { return 120; }
        return value;
    }

    //! Get active hours start
    //! @return start hour (0-23)
    function getStartHour() as Number {
        var value = getNumberSetting("startHour", DEFAULT_START_HOUR);
        if (value < 0) { return 0; }
        if (value > 23) { return 23; }
        return value;
    }

    //! Get active hours end
    //! @return end hour (0-23)
    function getEndHour() as Number {
        var value = getNumberSetting("endHour", DEFAULT_END_HOUR);
        if (value < 0) { return 0; }
        if (value > 23) { return 23; }
        return value;
    }

    //! Get snooze duration in minutes
    //! @return snooze duration (10-120)
    function getSnoozeDuration() as Number {
        var value = getNumberSetting("snoozeDuration", DEFAULT_SNOOZE_DURATION);
        if (value < 10) { return 10; }
        if (value > 120) { return 120; }
        return value;
    }

    //! Calculate required buffer size based on time window
    //! Buffer needs enough samples to cover the time window at 5min intervals
    //! @return number of samples needed
    function getRequiredBufferSize() as Number {
        var timeWindow = getTimeWindow();
        return (timeWindow / 5) + 3;  // +3 for safety margin
    }

    //! Read a numeric setting from Properties
    //! @param key The property key to read
    //! @param defaultValue The default value if reading fails
    //! @return The setting value or default
    function getNumberSetting(key as String, defaultValue as Number) as Number {
        try {
            var value = Properties.getValue(key);
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading setting " + key);
        }
        return defaultValue;
    }
}
