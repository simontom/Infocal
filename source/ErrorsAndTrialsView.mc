using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang as Ex;
using RuntimeData as RD;
using Toybox.Time.Gregorian as Date;
using Toybox.Application as App;
using Toybox.ActivityMonitor as Mon;
using Toybox.UserProfile;
using DataField as DF;
using SettingsEnums as SE;

class ErrorsAndTrialsView extends WatchUi.WatchFace {

	var last_draw_minute = -1;
	var restore_from_resume = false;
	var last_resume_mili = 0;

	var font_padding = 12;
	var font_height_half = 7;

	var face_radius;

	var did_clear = false;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    	RD.centerX = dc.getWidth() / 2;
    	RD.centerY = dc.getHeight() / 2;
    	face_radius = RD.centerX - (18 * RD.centerX / 120).toNumber();

        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        last_draw_minute = -1;
        restore_from_resume = true;
        last_resume_mili = System.getTimer();

        App.getApp().checkPendingWebRequests();
    }

    // Update the view
    function onUpdate(dc) {
    	var clockTime = System.getClockTime();
    	var current_tick = System.getTimer();
    	var time_now = Time.now();

    	RD.batteryDataProvider.calculateBatteryConsumption(time_now);

        // RD.forceRenderComponent = true;
		// normal power mode
		if (restore_from_resume) {
			var current_mili = current_tick;

			RD.forceRenderComponent = true;

			// will allow watch face to refresh in 5s when resumed (`onShow()` called)
			if ((current_mili - last_resume_mili) > 5000) {
				restore_from_resume = false;
			}
		}

        // INFO: Moved into IF to save some re-rendering
		// RD.forceRenderComponent = true;
		if (clockTime.min != last_draw_minute) {
            RD.forceRenderComponent = true;
			// Only check background web request every 1 minute
			App.getApp().checkPendingWebRequests();
		}

		mainDrawComponents(dc);
		last_draw_minute = clockTime.min;
    	RD.forceRenderComponent = false;

    	onPartialUpdate(dc);
    }

	function mainDrawComponents(dc) {
        if (RD.forceRenderComponent) {
            // dc.setColor(Graphics.COLOR_TRANSPARENT, RD.themeDataProvider.gbackground_color);
            // dc.clear();

            dc.setColor(RD.themeDataProvider.gbackground_color, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, RD.centerX * 2, RD.centerY * 2);
        }

		var bar1 = View.findDrawableById("aBarDisplay");
		var bar2 = View.findDrawableById("bBarDisplay");
		var bar3 = View.findDrawableById("cBarDisplay");
		var bar4 = View.findDrawableById("dBarDisplay");
		var bar5 = View.findDrawableById("eBarDisplay");
		var bar6 = View.findDrawableById("fBarDisplay");
		bar1.draw(dc);
		bar2.draw(dc);
		bar3.draw(dc);
		bar4.draw(dc);
		bar5.draw(dc);
		bar6.draw(dc);

        // dc.setColor(RD.themeDataProvider.gbackground_color, Graphics.COLOR_TRANSPARENT);
        // dc.setColor(RD.themeDataProvider.gmain_color, RD.themeDataProvider.gsecondary_color); // pokus
        // dc.fillCircle(RD.centerX, RD.centerY, face_radius);

        var backgroundView = View.findDrawableById("background");
		backgroundView.draw(dc);

        var bbar1 = View.findDrawableById("bUBarDisplay");
		var bbar2 = View.findDrawableById("tUBarDisplay");
		bbar1.draw(dc);
		bbar2.draw(dc);

		var bgraph1 = View.findDrawableById("tGraphDisplay");
		var bgraph2 = View.findDrawableById("bGraphDisplay");
		bgraph1.draw(dc);
		bgraph2.draw(dc);

        var moonPhase = View.findDrawableById("moonPhase");
        moonPhase.draw(dc);

        // Call the parent onUpdate function to redraw the layout
        var digitalDisplay = View.findDrawableById("digital");
        digitalDisplay.draw(dc);
	}

    // Gets called once per second but the mustn't exceed 30ms
	function onPartialUpdate(dc) {
		if (Application.getApp().getProperty("always_on_second")) {
			var clockTime = System.getClockTime();
			var second_text = clockTime.sec.format(Constants.ZeroLeadingFormat);
			var ss = dc.getTextDimensions(second_text, RD.themeDataProvider.second_digi_font);

			dc.setClip(RD.themeDataProvider.second_x, RD.themeDataProvider.second_y,
                       RD.themeDataProvider.second_clip_size[0], RD.themeDataProvider.second_clip_size[1]);
			dc.setColor(Graphics.COLOR_TRANSPARENT, RD.themeDataProvider.gbackground_color);
			dc.clear();

			dc.setColor(RD.themeDataProvider.gmain_color, Graphics.COLOR_TRANSPARENT);
			dc.drawText(RD.themeDataProvider.second_x,
                        RD.themeDataProvider.second_y - font_padding,
						RD.themeDataProvider.second_digi_font,
						second_text,
						Graphics.TEXT_JUSTIFY_LEFT);

			dc.clearClip();
		}
	}

    // The user has just looked at their watch. Timers and animations may be started here
    // If in low energy mode, onUpdate gets called once per second I think
    function onExitSleep() {
    	App.getApp().checkPendingWebRequests();
    }
}
