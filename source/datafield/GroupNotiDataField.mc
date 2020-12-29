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

    //////////////////////
    // Group noti stage //
    //////////////////////

    class GroupNotiDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var settings = Sys.getDeviceSettings();
            var notificationCount = settings.notificationCount.format("%d");
            var alarmCount = settings.alarmCount.format("%d");
            var phoneConnected = settings.phoneConnected ? "C" : "D";

            return Lang.format("N$1$-D$2$-$3$", [notificationCount, alarmCount, phoneConnected]);
        }
    }

}
