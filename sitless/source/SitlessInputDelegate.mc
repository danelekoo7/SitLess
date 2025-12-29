import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Input delegate for handling button presses in the widget
class SitlessInputDelegate extends WatchUi.BehaviorDelegate {

    //! Constructor
    function initialize() {
        BehaviorDelegate.initialize();
    }

    //! Handle select button press
    //! Toggles snooze mode on/off
    //! @return true if handled
    function onSelect() as Boolean {
        AlertManager.toggleSnooze();
        WatchUi.requestUpdate();
        return true;
    }

    //! Handle menu button press (long-press UP on most devices)
    //! Opens the settings menu
    //! @return true if handled
    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.SettingsTitle) as String});
        menu.addItem(new WatchUi.ToggleMenuItem(
            WatchUi.loadResource(Rez.Strings.NotificationsLabel) as String,
            {:enabled => WatchUi.loadResource(Rez.Strings.On) as String, :disabled => WatchUi.loadResource(Rez.Strings.Off) as String},
            :notifications,
            getNotificationsEnabled(),
            {}
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.StepGoalLabel) as String,
            getMinSteps().toString(),
            :stepGoal,
            {}
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.TimeWindowLabel) as String,
            getTimeWindow().toString() + " min",
            :timeWindow,
            {}
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.StartHourLabel) as String,
            formatHour(getStartHour()),
            :startHour,
            {}
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.EndHourLabel) as String,
            formatHour(getEndHour()),
            :endHour,
            {}
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.SnoozeDurationLabel) as String,
            getSnoozeDuration().toString() + " min",
            :snoozeDuration,
            {}
        ));
        WatchUi.pushView(menu, new SitlessMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    //! Format hour for display (e.g., "7:00")
    private function formatHour(hour as Number) as String {
        return hour.toString() + ":00";
    }

    //! Read current minSteps value from Properties
    //! @return current step goal value
    private function getMinSteps() as Number {
        try {
            var value = Application.Properties.getValue("minSteps");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading minSteps in delegate");
        }
        return 50;
    }

    //! Read current timeWindow value from Properties
    //! @return current time window value in minutes
    private function getTimeWindow() as Number {
        try {
            var value = Application.Properties.getValue("timeWindow");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading timeWindow in delegate");
        }
        return 60;
    }

    //! Read current startHour value from Properties
    //! @return current start hour value (0-23)
    private function getStartHour() as Number {
        try {
            var value = Application.Properties.getValue("startHour");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading startHour in delegate");
        }
        return 7;
    }

    //! Read current endHour value from Properties
    //! @return current end hour value (0-23)
    private function getEndHour() as Number {
        try {
            var value = Application.Properties.getValue("endHour");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading endHour in delegate");
        }
        return 21;
    }

    //! Read current notificationsEnabled value from Properties
    //! @return true if notifications are enabled
    private function getNotificationsEnabled() as Boolean {
        try {
            var value = Application.Properties.getValue("notificationsEnabled");
            if (value != null && value instanceof Boolean) {
                return value as Boolean;
            }
        } catch (e) {
            System.println("SitLess: Error reading notificationsEnabled in delegate");
        }
        return true;
    }

    //! Read current snoozeDuration value from Properties
    //! @return current snooze duration value in minutes
    private function getSnoozeDuration() as Number {
        try {
            var value = Application.Properties.getValue("snoozeDuration");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading snoozeDuration in delegate");
        }
        return 60;
    }
}
