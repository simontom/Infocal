using Toybox.Application;
using Toybox.Activity as Activity;
using Toybox.Background as BG;
using Toybox.WatchUi as Ui;
using Toybox.Time;
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

        mView = new ErrorsAndTrialsView();
        return [mView];
    }

    function getView() {
        return mView;
    }

    function onSettingsChanged() {
        RD.formattedDateDataProvider.reloadSettings();

        checkPendingWebRequests();

        mView.last_draw_minute = -1;
        WatchUi.requestUpdate();   // Update the view to reflect changes
    }

    (:background_method)
    function getServiceDelegate() {
        return [new BackgroundService()];
    }

    // Determine if any web requests are needed.
    // If so, set approrpiate pendingWebRequests flag for use by BackgroundService, then register for temporal event.
    // Currently called on layout initialisation / when settings change / and on exiting sleep.
    (:background_method)
    function checkPendingWebRequests() {
        // Attempt to update current location, to be used by Sunrise/Sunset, and Weather.
        // If current location available from current activity, save it in case it goes "stale" and can not longer be retrieved.
        var location = Activity.getActivityInfo().currentLocation;
        if (location != null) {
            location = location.toDegrees(); // Array of Doubles
            RD.gLocationLat = location[0].toFloat();
            RD.gLocationLng = location[1].toFloat();

            Application.getApp().setProperty("LastLocationLat", RD.gLocationLat);
            Application.getApp().setProperty("LastLocationLng", RD.gLocationLng);
        // If current location is not available, read stored value from Object Store, being careful not to overwrite a valid
        // in-memory value with an invalid stored one.
        } else {
            var lat = Application.getApp().getProperty("LastLocationLat");

            if (lat != null) {
                var lng = Application.getApp().getProperty("LastLocationLng");

                RD.gLocationLat = lat;
                RD.gLocationLng = lng;
            }
        }

        var pendingWebRequests = getProperty("PendingWebRequests");
        if (pendingWebRequests == null) {
            pendingWebRequests = {};
        }

        // 2. Weather:
        // Location must be available, weather or humidity (#113) data field must be shown
        if (RD.gLocationLat != null) {
            var owmCurrent = getProperty("OpenWeatherMapCurrent");

            // No existing data.
            if (owmCurrent == null) {
                pendingWebRequests["OpenWeatherMapCurrent"] = true;
            // Successfully received weather data.
            } else if (owmCurrent["cod"] == 200) {
                if (
                    // Existing data is older than 30 mins.
                    // TODO: Consider requesting weather at sunrise/sunset to update weather icon.
                    (Time.now().value() > (owmCurrent["dt"] + 1800)) ||

                    // Existing data not for this location.
                    // Not a great test, as a degree of longitude varies betwee 69 (equator) and 0 (pole) miles, but simpler than
                    // true distance calculation. 0.02 degree of latitude is just over a mile.
                    (((RD.gLocationLat - owmCurrent["lat"]).abs() > 0.02) ||
                    ((RD.gLocationLng - owmCurrent["lon"]).abs() > 0.02))) {

                    pendingWebRequests["OpenWeatherMapCurrent"] = true;
                }
            }
        }

        // If there are any pending requests:
        if (pendingWebRequests.keys().size() > 0) {
            // Register for background temporal event as soon as possible.
            var lastTime = BG.getLastTemporalEventTime();

            // Events scheduled for a time in the past trigger immediately.
            if (lastTime) {
                var nextTime = lastTime.add(new Time.Duration(20 * 60));
                BG.registerForTemporalEvent(nextTime);
            } else {
                BG.registerForTemporalEvent(Time.now());
            }
        }

        setProperty("PendingWebRequests", pendingWebRequests);
    }

    // Handle data received from BackgroundService.
    // On success, clear appropriate pendingWebRequests flag.
    // data is Dictionary with single key that indicates the data type received. This corresponds with Object Store and
    // pendingWebRequests keys.
    (:background_method)
    function onBackgroundData(data) {
        var pendingWebRequests = getProperty("PendingWebRequests");
        if (pendingWebRequests == null) {
            pendingWebRequests = {};
        }

        var type = data.keys()[0]; // Type of received data.
        var storedData = getProperty(type);
        var receivedData = data[type]; // The actual data received: strip away type key.

        // No value in showing any HTTP error to the user, so no need to modify stored data.
        // Leave pendingWebRequests flag set, and simply return early.
        if (receivedData["httpError"]) {
            return;
        }

        // New data received: clear pendingWebRequests flag and overwrite stored data.
        storedData = receivedData;
        pendingWebRequests.remove(type);
        setProperty("PendingWebRequests", pendingWebRequests);
        setProperty(type, storedData);

        Ui.requestUpdate();
    }
}
