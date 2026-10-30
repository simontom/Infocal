using Toybox.Background as Bg;
using Toybox.System as Sys;
using Toybox.Communications as Comms;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Time.Gregorian as Date;
using Toybox.Math;
using Toybox.Lang;

(:background)
class BackgroundService extends Sys.ServiceDelegate {

    var mNewRefreshToken = null;

    (:background_method)
    function initialize() {
        Sys.ServiceDelegate.initialize();
    }

    (:background_method)
    function onTemporalEvent() {
        var app = App.getApp();
        var pending = app.getProperty("PendingWebRequests");
        if (pending == null) {
            Bg.exit({});
            return;
        }

        // Prioritize Weather if pending and coordinates are valid, otherwise Calendar
        var lat = app.getProperty("LastLocationLat");
        var lng = app.getProperty("LastLocationLng");
        if (pending["Weather"] != null && lat != null && lng != null) {
            requestWeather();
        } else if (pending["Calendar"] != null) {
            requestCalendarStep();
        } else {
            Bg.exit({});
        }
    }

    (:background_method)
    function requestWeather() {
        var app = App.getApp();
        var lat = app.getProperty("LastLocationLat");
        var lng = app.getProperty("LastLocationLng");
        if (lat == null || lng == null) {
            Bg.exit({});
            return;
        }

        var tempUnitPref = app.getProperty("temp_unit");
        var unitStr = "celsius";
        if (tempUnitPref == 2 || (tempUnitPref == 0 && Sys.getDeviceSettings().temperatureUnits == Sys.UNIT_STATUTE)) {
            unitStr = "fahrenheit";
        }

        var params = {
            "latitude" => lat,
            "longitude" => lng,
            "hourly" => "temperature_2m,precipitation,weather_code",
            "forecast_hours" => 24,
            "timezone" => "auto",
            "timeformat" => "unixtime",
            "temperature_unit" => unitStr
        };

        makeGetRequest("https://api.open-meteo.com/v1/metno", params, method(:onReceiveWeather));
    }

    (:background_method)
    function onReceiveWeather(responseCode, data) {
        if (responseCode != 200 || data == null || data["hourly"] == null) {
            Bg.exit({});
            return;
        }

        var hourly = data["hourly"];
        var temps = hourly["temperature_2m"];
        var precip = hourly["precipitation"];
        var codes = hourly["weather_code"];
        if (temps == null || precip == null || codes == null || temps.size() < 16) {
            Bg.exit({});
            return;
        }

        var currentHour = Sys.getClockTime().hour;
        var currentTemp = Math.round(temps[0]).toNumber();
        var minTemp = currentTemp;
        var maxTemp = currentTemp;
        for (var i = 1; i < 16 && i < temps.size(); i += 1) {
            if (temps[i] != null) {
                var t = Math.round(temps[i]).toNumber();
                if (t < minTemp) { minTemp = t; }
                if (t > maxTemp) { maxTemp = t; }
            }
        }

        var sumPrecip = 0.0;
        for (var j = 0; j < 24 && j < precip.size(); j += 1) {
            if (precip[j] != null) {
                sumPrecip += precip[j];
            }
        }
        var totalPrecip = Math.round(sumPrecip).toNumber();

        var result = [
            Time.now().value(),
            currentHour,
            currentTemp,
            minTemp,
            maxTemp,
            totalPrecip
        ];

        for (var k = 0; k < 24; k += 1) {
            var wmo = (k < codes.size()) ? codes[k] : null;
            var hOfDay = (currentHour + k) % 24;
            var isDay = (hOfDay >= 6 && hOfDay < 20);
            result.add(mapWmoToMeteoCode(wmo, isDay));
        }

        Bg.exit({ "WeatherData" => result });
    }

    (:background_method)
    function requestCalendarStep() {
        var app = App.getApp();
        var clientId = app.getProperty("google_client_id");
        var clientSecret = app.getProperty("google_client_secret");
        var refreshToken = app.getProperty("google_refresh_token");
        var deviceCode = app.getProperty("google_device_code");

        if (clientId == null || clientId.length() == 0) {
            Bg.exit({});
            return;
        }

        if (refreshToken != null && refreshToken.length() > 0) {
            // Step 3: Exchange refresh_token for access_token
            makePostRequest(
                "https://oauth2.googleapis.com/token",
                {
                    "client_id" => clientId,
                    "client_secret" => clientSecret,
                    "refresh_token" => refreshToken,
                    "grant_type" => "refresh_token"
                },
                method(:onReceiveTokenRefresh)
            );
        } else if (deviceCode != null && deviceCode.length() > 0) {
            // Step 2: Poll device_code for user approval
            makePostRequest(
                "https://oauth2.googleapis.com/token",
                {
                    "client_id" => clientId,
                    "client_secret" => clientSecret,
                    "device_code" => deviceCode,
                    "grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
                },
                method(:onReceiveDevicePoll)
            );
        } else {
            // Step 1: Request new device_code and user_code
            makePostRequest(
                "https://oauth2.googleapis.com/device/code",
                {
                    "client_id" => clientId,
                    "scope" => "https://www.googleapis.com/auth/calendar.readonly"
                },
                method(:onReceiveDeviceCode)
            );
        }
    }

