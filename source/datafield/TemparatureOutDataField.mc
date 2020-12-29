using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Activity as Activity;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.SensorHistory as SensorHistory;
using RuntimeData as RD;
using Toybox.Lang as Ex;
using ConversionUtils as CU;
using Toybox.UserProfile;
using Toybox.Time;
using Toybox.Time.Gregorian as Date;

module DataField {

    ///////////////////////////
    // Temparature out stage //
    ///////////////////////////

    class TemparatureOutDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            // WEATHER
            var need_minimal = App.getApp().getProperty("minimal_data");
            var weather_data = App.getApp().getProperty("OpenWeatherMapCurrent");

            if (weather_data == null) {
                if (need_minimal) {
                    return "--";
                }

                return "TEMP --";
            }

            var settings = Sys.getDeviceSettings();
            var temp = weather_data["temp"];
            var unit = "°C";
            if (settings.temperatureUnits == System.UNIT_STATUTE) {
                temp = CU.toFahrenheit(temp);
                unit = "°F";
            }
            value = temp.format("%d") + unit;

            if (need_minimal) {
                return value;
            }

            return Lang.format("TEMP $1$",[value]);
        }
    }

}
