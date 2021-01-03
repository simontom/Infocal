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
using SettingsEnums as SE;

module DataField {

    ////////////////
    // Baro stage //
    ////////////////

    class BarometerDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_val() {
            var presure_data = _retrieveBarometer();
            return presure_data;
        }

        function cur_label(value) {
            var pascal = value[0];
            var value2 = value[1];

            if (pascal == null) {
                return "BARO --";
            }

            var pressure = null;
            var pressureFormat = null;
            var unit = App.getApp().getProperty("barometer_unit");
            if (unit == SE.BAROMETER_UNIT_INHG) {
                pressure = pascal * 0.000295301d;
                pressureFormat = "%0.2f";
            } else if (unit == SE.BAROMETER_UNIT_HPA) {
                pressure = pascal / 100.0;
                pressureFormat = "%d";
            }

            var signal = "";
            if (value2 == 1) {
                signal = "+";
            } else if (value2 == -1) {
                signal = "-";
            }

            return Lang.format("BAR $1$$2$", [pressure.format(pressureFormat), signal]);
        }

        // Create a method to get the SensorHistoryIterator object
        function _getIterator() {
            return Toybox.SensorHistory.getPressureHistory({});
        }

        // Create a method to get the SensorHistoryIterator object
        function _getIteratorDurate(hour) {
            var duration = new Time.Duration(hour * 3600);
            return Toybox.SensorHistory.getPressureHistory({"period"=>duration, "order"=>SensorHistory.ORDER_OLDEST_FIRST});
        }

        function _retrieveBarometer() {
            var trend_iter = _getIteratorDurate(3); // 3 hour
            var trending = null;
            if (trend_iter!= null) {
                // get 5 sample
                var sample = null;
                var num = 0.0;
                for (var i=0;i<5;i+=1) {
                    sample = trend_iter.next();
                    if ((sample != null) && (sample has :data)) {
                        var d = sample.data;
                        if (d != null) {
                            if (trending == null) {
                                trending = d;
                                num += 1;
                            } else {
                                trending += d;
                                num += 1;
                            }
                        }
                    }
                }
                if (trending != null) {
                    trending /= num;
                }
            }
            var iter = _getIterator();
            // Print out the next entry in the iterator
            if (iter != null) {
                var sample = iter.next();
                if ((sample != null) && (sample has :data)) {
                    var d = sample.data;
                    var c = 0;
                    if (trending != null && d != null) {
                        c = trending > d ? -1 : 1;
                    }
                    return [d, c];
                }
            }
            return [null, 0];
        }

    }

}
