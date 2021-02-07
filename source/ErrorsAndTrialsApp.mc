using Toybox.Application;
using Toybox.WatchUi as Ui;
using DataProvider as DP;
using RuntimeData as RD;

// TODO: Do not forget to remove
function formatMoment(moment) {
    if (moment == null) {
        return "null";
    }

    // INFO: Check if moment is of type Duration
    if (moment has :divide) {
        Toybox.System.println(" -> duration");
        var lastTime = Toybox.Background.getLastTemporalEventTime();
        moment = lastTime.add(moment);
    }

    var momentAsInfo = Toybox.Time.Gregorian.info(moment, Toybox.Time.FORMAT_SHORT);
    return Toybox.Lang.format(
        "m=$5$ d=$4$ h=$1$ m=$2$ s=$3$",
        [momentAsInfo.hour.format("%02d"), momentAsInfo.min.format("%02d"), momentAsInfo.sec.format("%02d"),
        momentAsInfo.day.format("%02d"), momentAsInfo.month.format("%02d")]);
}

// TODO: Do not forget to remove
function showTemporalEventTime(id) {
    var now = Toybox.Time.now();
    var temporalEventRegisteredTime = Toybox.Background.getTemporalEventRegisteredTime();
    var lastTemporalEventTime = Toybox.Background.getLastTemporalEventTime();

    var nowFormatted = $.formatMoment(now);
    var temporalEventRegisteredTimeFormatted = $.formatMoment(temporalEventRegisteredTime);
    var lastTemporalEventTimeFromatted = $.formatMoment(lastTemporalEventTime);

    Toybox.System.println(id + " - Now:                         " + nowFormatted);
    Toybox.System.println(id + " - TemporalEventRegisteredTime: " + temporalEventRegisteredTimeFormatted);
    Toybox.System.println(id + " - LastTemporalEventTime:       " + lastTemporalEventTimeFromatted);

    // Toybox.System.println("");
}

// TODO: Do not forforgetger to remove
function log(message) {
    var moment = Toybox.Time.now();
    var momentAsInfo = Toybox.Time.Gregorian.info(moment, Toybox.Time.FORMAT_SHORT);
    var formatted = Toybox.Lang.format(
        "$6$-$5$_$1$:$2$:$3$ - $4$",
        [momentAsInfo.hour.format("%02d"), momentAsInfo.min.format("%02d"), momentAsInfo.sec.format("%02d"),
         message, momentAsInfo.day.format("%02d"), momentAsInfo.month.format("%02d")]);

    Toybox.System.println(formatted);
    // Toybox.System.println("");
}

(:background)
class ErrorsAndTrialsApp extends Application.AppBase {

    private var mView;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        $.log("getInitialView");

        // TODO: Maybe, I should keep the ref to DataProviders / RuntimeData right here in AppBase :-/
        tryReInitDataProviders();

        mView = new ErrorsAndTrialsView();
        return [mView];
    }

    function getView() {
        $.log("getView");
        return mView;
    }

    function onSettingsChanged() {
        RD.formattedDateDataProvider.reloadSettings();
        RD.themeDataProvider.reloadSettings();

        RD.weatherDataProvider.requestWeatherUpdate();

        mView.last_draw_minute = -1;
        Ui.requestUpdate(); // Update the view to reflect changes
    }

    function getServiceDelegate() {
        return [new BackgroundService()];
    }

    function onBackgroundData(data) {
        try {
            handleReceivedData(data);
        } catch(exception) {
            if (data has :toString) {
                var dataAsString = data.toString();
                $.log("onBackgroundData - CATCH - data has toString: " + dataAsString);
            } else {
                $.log("onBackgroundData - CATCH - data missing toString");
            }

            var message = exception.getErrorMessage();
            $.log("onBackgroundData - CATCH - message: " + message);
            exception.printStackTrace();
        }
    }

    private function handleReceivedData(data) {
        if (data == null) {
            $.log("onBackgroundData - ERROR - data is NULL");
            return;
        }

        if (data.hasKey("httpError")) {
            $.log("onBackgroundData - ERROR - " + data["httpError"]);
            return;
        }

        if (RD.weatherDataProvider == null) {
            $.log("onBackgroundData - DONE - before setWeather - RD.weatherDataProvider is NULL");
            $.receivedDataHandlerFailed = true;
            tryReInitDataProviders();
        }

        $.log("onBackgroundData - DONE - before setWeather - " + data["dt"]);
        RD.weatherDataProvider.setWeather(data);

        $.log("onBackgroundData - DONE - before requestUpdate");
        Ui.requestUpdate();
    }

    private function tryReInitDataProviders() {
        $.log("tryReInitDataProviders");

        if (RD.formattedDateDataProvider == null) {
            $.log("tryReInitDataProviders - creating FormattedDateDataProvider");
            RD.formattedDateDataProvider = new DP.FormattedDateDataProvider();
        }

        if (RD.batteryDataProvider == null) {
            $.log("tryReInitDataProviders - creating BatteryDataProvider");
            RD.batteryDataProvider = new DP.BatteryDataProvider();
        }

        if (RD.themeDataProvider == null) {
            $.log("tryReInitDataProviders - creating ThemeDataProvider");
            RD.themeDataProvider = new DP.ThemeDataProvider();
        }

        if (RD.weatherDataProvider == null) {
            $.log("tryReInitDataProviders - creating WeatherDataProvider");
            RD.weatherDataProvider = new DP.WeatherDataProvider();
        }
    }
}
