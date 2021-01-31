using Toybox.Application as App;
using Toybox.Time as T;
using Toybox.Background as Bg;
using RuntimeData as RD;
using Toybox.Activity as Activity;

module DataProvider {

    class WeatherDataProvider {

        // Not a great test, as a degree of longitude varies between 69 (equator) and 0 (pole) miles, but simpler than
        // true distance calculation; 0.02 degree of latitude is just over a mile
        private const IMMEDIATE_UPDATE_THRESHOLD_LOCATION_DIFF = 0.2;
        private const IMMEDIATE_UPDATE_THRESHOLD_LOCATION_DELAY = 1200; // 20 min
        private const IMMEDIATE_UPDATE_THRESHOLD_PERIOD_SEC = 7200; // 2 hours
        private const DATA_TOO_OLD_THRESHOLD_SEC = 9000; // 2.5 hours
        private const UPDATE_PERIOD_SEC = 3600; // 1 hour

        function initialize() {
            tryUpdateLocation();
        }

        function getWeather() {
            var weather = App.getApp().getProperty("OpenWeatherMapCurrent");

            if ((weather != null) && (T.now().value() < (weather["dt"] + DATA_TOO_OLD_THRESHOLD_SEC))) {
                return weather;
            }

            return null;
        }

        function setWeather(weather) {
            App.getApp().setProperty("OpenWeatherMapCurrent", weather);
        }

        // Currently called on layout initialisation / when settings change / and on exiting sleep
        function requestWeatherUpdate() {
            $.showTemporalEventTime("WeatherDataProvider_1");

            tryUpdateLocation();

            if (!canRegister()) {
                Bg.deleteTemporalEvent();
                log("requestWeatherUpdate - cannot register");
                return;
            }

            var now = T.now();
            var isImmediateUpdateNeeded = needImmediateUpdate(now);

            registerForEvent(now, isImmediateUpdateNeeded);

            $.showTemporalEventTime("WeatherDataProvider_2");
        }

        private function tryUpdateLocation() {
            // Attempt to update current location
            // If current location available from current activity, save it in case it goes "stale" and can not longer be retrieved
            var location = Activity.getActivityInfo().currentLocation;
            if (location != null) {
                location = location.toDegrees(); // Array of Doubles

                RD.gLocationLat = location[0].toFloat();
                RD.gLocationLng = location[1].toFloat();

                App.getApp().setProperty("LastLocationLat", RD.gLocationLat);
                App.getApp().setProperty("LastLocationLng", RD.gLocationLng);
            // If current location is not available, read stored value from Object Store, being careful not to overwrite a valid
            // in-memory value with an invalid stored one.
            } else if (RD.gLocationLat == null) {
                var lat = App.getApp().getProperty("LastLocationLat");

                if (lat != null) {
                    var lng = App.getApp().getProperty("LastLocationLng");

                    RD.gLocationLat = lat;
                    RD.gLocationLng = lng;
                }
            }
        }

        private function canRegister() {
            return (RD.gLocationLat != null) &&
                    (App.getApp().getProperty("openweathermap_api").length() > 0);
        }

        private function needImmediateUpdate(now) {
            var weather = getWeather();

            if (weather == null) {
                return true;
            }

            var weatherTime = weather["dt"];
            var diffSeconds = now.value() - weatherTime;

            if (diffSeconds > IMMEDIATE_UPDATE_THRESHOLD_PERIOD_SEC) {
                return true;
            }


            if ((((RD.gLocationLat - weather["lat"]).abs() > IMMEDIATE_UPDATE_THRESHOLD_LOCATION_DIFF) ||
                ((RD.gLocationLng - weather["lon"]).abs() > IMMEDIATE_UPDATE_THRESHOLD_LOCATION_DIFF)) &&
                (diffSeconds > IMMEDIATE_UPDATE_THRESHOLD_LOCATION_DELAY)) {

                return true;
            }

            return false;
        }

        // TODO: Add backfoff delay (otherwise it might eat up :-( the whole battery when data too old and cannot obtain new
        private function registerForEvent(now, isImmediateUpdateNeeded) {
            log("registerForEvent - isImmediateUpdateNeeded: " + isImmediateUpdateNeeded);

            var registeredTime = Bg.getTemporalEventRegisteredTime();
            var isSetRegisteredTime = registeredTime != null;
            log("registerForEvent - isSetRegisteredTime: " + isSetRegisteredTime);

            if (isImmediateUpdateNeeded) {
                // Register for background temporal event as soon as possible
                var lastTimeEventFired = Bg.getLastTemporalEventTime();
                var isSetLastTimeEventFired = lastTimeEventFired != null;
                log("registerForEvent - isSetLastTimeEventFired: " + isSetLastTimeEventFired);


                var isRegisteredTimeOfTypeDuration = isSetRegisteredTime && (registeredTime has :divide);
                log("registerForEvent - isRegisteredTimeOfTypeDuration: " + isRegisteredTimeOfTypeDuration);

                // Events scheduled for a time in the past trigger immediately
                // if (isSetLastTimeEventFired && isRegisteredTimeOfTypeDuration) {
                if (isSetLastTimeEventFired && (!isSetRegisteredTime || isRegisteredTimeOfTypeDuration)) {
                    log("registerForEvent - register nextTime");
                    // Add at least 5 minutes to avoid InvalidBackgroundTimeException (registration in past should fire event ASAP)
                    var nextTime = lastTimeEventFired.add(new T.Duration(5 * 60));
                    Bg.registerForTemporalEvent(nextTime);
                } else if (!isSetLastTimeEventFired) {
                    log("registerForEvent - register now");
                    Bg.registerForTemporalEvent(now);
                } else {
                    log("registerForEvent - already registered and waiting");
                }
            } else if (!isSetRegisteredTime) {
                var period = new T.Duration(UPDATE_PERIOD_SEC);
                Bg.registerForTemporalEvent(period);
            } else {
                log("registerForEvent - registered as expected");
            }
        }

    }

}
