using Toybox.Application as App;
using Toybox.Time as T;
using Toybox.Background as Bg;
using RuntimeData as RD;
using Toybox.Activity as Activity;

module DataProvider {

    class WeatherDataProvider {

        function initialize() {
            tryUpdateLocation();
        }

        function getWeather() {
            var weather = App.getApp().getProperty("OpenWeatherMapCurrent");

            // Existing data is older than 120 mins = 120 * 60sec = 7'200sec
            if ((weather != null) && (T.now().value() < (weather["dt"] + 7200))) {
                return weather;
            }

            return null;
        }

        function setWeather(weather) {
            App.getApp().setProperty("OpenWeatherMapCurrent", weather);
        }

        // Determine if any web requests are needed
        // Currently called on layout initialisation / when settings change / and on exiting sleep
        function requestWeatherUpdate() {
            $.showTemporalEventTime("WeatherDataProvider_1");

            tryUpdateLocation();

            var now = T.now();

            // if (!canRegisterForUpdates(now)) {
            if (!canRegister()) {
                Bg.deleteTemporalEvent();
                log("requestWeatherUpdate - cannot register");
                return;
            }

            var isImmediateUpdateNeeded = needImmediateUpdate(now);

            requestUpdate(isImmediateUpdateNeeded, now);

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
        // private function canRegister(now) {
            return (RD.gLocationLat != null) &&
                    (App.getApp().getProperty("openweathermap_api").length() > 0);

            // if ((RD.gLocationLat == null) ||
            //     (App.getApp().getProperty("openweathermap_api").length() == 0) // ||
            //     // (Bg.getTemporalEventRegisteredTime() != null)
            //     ) {

            //     return false;
            // }

            // (Bg.getTemporalEventRegisteredTime() == Bg.getLastTemporalEventTime())
            // var temporalEventRegisteredTime = Bg.getTemporalEventRegisteredTime();
            // if ((temporalEventRegisteredTime != null) && now.compare(temporalEventRegisteredTime) >= 3600) {
            // }

            return true;
        }

        private function needImmediateUpdate(now) {
            var weather = getWeather();

            if (weather == null) {
                return true;
            }

            // Stored data is older than 120 mins = 120 * 60sec
            if (now.value() > (weather["dt"] + 7200)) {
                return true;
            }

            // Stored data not for current location
            // Not a great test, as a degree of longitude varies between 69 (equator) and 0 (pole) miles, but simpler than
            // true distance calculation; 0.02 degree of latitude is just over a mile
            if (((RD.gLocationLat - weather["lat"]).abs() > 0.02) ||
                ((RD.gLocationLng - weather["lon"]).abs() > 0.02)) {

                return true;
            }

            return false;
        }

        private function requestUpdate(isImmediateUpdateNeeded, now) {
            log("requestUpdate - isImmediateUpdateNeeded: " + isImmediateUpdateNeeded);
            if (isImmediateUpdateNeeded) {
                // Register for background temporal event as soon as possible
                var lastTimeEventFired = Bg.getLastTemporalEventTime();
                log("requestUpdate - is set lastTimeEventFired: " + (lastTimeEventFired != null));

                var registeredTime = Bg.getTemporalEventRegisteredTime();
                log("requestUpdate - is set registeredTime: " + (registeredTime != null));

                var isRegisteredTimeOfTypeDuration = (registeredTime != null) && (registeredTime has :divide);
                log("requestUpdate - isRegisteredTimeOfTypeDuration: " + isRegisteredTimeOfTypeDuration);

                // Events scheduled for a time in the past trigger immediately
                if ((lastTimeEventFired != null) && isRegisteredTimeOfTypeDuration) {
                    log("requestUpdate - register nextTime");
                    // Bg.deleteTemporalEvent();
                    var nextTime = lastTimeEventFired.add(new T.Duration(5 * 60));
                    Bg.registerForTemporalEvent(nextTime);
                } else if (Bg.getTemporalEventRegisteredTime() == null) {
                    log("requestUpdate - register now");
                    Bg.registerForTemporalEvent(now);
                }

                return;
            }

            var isEventRegistered = Bg.getTemporalEventRegisteredTime() != null;
            log("requestUpdate - isEventRegistered: " + isEventRegistered);
            if (!isEventRegistered) {
                var period = new T.Duration(60 * 60);
                Bg.registerForTemporalEvent(period);
            }
        }

    }

}
