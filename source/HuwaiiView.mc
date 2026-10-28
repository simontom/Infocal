using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Application as App;

var smallDigitalFont = null;
var bigDigitalFont = null;

var last_battery_percent = -1;
var last_hour_consumtion = -1;

class HuwaiiView extends WatchUi.WatchFace {

    var last_draw_minute = -1;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        smallDigitalFont = WatchUi.loadResource(Rez.Fonts.smadigi);
        bigDigitalFont = WatchUi.loadResource(Rez.Fonts.bigdigi);
        centerX = dc.getWidth() / 2;
        centerY = dc.getHeight() / 2;
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown.
    function onShow() {
        last_draw_minute = -1;
        checkBackgroundRequest();
    }

    // Update the view
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }

    // Called when this View is removed from the screen.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
        checkBackgroundRequest();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

    function checkBackgroundRequest() {
        if (HuwaiiApp has :checkPendingWebRequests) {
            App.getApp().checkPendingWebRequests();
        }
    }
}
