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

        private function canUpdateOwm() {
            if ((RD.gLocationLat == null) ||
                (App.getApp().getProperty("openweathermap_api").length() == 0) ||
                (Bg.getTemporalEventRegisteredTime() != null)) {

                return false;
            }

            return true;
        }

        private function shouldUpdateOwm() {
            var weather = getWeather();

            if (weather == null) {
                return true;
            }

            // Existing data is older than 30 mins = 30 * 60sec
            if (T.now().value() > (weather["dt"] + 1800)) {
                return true;
            }

            // Existing data not for current location
            // Not a great test, as a degree of longitude varies between 69 (equator) and 0 (pole) miles, but simpler than
            // true distance calculation; 0.02 degree of latitude is just over a mile
            if (((RD.gLocationLat - weather["lat"]).abs() > 0.02) ||
                ((RD.gLocationLng - weather["lon"]).abs() > 0.02)) {

                return true;
            }

            return false;
        }

    }

}
