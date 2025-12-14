import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;

class sitlessView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var info = ActivityMonitor.getInfo();
        var steps = 0;
        if (info != null && info.steps != null) {
            steps = info.steps;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            "Steps: " + steps,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function onHide() as Void {
    }

}
