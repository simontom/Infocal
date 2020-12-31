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

    ///////////////////
    // Weather stage //
    ///////////////////

    class WindDataField extends BaseDataField {

        var wind_direction_mapper;

        function initialize(id) {
            BaseDataField.initialize(id);
            wind_direction_mapper = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW",  "WSW", "W", "WNW", "NW", "NNW"];
        }

        function cur_label(value) {
            // WEATHER
            var need_minimal = App.getApp().getProperty("minimal_data");
            var weather_data = App.getApp().getProperty("OpenWeatherMapCurrent");

            if (weather_data == null) {
                return "--";
            }

            var settings = Sys.getDeviceSettings();
            var speed = weather_data["wind_speed"]*3.6; // kph
            var direct = weather_data["wind_direct"];

            var direct_corrected = direct + 11.25;                                 					// move degrees to int spaces (North from 348.75-11.25 to 360(min)-22.5(max))
            direct_corrected = direct_corrected < 360 ? direct_corrected : direct_corrected - 360;  // move North from 360-371.25 back to 0-11.25 (final result is North 0(min)-22.5(max))
            var direct_idx = (direct_corrected / 22.5).toNumber();                         			// now calculate direction array position: int([0-359.99]/22.5) will result in 0-15 (correct array positions)

            var directLabel = wind_direction_mapper[direct_idx];
            var unit = "k";
            if (settings.distanceUnits == System.UNIT_STATUTE) {
                speed *= 0.621371;
                unit = "m";
            }

            return directLabel + " " + speed.format("%0.1f") + unit;
        }
    }

}