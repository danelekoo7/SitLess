import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class sitlessApp extends Application.AppBase {
    // Step buffer instance shared across app
    // 15 samples = ~75 min coverage at 5min intervals
    private var _stepBuffer as StepBuffer;

    function initialize() {
        AppBase.initialize();
        _stepBuffer = new StepBuffer(15);
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new sitlessView() ];
    }

    // Get the step buffer instance
    function getStepBuffer() as StepBuffer {
        return _stepBuffer;
    }

}

function getApp() as sitlessApp {
    return Application.getApp() as sitlessApp;
}