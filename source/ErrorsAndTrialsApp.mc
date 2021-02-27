using Toybox.Application;
using Toybox.WatchUi as Ui;
using DataProvider as DP;
using RuntimeData as RD;

(:background)
class ErrorsAndTrialsApp extends Application.AppBase {

    private var mView;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        // TODO: Maybe, I should keep the ref to DataProviders / RuntimeData right here in AppBase :-/
        tryReInitDataProviders();

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

    function onBackgroundData(data) {
        try {
            handleReceivedData(data);
        } catch(exception) {
            exception.printStackTrace();
        }
    }

    private function handleReceivedData(data) {
        if ((data == null) || data.hasKey("httpError")) {
            return;
        }

        // Reset on incoming data
        $.receivedDataHandlerFailed = false;
        if (RD.weatherDataProvider == null) {
            $.receivedDataHandlerFailed = true;
            tryReInitDataProviders();
        }

        RD.weatherDataProvider.setWeather(data);
        Ui.requestUpdate();
    }

    private function tryReInitDataProviders() {
        if (RD.formattedDateDataProvider == null) {
            RD.formattedDateDataProvider = new DP.FormattedDateDataProvider();
        }

        if (RD.batteryDataProvider == null) {
            RD.batteryDataProvider = new DP.BatteryDataProvider();
        }

        if (RD.themeDataProvider == null) {
            RD.themeDataProvider = new DP.ThemeDataProvider();
        }

        if (RD.weatherDataProvider == null) {
            RD.weatherDataProvider = new DP.WeatherDataProvider();
        }
    }
}
