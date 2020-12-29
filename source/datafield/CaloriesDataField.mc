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

    ////////////////////
    // Calories stage //
    ////////////////////

    class CaloriesDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function max_val() {
            return 3000.0;
        }

        function cur_val() {
            var activityInfo = ActivityMonitor.getInfo();
            return activityInfo.calories.toFloat();
        }

        function max_label(value) {
            var valKp = CU.toKValue(value);
            return Lang.format("$1$K",[valKp]);
        }

        function cur_label(value) {
            var activeCalories = active_calories(value);
            var need_minimal = App.getApp().getProperty("minimal_data");

            if (need_minimal) {
                return Lang.format("$1$-$2$",[value.format("%d"), activeCalories.format("%d")]);
            }

            var valKp = CU.toKValue(value);
            return Lang.format("$1$K-$2$",[valKp, activeCalories.format("%d")]);
        }

        function active_calories(value) {
            var now = Time.now();
            var date = Date.info(now, Time.FORMAT_SHORT);

            var profile = UserProfile.getProfile();
            // var bonus = profile.gender == UserProfile.GENDER_MALE ? 5.0 : -161.0;
            var age = (date.year-profile.birthYear).toFloat();
            var weight = profile.weight.toFloat()/1000.0;
            var height = profile.height.toFloat();

            // var bmr = 0.01*weight + 6.25*height + 5.0*age + bonus; // method 1
            var bmr = -6.1 * age + 7.6 * height + 12.1 * weight + 9.0; // method 2
            var current_segment = (date.hour * 60.0 + date.min).toFloat() / 1440.0;
            // var nonActiveCalories = 1.604*bmr*current_segment; // method 1
            var nonActiveCalories = 1.003 * bmr * current_segment; // method 2
            var activeCalories = value - nonActiveCalories;

            activeCalories = ((activeCalories > 0) ? activeCalories : 0).toNumber();

            return activeCalories;
        }

        function bar_data() {
            return true;
        }
    }

}
