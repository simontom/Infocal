using Toybox.Application;
using Toybox.Activity as Activity;
using Toybox.System as Sys;
using Toybox.Background as Bg;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Math;
using Toybox.Lang;
using Toybox.Time.Gregorian as Date;

var gLocationLat = null;
var gLocationLng = null;

var centerX;
var centerY;

function degreesToRadians(degrees) {
    return degrees * Math.PI / 180.0;
}

function radiansToDegrees(radians) {
    return radians * 180.0 / Math.PI;
}

function convertCoorX(radians, radius) {
    return centerX + radius * Math.cos(radians);
}

function convertCoorY(radians, radius) {
    return centerY + radius * Math.sin(radians);
}

(:background)
class HuwaiiApp extends Application.AppBase {

    var mView;
    var days;
    var months;

    function initialize() {
        AppBase.initialize();
        days = {
            Date.DAY_MONDAY => "MON",
            Date.DAY_TUESDAY => "TUE",
            Date.DAY_WEDNESDAY => "WED",
            Date.DAY_THURSDAY => "THU",
            Date.DAY_FRIDAY => "FRI",
            Date.DAY_SATURDAY => "SAT",
            Date.DAY_SUNDAY => "SUN"
        };
        months = {
            Date.MONTH_JANUARY => "JAN",
            Date.MONTH_FEBRUARY => "FEB",
            Date.MONTH_MARCH => "MAR",
            Date.MONTH_APRIL => "APR",
            Date.MONTH_MAY => "MAY",
            Date.MONTH_JUNE => "JUN",
            Date.MONTH_JULY => "JUL",
            Date.MONTH_AUGUST => "AUG",
            Date.MONTH_SEPTEMBER => "SEP",
            Date.MONTH_OCTOBER => "OCT",
            Date.MONTH_NOVEMBER => "NOV",
            Date.MONTH_DECEMBER => "DEC"
        };
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        mView = new HuwaiiView();
        return [mView];
    }

    function getView() {
        return mView;
    }

    function onSettingsChanged() {
        if (HuwaiiApp has :checkPendingWebRequests) {
            checkPendingWebRequests();
        }
        if (mView != null) {
            mView.last_draw_minute = -1;
        }
        Ui.requestUpdate();
    }

    (:background_method)
    function checkPendingWebRequests() {
        var actInfo = Activity.getActivityInfo();
        var location = (actInfo != null) ? actInfo.currentLocation : null;
        if (location != null) {
            location = location.toDegrees();
            gLocationLat = location[0].toFloat();
            gLocationLng = location[1].toFloat();
            setProperty("LastLocationLat", gLocationLat);
            setProperty("LastLocationLng", gLocationLng);
        } else {
            var lat = getProperty("LastLocationLat");
            var lng = getProperty("LastLocationLng");
            if (lat != null && lng != null) {
                gLocationLat = lat;
                gLocationLng = lng;
            }
        }

        if (!(Sys has :ServiceDelegate)) {
            return;
        }

        var pending = getProperty("PendingWebRequests");
        if (pending == null) {
            pending = {};
        }

        var nowVal = Time.now().value();

        // 1. Weather (yr.no via Open-Meteo metno)
        if (getProperty("weather") == true && gLocationLat != null) {
            var wData = getProperty("WeatherData");
            if (wData == null || !(wData instanceof Toybox.Lang.Array) || wData.size() < 6 || (nowVal - wData[0]) > 1800) {
                pending["Weather"] = true;
            }
        }

        // 2. Google Calendar
        var clientId = getProperty("google_client_id");
        if (getProperty("enable_calendar") == true && clientId != null && clientId.length() > 0) {
            var refreshToken = getProperty("google_refresh_token");
            var calData = getProperty("CalendarData");
            if (refreshToken == null || refreshToken.length() == 0) {
                // Poll every 5 minutes while waiting for device flow login
                pending["Calendar"] = true;
            } else if (calData == null || (calData["ts"] != null && (nowVal - calData["ts"]) > 1800)) {
                pending["Calendar"] = true;
            }
        }

        setProperty("PendingWebRequests", pending);

        if (pending.keys().size() > 0) {
            var lastTime = Bg.getLastTemporalEventTime();
            if (lastTime != null) {
                var nextTime = lastTime.add(new Time.Duration(5 * 60));
                Bg.registerForTemporalEvent(nextTime);
            } else {
                Bg.registerForTemporalEvent(Time.now());
            }
        }
    }

    (:background_method)
    function getServiceDelegate() {
        return [new BackgroundService()];
    }

    (:background_method)
    function onBackgroundData(data) {
        if (data == null || !(data instanceof Toybox.Lang.Dictionary)) {
            return;
        }
        var pending = getProperty("PendingWebRequests");
        if (pending == null) {
            pending = {};
        }

        if (data["WeatherData"] != null) {
            var w = data["WeatherData"];
            if (w instanceof Toybox.Lang.Array) {
                setProperty("WeatherData", w);
                pending.remove("Weather");
            }
        }

        if (data["CalendarAuth"] != null) {
            var auth = data["CalendarAuth"];
            if (auth["device_code"] != null) {
                setProperty("google_device_code", auth["device_code"]);
            }
            if (auth["user_code"] != null) {
                setProperty("google_user_code", auth["user_code"]);
            }
        }

        if (data["CalendarData"] != null) {
            var cal = data["CalendarData"];
            if (cal["refresh_token"] != null && cal["refresh_token"].length() > 0) {
                setProperty("google_refresh_token", cal["refresh_token"]);
                setProperty("google_device_code", "");
                setProperty("google_user_code", "");
            }
            if (cal["events"] != null) {
                setProperty("CalendarData", {
                    "ts" => cal["ts"],
                    "events" => cal["events"]
                });
                pending.remove("Calendar");
            }
        }

        setProperty("PendingWebRequests", pending);
        if (pending.keys().size() > 0) {
            checkPendingWebRequests();
        }
        Ui.requestUpdate();
    }

    function getFormatedDate() {
        var now = Time.now();
        var date = Date.info(now, Time.FORMAT_SHORT);
        var date_formater = getProperty("date_format");
        if (date_formater == null) {
            date_formater = 0;
        }
        if (date_formater == 0) {
            if (getProperty("force_date_english")) {
                return Lang.format("$1$ $2$", [days[date.day_of_week], date.day.format("%d")]);
            } else {
                var dateLong = Date.info(now, Time.FORMAT_LONG);
                return Lang.format("$1$ $2$", [dateLong.day_of_week.toUpper(), dateLong.day.format("%d")]);
            }
        } else if (date_formater == 1) {
            return Lang.format("$1$.$2$", [date.day.format("%d"), date.month.format("%d")]);
        } else if (date_formater == 2) {
            return Lang.format("$1$.$2$", [date.month.format("%d"), date.day.format("%d")]);
        } else if (date_formater == 5) {
            return Lang.format("$1$ $2$", [date.day.format("%d"), months[date.month]]);
        } else if (date_formater == 6) {
            return Lang.format("$1$ $2$", [months[date.month], date.day.format("%d")]);
        }
        return Lang.format("$1$ $2$", [days[date.day_of_week], date.day.format("%d")]);
    }

    function toKValue(value) {
        var valK = value / 1000.0;
        return valK.format("%0.1f");
    }
}
