using Toybox.Application;
using Toybox.WatchUi as Ui;
using DataProvider as DP;
using RuntimeData as RD;

// TODO: Do not forger to remoove
function formatMoment(moment) {
    if (moment == null) {
        return "null";
    }

    // INFO: Check if moment is of type Duration
    if (moment has :divide) {
        var lastTime = Toybox.Background.getLastTemporalEventTime();
        moment = lastTime.add(moment);
    }

    var momentAsInfo = Toybox.Time.Gregorian.utcInfo(moment, Toybox.Time.FORMAT_SHORT);
    return Toybox.Lang.format("h=$1$ m=$2$ s=$3$", [momentAsInfo.hour.format("%d"), momentAsInfo.min.format("%d"), momentAsInfo.sec.format("%d")]);
}

// TODO: Do not forger to remoove
function showTemporalEventTime(id) {
    var now = Toybox.Time.now();
    var temporalEventRegisteredTime = Toybox.Background.getTemporalEventRegisteredTime();
    var lastTemporalEventTime = Toybox.Background.getLastTemporalEventTime();

    var nowFormatted = formatMoment(now);
    var temporalEventRegisteredTimeFormatted = formatMoment(temporalEventRegisteredTime);
    var lastTemporalEventTimeFromatted = formatMoment(lastTemporalEventTime);

    // Toybox.System.println(id + " - TemporalEventRegisteredTime: " + temporalEventRegisteredTimeFormatted);
    // Toybox.System.println(id + " - LastTemporalEventTime:       " + lastTemporalEventTimeFromatted);
    // Toybox.System.println(id + " - Now:                         " + nowFormatted);

    // Toybox.System.println("");
}

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
        RD.weatherDataProvider = new DP.WeatherDataProvider();

        mView = new ErrorsAndTrialsView();
        return [mView];
    }

    function getView() {
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

    // Handle data received from BackgroundService
    function onBackgroundData(data) {
        // $.showTemporalEventTime("ErrorsAndTrialsApp  ");

        if (data.hasKey("httpError")) {
            return;
        }

        RD.weatherDataProvider.setWeather(data);

        Ui.requestUpdate();
    }
}