    (:background_method)
    function onReceiveDeviceCode(responseCode, data) {
        if (responseCode == 200 && data != null && data["device_code"] != null) {
            Bg.exit({
                "CalendarAuth" => {
                    "device_code" => data["device_code"],
                    "user_code" => data["user_code"],
                    "verification_url" => "google.com/device"
                }
            });
            return;
        }
        Bg.exit({});
    }

    (:background_method)
    function onReceiveDevicePoll(responseCode, data) {
        if (responseCode == 200 && data != null && data["access_token"] != null) {
            mNewRefreshToken = data["refresh_token"];
            fetchCalendarEvents(data["access_token"]);
            return;
        }
        if (data != null && data["error"] != null && data["error"].equals("expired_token")) {
            Bg.exit({
                "CalendarAuth" => {
                    "device_code" => "",
                    "user_code" => ""
                }
            });
            return;
        }
        Bg.exit({});
    }

    (:background_method)
    function onReceiveTokenRefresh(responseCode, data) {
        if (responseCode == 200 && data != null && data["access_token"] != null) {
            fetchCalendarEvents(data["access_token"]);
            return;
        }
        if (data != null && data["error"] != null && data["error"].equals("invalid_grant")) {
            Bg.exit({ "CalendarAuth" => { "clear_tokens" => true } });
            return;
        }
        Bg.exit({});
    }

    (:background_method)
    function fetchCalendarEvents(accessToken) {
        var calId = App.getApp().getProperty("calendar_ids");
        if (calId == null || calId.length() == 0) {
            calId = "primary";
        } else {
            var commaIdx = calId.find(",");
            if (commaIdx != null && commaIdx > 0) {
                calId = calId.substring(0, commaIdx);
            }
        }

        var now = Time.now();
        var next24 = now.add(new Time.Duration(24 * 3600));
        var url = "https://www.googleapis.com/calendar/v3/calendars/" + Comms.encodeURL(calId) + "/events";
        var params = {
            "singleEvents" => "true",
            "orderBy" => "startTime",
            "timeMin" => formatUtcIso(now),
            "timeMax" => formatUtcIso(next24),
            "maxResults" => "6",
            "fields" => "items(summary,location,start/dateTime,end/dateTime)"
        };
        var options = {
            :method => Comms.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + accessToken
            },
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Comms.makeWebRequest(url, params, options, method(:onReceiveCalendarEvents));
    }

    (:background_method)
    function onReceiveCalendarEvents(responseCode, data) {
        if (responseCode != 200 || data == null) {
            if (mNewRefreshToken != null) {
                Bg.exit({
                    "CalendarData" => {
                        "ts" => Time.now().value(),
                        "refresh_token" => mNewRefreshToken,
                        "events" => []
                    }
                });
            } else {
                Bg.exit({});
            }
            return;
        }

        var eventsOut = [];
        var items = data["items"];
        if (items != null && (items instanceof Toybox.Lang.Array)) {
            for (var i = 0; i < items.size(); i += 1) {
                var item = items[i];
                var startObj = item["start"];
                var endObj = item["end"];
                if (startObj != null && startObj["dateTime"] != null && endObj != null && endObj["dateTime"] != null) {
                    var startEpoch = parseIso8601ToEpoch(startObj["dateTime"]);
                    var endEpoch = parseIso8601ToEpoch(endObj["dateTime"]);
                    if (startEpoch != null && endEpoch != null) {
                        var summary = (item["summary"] != null) ? item["summary"] : "Event";
                        if (summary.length() > 20) {
                            summary = summary.substring(0, 20);
                        }
                        var loc = (item["location"] != null) ? item["location"] : "";
                        var comma = loc.find(",");
                        if (comma != null && comma > 0) {
                            loc = loc.substring(0, comma);
                        }
                        if (loc.length() > 12) {
                            loc = loc.substring(0, 12);
                        }
                        eventsOut.add([startEpoch, endEpoch, summary, loc]);
                    }
                }
            }
        }

        Bg.exit({
            "CalendarData" => {
                "ts" => Time.now().value(),
                "refresh_token" => mNewRefreshToken,
                "events" => eventsOut
            }
        });
    }

    (:background_method)
    function formatUtcIso(moment) {
        var utcInfo = Date.utcInfo(moment, Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$T$4$:$5$:00Z", [
            utcInfo.year.format("%04d"),
            utcInfo.month.format("%02d"),
            utcInfo.day.format("%02d"),
            utcInfo.hour.format("%02d"),
            utcInfo.min.format("%02d")
        ]);
    }

    (:background_method)
    function makeGetRequest(url, params, callback) {
        var options = {
            :method => Comms.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Comms.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Comms.makeWebRequest(url, params, options, callback);
    }

    (:background_method)
    function makePostRequest(url, params, callback) {
        var options = {
            :method => Comms.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Comms.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Comms.makeWebRequest(url, params, options, callback);
    }
}
