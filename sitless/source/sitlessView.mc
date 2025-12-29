import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Lang;
import Toybox.System;

class sitlessView extends WatchUi.View {
    // Visibility flag for performance optimization
    private var _isVisible as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        _isVisible = true;
        // Reload step buffer from storage (populated by background service)
        // Then add current sample
        loadStepBufferFromStorage();
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
        var timeWindow = SettingsManager.getTimeWindow();
        var windowSteps = stepBuffer.getStepsInWindow(timeWindow);
        var sampleCount = stepBuffer.getSampleCount();

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var screenWidth = dc.getWidth();

        // Get step goal from settings
        var stepGoal = SettingsManager.getMinSteps();

        // Check if snooze is active
        var isSnoozeActive = AlertManager.isInSnoozeMode();
        var snoozeRemaining = isSnoozeActive ? AlertManager.getSnoozeRemainingMinutes() : 0;

        // Determine color based on goal progress and snooze status
        var hasData = windowSteps >= 0;
        var goalMet = hasData && windowSteps >= stepGoal;
        var progressColor = Graphics.COLOR_DK_GRAY;
        if (isSnoozeActive) {
            progressColor = Graphics.COLOR_ORANGE;
        } else if (hasData) {
            progressColor = goalMet ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
        }

        // 1. Daily steps (top, small gray font)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var dailyLabel = WatchUi.loadResource(Rez.Strings.DailySteps) as String;
        dc.drawText(
            centerX,
            centerY - 50,
            Graphics.FONT_SMALL,
            dailyLabel + ": " + dailySteps,
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

        // 4. Label "last X min" or snooze status (bottom, small font)
        var labelText;
        var labelColor;
        if (isSnoozeActive) {
            // Show snooze status in orange
            var snoozedLabel = WatchUi.loadResource(Rez.Strings.SnoozedLabel) as String;
            labelText = snoozedLabel + " (" + snoozeRemaining + " min)";
            labelColor = Graphics.COLOR_ORANGE;
        } else {
            // Show normal "last X min" label
            var lastMinLabel = WatchUi.loadResource(Rez.Strings.LastMinutes) as String;
            var samplesLabel = WatchUi.loadResource(Rez.Strings.Samples) as String;
            // Replace %d placeholder with actual value
            labelText = lastMinLabel;
            var percentDPos = labelText.find("%d");
            if (percentDPos != null) {
                labelText = labelText.substring(0, percentDPos) + timeWindow.toString() + labelText.substring(percentDPos + 2, labelText.length());
            }
            if (!hasData) {
                labelText += " (" + sampleCount + " " + samplesLabel + ")";
            }
            labelColor = Graphics.COLOR_LT_GRAY;
        }
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY + 50,
            Graphics.FONT_SMALL,
            labelText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // 5. Snooze hint indicator near SELECT button (upper-right, ~30 degrees)
        // Arc + small "zzz" text to indicate snooze functionality
        // 0° = 3 o'clock, 90° = 12 o'clock, so 30° is near 2 o'clock (SELECT button position)
        var hintColor = isSnoozeActive ? Graphics.COLOR_ORANGE : Graphics.COLOR_DK_GRAY;
        dc.setColor(hintColor, Graphics.COLOR_TRANSPARENT);

        // Draw small arc at the edge of screen near SELECT button
        // Arc centered on screen, radius = half screen width, at ~30° position (2 o'clock)
        var arcRadius = (screenWidth / 2) - 3;  // 3px from edge
        dc.setPenWidth(3);
        dc.drawArc(centerX, centerY, arcRadius, Graphics.ARC_COUNTER_CLOCKWISE, 20, 40);  // 20° arc around 30°
        dc.setPenWidth(1);

        // Small "zzz" text near the arc
        // Position using polar coordinates: x = cx + r*cos(30°), y = cy - r*sin(30°)
        // cos(30°) ≈ 0.866, sin(30°) ≈ 0.500
        var textRadius = (screenWidth / 2) - 22;  // Inside the arc
        var zzzX = centerX + (textRadius * 866 / 1000);   // cos(30°) * 1000 = 866
        var zzzY = centerY - (textRadius * 500 / 1000);   // sin(30°) * 1000 = 500
        dc.drawText(
            zzzX,
            zzzY,
            Graphics.FONT_XTINY,
            "zzz",
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

    // Load step buffer data from persistent storage (populated by background service)
    private function loadStepBufferFromStorage() as Void {
        var buffer = getApp().getStepBuffer();
        var storedData = Application.Storage.getValue("stepBuffer");
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
            System.println("SitLess View: Loaded " + convertedSamples.size() + " samples from storage");
        }
    }
}
