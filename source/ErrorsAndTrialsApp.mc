using Toybox.Application;
using Toybox.Activity as Activity;
using Toybox.Background as BG;
using Toybox.WatchUi as Ui;
using Toybox.Time as T;
using DataProvider as DP;
using RuntimeData as RD;

// TODO: Add:
//              - Moon Phase

// TODO: Remove:
//              - Calories
//              - BackgroundService
//              - Distance?

// TODO: Rewrite:
//              - Weather

(:background)
class ErrorsAndTrialsApp extends Application.AppBase {

    private var mView;

    function initialize() {
        AppBase.initialize();
    }

    // Return the initial view of your application here
    function getInitialView() {
        RD.formattedDateDataProvider = new DP.FormattedDateDataProvider();
        RD.batteryDataProvider = new DP.BatteryDataProvider();
        RD.themeDataProvider = new DP.ThemeDataProvider();

        mView = new ErrorsAndTrialsView();
        return [mView];
    }

    function getView() {
        return mView;
    }

    function onSettingsChanged() {
        RD.formattedDateDataProvider.reloadSettings();
        RD.themeDataProvider.reloadSettings();

        requestWeatherUpdate();

        mView.last_draw_minute = -1;
        Ui.requestUpdate();   // Update the view to reflect changes
    }

    function getServiceDelegate() {
        return [new BackgroundService()];
    }

    // Handle data received from BackgroundService
    function onBackgroundData(data) {
        if (data.hasKey("httpError")) {
            return;
        }

        setProperty("OpenWeatherMapCurrent", data);

        Ui.requestUpdate();
    }

    // Determine if any web requests are needed
    // Currently called on layout initialisation / when settings change / and on exiting sleep
    function requestWeatherUpdate() {
        tryUpdateLocation();

        if (!canUpdateOwm()) {
            return;
        }

        if (shouldUpdateOwm()) {
            // Register for background temporal event as soon as possible
            var lastTime = Bg.getLastTemporalEventTime();

            // Events scheduled for a time in the past trigger immediately
            if (lastTime != null) {
                var nextTime = lastTime.add(new T.Duration(5 * 60));
                Bg.registerForTemporalEvent(nextTime);
            } else {
                Bg.registerForTemporalEvent(T.now());
            }
        }
    }

    private function tryUpdateLocation() {
        // Attempt to update current location
        // If current location available from current activity, save it in case it goes "stale" and can not longer be retrieved
        var location = Activity.getActivityInfo().currentLocation;
        if (location != null) {
            location = location.toDegrees(); // Array of Doubles

            RD.gLocationLat = location[0].toFloat();
            RD.gLocationLng = location[1].toFloat();

            setProperty("LastLocationLat", RD.gLocationLat);
            setProperty("LastLocationLng", RD.gLocationLng);
        // If current location is not available, read stored value from Object Store, being careful not to overwrite a valid
        // in-memory value with an invalid stored one.
        } else if (RD.gLocationLat == null) {
            var lat = Application.getApp().getProperty("LastLocationLat");

            if (lat != null) {
                var lng = Application.getApp().getProperty("LastLocationLng");

                RD.gLocationLat = lat;
                RD.gLocationLng = lng;
            }
        }
    }

    private function canUpdateOwm() {
        if ((RD.gLocationLat == null) || (getProperty("openweathermap_api").length() == 0) || (Bg.getTemporalEventRegisteredTime() != null)) {
            return false;
        }

        return true;
    }

    private function shouldUpdateOwm() {
        var owmCurrent = getProperty("OpenWeatherMapCurrent");

        if (owmCurrent == null) {
            return true;
        }

        // Existing data is older than 30 mins = 30 * 60sec
        if (T.now().value() > (owmCurrent["dt"] + 1800)) {
            return true;
        }

        // Existing data not for current location
        // Not a great test, as a degree of longitude varies between 69 (equator) and 0 (pole) miles, but simpler than
        // true distance calculation; 0.02 degree of latitude is just over a mile
        if (((RD.gLocationLat - owmCurrent["lat"]).abs() > 0.02) ||
            ((RD.gLocationLng - owmCurrent["lon"]).abs() > 0.02)) {

            return true;
        }

        return false;
    }
}
