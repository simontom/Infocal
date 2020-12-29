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

    class BaseDataField {

        function initialize(id) {
            _field_id = id;
        }

        private var _field_id;

        function field_id() {
            return _field_id;
        }

        function have_secondary() {
            return false;
        }

        function min_val() {
            return 0.0;
        }

        function max_val() {
            return 100.0;
        }

        function cur_val() {
            return 0.01;
        }

        function min_label(value) {
            return "0";
        }

        function max_label(value) {
            return "100";
        }

        function cur_label(value) {
            return "0";
        }

        function need_draw() {
            return true;
        }

        function bar_data() {
            return false;
        }
    }

}
