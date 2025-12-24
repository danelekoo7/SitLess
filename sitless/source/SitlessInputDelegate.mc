import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Input delegate for handling button presses in the widget
class SitlessInputDelegate extends WatchUi.BehaviorDelegate {

    //! Constructor
    function initialize() {
        BehaviorDelegate.initialize();
    }

    //! Handle menu button press (long-press UP on most devices)
    //! Opens the settings menu
    //! @return true if handled
    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.SettingsTitle) as String});
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.StepGoalLabel) as String,
            getMinSteps().toString(),
            :stepGoal,
            {}
        ));
        WatchUi.pushView(menu, new SitlessMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
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
            // Fall through to default
        }
        return 50;
    }
}
