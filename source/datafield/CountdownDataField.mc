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

    /////////////////////
    // Countdown stage //
    /////////////////////

    class CountdownDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var set_end_date = new Time.Moment(App.getApp().getProperty("countdown_date"));
            var now_d = new Time.Moment(Time.today().value());
            var dif_e_n = -(now_d.compare(set_end_date)) / 86400;

            if (dif_e_n > 1 || dif_e_n < -1) {
                return Lang.format("$1$ days",[dif_e_n.toString()]);
            }

            return Lang.format("$1$ day",[dif_e_n.toString()]);
        }
    }

}
