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

// TODO: Move to proper modules / classes
var smallDigitalFont = null;
var second_digi_font = null;
var second_x = 160;
var second_y = 140;
var heart_x = 80;

var second_font_height_half = 7;
var second_background_color = 0x000000;
var second_font_color = 0xFFFFFF;
var second_clip_size = null;

// Theming
var last_theme_code = -1;
var gbackground_color = 0x000000;
var gmain_color = 0xFFFFFF;
var gsecondary_color = 0xFF0000;
var garc_color = 0x555555;
var gbar_color_indi = 0xAAAAAA;
var gbar_color_back = 0x550000;
var gbar_color_0 = 0xFFFF00;
var gbar_color_1 = 0x0000FF;

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
    	smallDigitalFont = WatchUi.loadResource(Rez.Fonts.smadigi);
    	RD.centerX = dc.getWidth() / 2;
    	RD.centerY = dc.getHeight() / 2;

    	face_radius = RD.centerX - (18 * RD.centerX / 120).toNumber();

        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	 var clockTime = System.getClockTime();

    	last_draw_minute = -1;
    	restore_from_resume = true;
    	last_resume_mili = System.getTimer();

		checkBackgroundRequest();
    }

    // Update the view
    function onUpdate(dc) {
    	var clockTime = System.getClockTime();
    	var current_tick = System.getTimer();
    	var time_now = Time.now();

    	RD.batteryDataProvider.calculateBatteryConsumption(time_now);

        var always_on_style = Application.getApp().getProperty("always_on_style");
        if (always_on_style == SE.ALWAYS_ON_STYLE_SMALL) {
            second_digi_font = WatchUi.loadResource(Rez.Fonts.secodigi);
            second_font_height_half = 7;
            second_clip_size = [20, 15];
        } else {
            second_digi_font = WatchUi.loadResource(Rez.Fonts.xsecodigi);
            second_font_height_half = 14;
            second_clip_size = [26, 22];
        }

    	RD.forceRenderComponent = true;
		// normal power mode
		if (restore_from_resume) {
			var current_mili = current_tick;
			RD.forceRenderComponent = true;

			// will allow watch face to refresh in 5s when resumed (`onShow()` called)
			if ((current_mili - last_resume_mili) > 5000) {
				restore_from_resume = false;
			}
		}

		RD.forceRenderComponent = true;
		if (clockTime.min != last_draw_minute) {
			// Only check background web request every 1 minute
			checkBackgroundRequest();
		}

		mainDrawComponents(dc);
		last_draw_minute = clockTime.min;
    	RD.forceRenderComponent = false;

    	onPartialUpdate(dc);
    }

	function mainDrawComponents(dc) {
		checkTheme();

		if (RD.forceRenderComponent) {
			dc.setColor(Graphics.COLOR_TRANSPARENT, gbackground_color);
			dc.clear();
			dc.setColor(gbackground_color, Graphics.COLOR_TRANSPARENT);
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

        dc.setColor(gbackground_color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(RD.centerX, RD.centerY, face_radius);

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

        // Call the parent onUpdate function to redraw the layout
        var digitalDisplay = View.findDrawableById("digital");
		digitalDisplay.draw(dc);
	}

    // Gets called once per second but the mustn't exceed 30ms
	function onPartialUpdate(dc) {
		if (Application.getApp().getProperty("always_on_second")) {
			var clockTime = System.getClockTime();
			var second_text = clockTime.sec.format(Constants.ZeroLeadingFormat);
			var ss = dc.getTextDimensions(second_text, second_digi_font);

			dc.setClip(second_x, second_y, second_clip_size[0], second_clip_size[1]);
			dc.setColor(Graphics.COLOR_TRANSPARENT, gbackground_color);
			dc.clear();
			dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
			dc.drawText(second_x, second_y-font_padding,
						second_digi_font,
						second_text,
						Graphics.TEXT_JUSTIFY_LEFT);
			dc.clearClip();
		}

		if (Application.getApp().getProperty("always_on_heart")) {
			var h = DF.retrieveHeartRate();
			var heart_text = "--";
			if (h != null) {
				heart_text = h.format("%d");
			}
			var ss = dc.getTextDimensions(heart_text, second_digi_font);
			var s = (ss[0] * 1.2).toNumber();
			var s2 = (second_clip_size[0] * 1.25).toNumber();
			dc.setClip(heart_x-s2-1, second_y, s2+2, second_clip_size[1]);
			dc.setColor(Graphics.COLOR_TRANSPARENT, gbackground_color);
			dc.clear();

			dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
			dc.drawText(heart_x-1, second_y-font_padding,
						second_digi_font,
						heart_text,
						Graphics.TEXT_JUSTIFY_RIGHT);
			dc.clearClip();
		}
	}

    // The user has just looked at their watch. Timers and animations may be started here
    // If in low energy mode, onUpdate gets called once per second I think
    function onExitSleep() {
    	checkBackgroundRequest();
    }

	function checkTheme() {
		var theme_code = Application.getApp().getProperty("theme_code");

		if (last_theme_code == -1 || last_theme_code != theme_code) {
			var theme_pallete = WatchUi.loadResource(Rez.JsonData.theme_pallete);
			var theme = theme_pallete["" + theme_code];
			gbackground_color = theme[0];
			gmain_color = theme[1];
			gsecondary_color = theme[2];
			garc_color = theme[3];
			gbar_color_indi = theme[4];
			gbar_color_back = theme[5];
			gbar_color_0 = theme[6];
			gbar_color_1 = theme[7];
		}
	}

	function checkBackgroundRequest() {
		if (ErrorsAndTrialsApp has :checkPendingWebRequests) { // checkPendingWebRequests() can be excluded to save memory.
			App.getApp().checkPendingWebRequests(); // Depends on mDataFields.hasField().
		}
	}

}
