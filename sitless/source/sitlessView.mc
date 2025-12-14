import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Lang;

class sitlessView extends WatchUi.View {
    // Default time window in minutes
    private const DEFAULT_WINDOW_MINUTES = 60;

    // Visibility flag for performance optimization
    private var _isVisible as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        _isVisible = true;
        // Add a sample when view becomes visible
        addStepSample();
    }

    function onUpdate(dc as Dc) as Void {
        // Skip rendering when not visible (performance optimization)
        if (!_isVisible) {
            return;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var info = ActivityMonitor.getInfo();
        var dailySteps = 0;
        if (info != null && info.steps != null) {
            dailySteps = info.steps;
        }

        // Get steps in rolling window from buffer
        var stepBuffer = getApp().getStepBuffer();
        var windowSteps = stepBuffer.getStepsInWindow(DEFAULT_WINDOW_MINUTES);
        var sampleCount = stepBuffer.getSampleCount();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Show daily steps
        dc.drawText(
            centerX,
            centerY - 30,
            Graphics.FONT_SMALL,
            "Daily: " + dailySteps,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Show window steps
        var windowText = "Last 60min: ";
        if (windowSteps < 0) {
            windowText += "..." + " (" + sampleCount + ")";
        } else {
            windowText += windowSteps;
        }
        dc.drawText(
            centerX,
            centerY + 10,
            Graphics.FONT_MEDIUM,
            windowText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function onHide() as Void {
        _isVisible = false;
    }

    // Add current step count as a sample to the buffer
    private function addStepSample() as Void {
        var info = ActivityMonitor.getInfo();
        if (info != null && info.steps != null) {
            var steps = info.steps as Number;
            var stepBuffer = getApp().getStepBuffer();
            stepBuffer.addSample(steps, Time.now());
        }
    }

}
