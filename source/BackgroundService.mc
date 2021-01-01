using Toybox.Background as Bg;
using Toybox.System as Sys;
using Toybox.Communications as Comms;
using Toybox.Application as App;

(:background)
class BackgroundService extends Sys.ServiceDelegate {

    (:background_method)
    function initialize() {
        Sys.ServiceDelegate.initialize();
    }

    // Read pending web requests, and call appropriate web request function.
    // This function determines priority of web requests, if multiple are pending.
    // Pending web request flag will be cleared only once the background data has been successfully received.
    (:background_method)
    function onTemporalEvent() {
        Sys.println("onTemporalEvent");
        var pendingWebRequests = App.getApp().getProperty("PendingWebRequests");
        if (pendingWebRequests != null) {
            if (pendingWebRequests["OpenWeatherMapCurrent"] != null) {
                var api_key = App.getApp().getProperty("openweathermap_api");
                if (api_key.length() == 0) {
                    api_key = "333d6a4283794b870f5c717cc48890b5"; // default apikey
                }

                makeWebRequest(
                    "https://api.openweathermap.org/data/2.5/weather",
                    {
                        "lat" => App.getApp().getProperty("LastLocationLat"),
                        "lon" => App.getApp().getProperty("LastLocationLng"),
                        "appid" => api_key,
                        "units" => "metric" // Celcius.
                    },
                    method(:onReceiveOpenWeatherMapCurrent)
                );
            }
        }
    }

    // Sample invalid API key:
    /*
    {
        "cod":401,
        "message": "Invalid API key. Please see http://openweathermap.org/faq#error401 for more info."
    }
    */

    // Sample current weather:
    /*
    {
        "coord":{
            "lon":-0.46,
            "lat":51.75
        },
        "weather":[
            {
                "id":521,
                "main":"Rain",
                "description":"shower rain",
                "icon":"09d"
            }
        ],
        "base":"stations",
        "main":{
            "temp":281.82,
            "pressure":1018,
            "humidity":70,
            "temp_min":280.15,
            "temp_max":283.15
        },
        "visibility":10000,
        "wind":{
            "speed":6.2,
            "deg":10
        },
        "clouds":{
            "all":0
        },
        "dt":1540741800,
        "sys":{
            "type":1,
            "id":5078,
            "message":0.0036,
            "country":"GB",
            "sunrise":1540709390,
            "sunset":1540744829
        },
        "id":2647138,
        "name":"Hemel Hempstead",
        "cod":200
    }
    */
    (:background_method)
    function onReceiveOpenWeatherMapCurrent(responseCode, data) {
        var result;

        // Useful data only available if result was successful.
        // Filter and flatten data response for data that we actually need.
        // Reduces runtime memory spike in main app.
        if (responseCode == 200) {
            result = {
                "cod" => data["cod"],
                "lat" => data["coord"]["lat"],
                "lon" => data["coord"]["lon"],
                "dt" => data["dt"],
                "temp" => data["main"]["temp"],
                "temp_min" => data["main"]["temp_min"],
                "temp_max" => data["main"]["temp_max"],
                "humidity" => data["main"]["humidity"],
                "wind_speed" => data["wind"]["speed"],
                "wind_direct" => data["wind"]["deg"],
                "icon" => data["weather"][0]["icon"],
                "des" => data["weather"][0]["main"]
            };

        // HTTP error: do not save.
        } else {
            result = {
                "httpError" => responseCode
            };
        }

        Bg.exit({
            "OpenWeatherMapCurrent" => result
        });
    }

    (:background_method)
    function makeWebRequest(url, params, callback) {
        var options = {
            :method => Comms.HTTP_REQUEST_METHOD_GET,
            :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Comms.makeWebRequest(url, params, options, callback);
    }
}
