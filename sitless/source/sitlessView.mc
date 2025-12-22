import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Lang;
import Toybox.Application.Properties;

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
        var screenWidth = dc.getWidth();

        // Get step goal from settings
        var stepGoal = getMinSteps();

        // Determine color based on goal progress
        var hasData = windowSteps >= 0;
        var goalMet = hasData && windowSteps >= stepGoal;
        var progressColor = Graphics.COLOR_DK_GRAY;
        if (hasData) {
            progressColor = goalMet ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
        }

        // 1. Daily steps (top, small gray font)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY - 50,
            Graphics.FONT_SMALL,
            "Daily: " + dailySteps,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // 2. Main step count (center, large font, colored)
        dc.setColor(progressColor, Graphics.COLOR_TRANSPARENT);
        var mainText = hasData ? windowSteps + " / " + stepGoal : "...";
        dc.drawText(
            centerX,
            centerY - 10,
            Graphics.FONT_LARGE,
            mainText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // 3. Progress bar (below center)
        var barWidth = (screenWidth * 70) / 100;
        var barHeight = 12;
        var barX = (screenWidth - barWidth) / 2;
        var barY = centerY + 20;

        // Progress bar background (dark gray)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.fillRectangle(barX, barY, barWidth, barHeight);

        // Progress bar fill (colored based on status)
        if (hasData) {
            var progress = windowSteps.toFloat() / stepGoal.toFloat();
            if (progress > 1.0) {
                progress = 1.0;
            }
            var fillWidth = (barWidth * progress).toNumber();
            if (fillWidth > 0) {
                dc.setColor(progressColor, progressColor);
                dc.fillRectangle(barX, barY, fillWidth, barHeight);
            }
        }

        // 4. Label "last 60 min" (bottom, small gray font)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var labelText = "last " + DEFAULT_WINDOW_MINUTES + " min";
        if (!hasData) {
            labelText += " (" + sampleCount + " samples)";
        }
        dc.drawText(
            centerX,
            centerY + 50,
            Graphics.FONT_SMALL,
            labelText,
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

    // Read minSteps setting from Properties
    private function getMinSteps() as Number {
        try {
            var value = Properties.getValue("minSteps");
            if (value != null && value instanceof Number) {
                return value as Number;
            }
        } catch (e) {
            System.println("SitLess: Error reading minSteps");
        }
        return 50;
    }

}
