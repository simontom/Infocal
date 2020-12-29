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

    /////////////////////////
    // Distance week stage //
    /////////////////////////

    class WeekDistanceDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function min_val() {
            return 50.0;
        }

        function max_val() {
            var datas = _retriveWeekValues();
            return datas[1];
        }

        function cur_val() {
            var datas = _retriveWeekValues();
            return datas[0];
        }

        function cur_label(value) {
            var datas = _retriveWeekValues();
            var cm = datas[0];

            var need_minimal = App.getApp().getProperty("minimal_data");
            var settings = Sys.getDeviceSettings();

            var distance = cm / 100000;
            var unit = "Km";

            if (settings.distanceUnits != System.UNIT_METRIC) {
                distance *= 0.621371;
                unit = "Mi";
            }

            if (need_minimal) {
                return Lang.format("$1$ $2$", [distance.format("%0.1f"), unit]);
            }

            var valKp = CU.toKValue(distance * 1000);
            return Lang.format("DIS $1$$2$", [valKp, unit]);
        }

        function day_of_week(activity) {
            var moment = activity.startOfDay;
            var date = Date.info(moment, Time.FORMAT_SHORT);
            return date.day_of_week;
        }

        function today_of_week() {
            var now = Time.now();
            var date = Date.info(now, Time.FORMAT_SHORT);
            return date.day_of_week;
        }

        function _retriveWeekValues() {
            var settings = System.getDeviceSettings();
            var firstDayOfWeek = settings.firstDayOfWeek;

            var activities = [];
            var activityInfo = ActivityMonitor.getInfo();
            activities.add(activityInfo);

            if (today_of_week() != firstDayOfWeek) {
                var his = ActivityMonitor.getHistory();
                for (var i = 0; i < his.size(); i++ ) {
                    var activity = his[i];
                    activities.add(activity);
                    if (day_of_week(activity) == firstDayOfWeek) {
                        break;
                    }
                }
            }

            var total = 0.0;
            for (var i = 0; i < activities.size();i++) {
                total += activities[i].distance;
            }
            return [total, 10.0];
        }

        function bar_data() {
            return true;
        }
    }

}
