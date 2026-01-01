import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! Menu delegate for handling settings menu selections
class SitlessMenuDelegate extends WatchUi.Menu2InputDelegate {

    //! Constructor
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    //! Handle menu item selection
    //! @param item The selected menu item
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :notifications) {
            // Toggle is handled automatically by ToggleMenuItem
            // We just need to save the new value
            if (item instanceof WatchUi.ToggleMenuItem) {
                var toggleItem = item as WatchUi.ToggleMenuItem;
                var newValue = toggleItem.isEnabled();
                try {
                    Properties.setValue("notificationsEnabled", newValue);
                    System.println("SitLess: Notifications " + (newValue ? "enabled" : "disabled"));
                } catch (e) {
                    System.println("SitLess: Failed to save notifications setting");
                }
            }
        } else if (id == :stepGoal) {
            openStepGoalPicker();
        } else if (id == :timeWindow) {
            openTimeWindowPicker();
        } else if (id == :startHour) {
            openStartHourPicker();
        } else if (id == :endHour) {
            openEndHourPicker();
        } else if (id == :snoozeDuration) {
            openSnoozeDurationPicker();
        }
    }

    //! Open a picker to select step goal value
    private function openStepGoalPicker() as Void {
        var currentValue = getMinSteps();
        var picker = new StepGoalPicker(currentValue);
        WatchUi.pushView(picker, new StepGoalPickerDelegate(), WatchUi.SLIDE_LEFT);
    }

    //! Open a picker to select time window value
    private function openTimeWindowPicker() as Void {
        var currentValue = getTimeWindow();
        var picker = new TimeWindowPicker(currentValue);
        WatchUi.pushView(picker, new TimeWindowPickerDelegate(), WatchUi.SLIDE_LEFT);
    }

    //! Open a picker to select start hour value
    private function openStartHourPicker() as Void {
        var currentValue = getHourValue("startHour");
        var picker = new StartHourPicker(currentValue);
        WatchUi.pushView(picker, new HourPickerDelegate("startHour"), WatchUi.SLIDE_LEFT);
    }

    //! Open a picker to select end hour value
    private function openEndHourPicker() as Void {
        var currentValue = getHourValue("endHour");
        var picker = new EndHourPicker(currentValue);
        WatchUi.pushView(picker, new HourPickerDelegate("endHour"), WatchUi.SLIDE_LEFT);
    }

    //! Open a picker to select snooze duration value
    private function openSnoozeDurationPicker() as Void {
        var currentValue = getSnoozeDuration();
        var picker = new SnoozeDurationPicker(currentValue);
        WatchUi.pushView(picker, new SnoozeDurationPickerDelegate(), WatchUi.SLIDE_LEFT);
    }

    //! Read current snoozeDuration value from Properties
    //! @return current snooze duration value in minutes
    private function getSnoozeDuration() as Number {
        try {
            var value = Properties.getValue("snoozeDuration");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading snoozeDuration in menu");
        }
        return 60;
    }

    //! Read current minSteps value from Properties
    //! @return current step goal value
    private function getMinSteps() as Number {
        try {
            var value = Properties.getValue("minSteps");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading minSteps in menu");
        }
        return 50;
    }

    //! Read current timeWindow value from Properties
    //! @return current time window value in minutes
    private function getTimeWindow() as Number {
        try {
            var value = Properties.getValue("timeWindow");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading timeWindow in menu");
        }
        return 60;
    }

    //! Read hour value from Properties
    //! @param key The property key to read
    //! @return hour value (0-23), defaults to 7 for startHour, 21 for endHour
    private function getHourValue(key as String) as Number {
        try {
            var value = Properties.getValue(key);
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading " + key + " in menu");
        }
        return key.equals("startHour") ? 7 : 21;
    }
}

//! Factory for generating step goal picker values
//! Provides values from 10 to 500 in steps of 10
class StepGoalPickerFactory extends WatchUi.PickerFactory {
    private var _min as Number;
    private var _max as Number;
    private var _step as Number;

    //! Constructor
    //! @param min Minimum value
    //! @param max Maximum value
    //! @param step Step between values
    function initialize(min as Number, max as Number, step as Number) {
        PickerFactory.initialize();
        _min = min;
        _max = max;
        _step = step;
    }

