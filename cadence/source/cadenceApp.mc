using Toybox.Application;
using Toybox.WatchUi;

class cadenceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // For this app all that needs to be done is trigger a WatchUi refresh
    // since the settings are only used in onUpdate().
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new cadenceView() ];
    }

}
