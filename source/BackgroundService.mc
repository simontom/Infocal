using Toybox.Background as Bg;
using Toybox.System as Sys;
using Toybox.Communications as Comms;
using Toybox.Application as App;

(:background)
class BackgroundService extends Sys.ServiceDelegate {

    function initialize() {
        Sys.ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        var owmApiKey = App.getApp().getProperty("openweathermap_api");

        // In case of ApiKey gets deleted if TemporalEvent already been registered
        if (owmApiKey.length() == 0) {
            onReceiveWeather(401, null);
            return;
        }

        var parameters = {
            "lat" => App.getApp().getProperty("LastLocationLat"),
            "lon" => App.getApp().getProperty("LastLocationLng"),
            "appid" => owmApiKey,
            "units" => "metric"
        };

        var options = {
            :method => Comms.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED },
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Comms.makeWebRequest(
            "https://api.openweathermap.org/data/2.5/weather",
            parameters,
            options,
            method(:onReceiveWeather)
        );
    }

    function onReceiveWeather(responseCode, data) {
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

        // HTTP error: do not save
        } else {
            result = {
                "httpError" => responseCode
            };
        }

        Bg.exit(result);
    }

    // Some Urls
    // https://openweathermap.org/current
    // https://openweathermap.org/weather-conditions
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
}