    //! Get the number of items in the factory
    //! @return number of selectable values
    function getSize() as Number {
        return ((_max - _min) / _step) + 1;
    }

    //! Get the value at the given index
    //! @param index The index of the item
    //! @return The numeric value at this index
    function getValue(index as Number) as Object? {
        return _min + (index * _step);
    }

    //! Get drawable for an item
    //! @param index The index of the item
    //! @param isSelected Whether this item is currently selected
    //! @return A Text drawable showing the value
    function getDrawable(index as Number, isSelected as Boolean) as Drawable? {
        var value = getValue(index) as Number;
        return new WatchUi.Text({
            :text => value.toString(),
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_NUMBER_MEDIUM,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }

    //! Get index for a given value
    //! @param value The value to find
    //! @return The index of the value, or 0 if not found
    function getIndexForValue(value as Number) as Number {
        if (value < _min) {
            return 0;
        }
        if (value > _max) {
            return getSize() - 1;
        }
        return (value - _min) / _step;
    }
}

//! Picker view for selecting step goal
class StepGoalPicker extends WatchUi.Picker {
    //! Constructor
    //! @param currentValue The current step goal value
    function initialize(currentValue as Number) {
        var factory = new StepGoalPickerFactory(10, 500, 10);
        var defaultIndex = factory.getIndexForValue(currentValue);

        var title = new WatchUi.Text({
            :text => WatchUi.loadResource(Rez.Strings.StepGoalLabel) as String,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
        });

        Picker.initialize({
            :title => title,
            :pattern => [factory] as Array<PickerFactory or Drawable>,
            :defaults => [defaultIndex] as Array<Number>
        });
    }
}

//! Delegate for handling step goal picker selections
class StepGoalPickerDelegate extends WatchUi.PickerDelegate {

    //! Constructor
    function initialize() {
        PickerDelegate.initialize();
    }

    //! Handle picker confirmation
    //! @param values Array of selected values from each picker column
    //! @return true if handled
    function onAccept(values as Array) as Boolean {
        var value = values[0] as Number;

        // Validate range (should already be valid from factory, but double-check)
        if (value < 10) { value = 10; }
        if (value > 500) { value = 500; }

        // Save to properties
        try {
            Properties.setValue("minSteps", value);
            System.println("SitLess: Step goal set to " + value);
        } catch (e) {
            System.println("SitLess: Failed to save step goal");
        }

        // Pop back to widget (picker + menu)
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    //! Handle picker cancellation
    //! @return true if handled
    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

//! Picker view for selecting time window
class TimeWindowPicker extends WatchUi.Picker {
    //! Constructor
    //! @param currentValue The current time window value in minutes
    function initialize(currentValue as Number) {
        // Reuse StepGoalPickerFactory with different range: 30-180, step 15
        var factory = new StepGoalPickerFactory(30, 180, 15);
        var defaultIndex = factory.getIndexForValue(currentValue);

        var title = new WatchUi.Text({
            :text => WatchUi.loadResource(Rez.Strings.TimeWindowLabel) as String,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
        });

        Picker.initialize({
            :title => title,
            :pattern => [factory] as Array<PickerFactory or Drawable>,
            :defaults => [defaultIndex] as Array<Number>
        });
    }
}

//! Delegate for handling time window picker selections
class TimeWindowPickerDelegate extends WatchUi.PickerDelegate {

    //! Constructor
    function initialize() {
        PickerDelegate.initialize();
    }

    //! Handle picker confirmation
    //! @param values Array of selected values from each picker column
    //! @return true if handled
    function onAccept(values as Array) as Boolean {
        var value = values[0] as Number;

        // Validate range
        if (value < 30) { value = 30; }
        if (value > 180) { value = 180; }

        // Save to properties
        try {
            Properties.setValue("timeWindow", value);
            System.println("SitLess: Time window set to " + value);
        } catch (e) {
            System.println("SitLess: Failed to save time window");
        }

        // Pop back to widget (picker + menu)
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    //! Handle picker cancellation
    //! @return true if handled
    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

//! Factory for generating hour picker values (0-23)
class HourPickerFactory extends WatchUi.PickerFactory {

    //! Constructor
    function initialize() {
        PickerFactory.initialize();
    }

    //! Get the number of items in the factory
    //! @return 24 hours
    function getSize() as Number {
        return 24;
    }

    //! Get the value at the given index
    //! @param index The index of the item (0-23)
    //! @return The hour value
    function getValue(index as Number) as Object? {
        return index;
    }

    //! Get drawable for an item
    //! @param index The index of the item
    //! @param isSelected Whether this item is currently selected
    //! @return A Text drawable showing the hour formatted as "H:00"
    function getDrawable(index as Number, isSelected as Boolean) as Drawable? {
        return new WatchUi.Text({
            :text => index.toString() + ":00",
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_NUMBER_MEDIUM,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }
}

//! Picker view for selecting start hour
class StartHourPicker extends WatchUi.Picker {
    //! Constructor
    //! @param currentValue The current hour value (0-23)
    function initialize(currentValue as Number) {
        var factory = new HourPickerFactory();

        var title = new WatchUi.Text({
            :text => WatchUi.loadResource(Rez.Strings.StartHourLabel) as String,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
        });

        Picker.initialize({
            :title => title,
            :pattern => [factory] as Array<PickerFactory or Drawable>,
            :defaults => [currentValue] as Array<Number>
        });
    }
}

//! Picker view for selecting end hour
class EndHourPicker extends WatchUi.Picker {
    //! Constructor
    //! @param currentValue The current hour value (0-23)
    function initialize(currentValue as Number) {
        var factory = new HourPickerFactory();

        var title = new WatchUi.Text({
            :text => WatchUi.loadResource(Rez.Strings.EndHourLabel) as String,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
        });

        Picker.initialize({
            :title => title,
            :pattern => [factory] as Array<PickerFactory or Drawable>,
            :defaults => [currentValue] as Array<Number>
        });
    }
}

//! Delegate for handling hour picker selections
class HourPickerDelegate extends WatchUi.PickerDelegate {
    private var _propertyKey as String;

    //! Constructor
    //! @param propertyKey The property key to save the value to
    function initialize(propertyKey as String) {
        PickerDelegate.initialize();
        _propertyKey = propertyKey;
    }

    //! Handle picker confirmation
    //! @param values Array of selected values from each picker column
    //! @return true if handled
    function onAccept(values as Array) as Boolean {
        var value = values[0] as Number;

        // Validate range (0-23)
        if (value < 0) { value = 0; }
        if (value > 23) { value = 23; }

        // Save to properties
        try {
            Properties.setValue(_propertyKey, value);
            System.println("SitLess: " + _propertyKey + " set to " + value);
        } catch (e) {
            System.println("SitLess: Failed to save " + _propertyKey);
        }

        // Pop back to widget (picker + menu)
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    //! Handle picker cancellation
    //! @return true if handled
    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

//! Picker view for selecting snooze duration
class SnoozeDurationPicker extends WatchUi.Picker {
    //! Constructor
    //! @param currentValue The current snooze duration value in minutes
    function initialize(currentValue as Number) {
        // Reuse StepGoalPickerFactory with range: 15-180, step 15
        var factory = new StepGoalPickerFactory(15, 180, 15);
        var defaultIndex = factory.getIndexForValue(currentValue);

        var title = new WatchUi.Text({
            :text => WatchUi.loadResource(Rez.Strings.SnoozeDurationLabel) as String,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
        });

        Picker.initialize({
            :title => title,
            :pattern => [factory] as Array<PickerFactory or Drawable>,
            :defaults => [defaultIndex] as Array<Number>
        });
    }
}

//! Delegate for handling snooze duration picker selections
class SnoozeDurationPickerDelegate extends WatchUi.PickerDelegate {

    //! Constructor
    function initialize() {
        PickerDelegate.initialize();
    }

    //! Handle picker confirmation
    //! @param values Array of selected values from each picker column
    //! @return true if handled
    function onAccept(values as Array) as Boolean {
        var value = values[0] as Number;

        // Validate range
        if (value < 15) { value = 15; }
        if (value > 180) { value = 180; }

        // Save to properties
        try {
            Properties.setValue("snoozeDuration", value);
            System.println("SitLess: Snooze duration set to " + value);
        } catch (e) {
            System.println("SitLess: Failed to save snooze duration");
        }

        // Pop back to widget (picker + menu)
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    //! Handle picker cancellation
    //! @return true if handled
    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
