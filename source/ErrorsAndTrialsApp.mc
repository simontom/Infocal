using Toybox.Application;
using Toybox.WatchUi as Ui;
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
        if (data.hasKey("httpError")) {
            return;
        }

        RD.weatherDataProvider.setWeather(data);

        Ui.requestUpdate();
    }
}
