using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System;
using RuntimeData as RD;
using SettingsEnums as SE;
using Toybox.Lang as Ex;

class MainDialHand extends Ui.Drawable {

	////////////////////////
    /// common variables ///
    ////////////////////////

	private var digitalFont;
    private var xdigitalFont;
	private var midDigitalFont;
	private var midBoldFont;
	private var midSemiFont;
	private var xmidBoldFont;
	private var xmidSemiFont;
	private var barRadius;

	///////////////////////////////
    /// non-antialias variables ///
    ///////////////////////////////

	private var alignment;
	private var bonusy_smallsize;

	function initialize(params) {
        Drawable.initialize(params);
        barRadius = RD.centerX - 10;
        alignment = Graphics.TEXT_JUSTIFY_VCENTER|Graphics.TEXT_JUSTIFY_CENTER;

        bonusy_smallsize = 0;
    }

    function draw(dc) {
    	// possibly remove all font to save memory
    	checkCurrentFont();

    	var currentSettings = System.getDeviceSettings();
    	var clockTime = System.getClockTime();
    	var hour = clockTime.hour;
    	if(!(currentSettings.is24Hour)) {
			hour = hour % 12;
        	hour = (hour == 0) ? 12 : hour;
        }
		var minute = clockTime.min;

		var digital_style = Application.getApp().getProperty("digital_style");
		var alwayon_style = Application.getApp().getProperty("always_on_style");
		if (digital_style == SE.DIGITAL_STYLE_BIG || digital_style == SE.DIGITAL_STYLE_XBIG) { // big or extra big
			var bignumber = Application.getApp().getProperty("big_number_type") == SE.BIG_NUMBER_TYPE_MINUTE_IN_CENTER ? minute : hour;
			var smallnumber = Application.getApp().getProperty("big_number_type") == SE.BIG_NUMBER_TYPE_MINUTE_IN_CENTER ? hour : minute;

			var target_center_font = digital_style == SE.DIGITAL_STYLE_BIG ? digitalFont : xdigitalFont;

			// DRAW CENTER
	    	var bigText = bignumber.format(Constants.ZeroLeadingFormat);
	    	dc.setPenWidth(1);
	    	dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
	    	var h = dc.getFontHeight(target_center_font);
	    	var w = dc.getTextWidthInPixels(bigText, target_center_font);
	    	dc.drawText(RD.centerX, RD.centerY - h / 4, target_center_font, bigText, alignment);

	    	// DRAW STRIPES
	    	if (Application.getApp().getProperty("big_num_stripes")) {
		    	dc.setColor(gbackground_color, Graphics.COLOR_TRANSPARENT);
		    	var w2 = dc.getTextWidthInPixels("\\", target_center_font);
		    	dc.drawText(RD.centerX + w2 -w / 2, RD.centerY - h / 4, target_center_font, "\\", Graphics.TEXT_JUSTIFY_VCENTER);
	    	}

	    	var f_align = digital_style == SE.DIGITAL_STYLE_BIG ? 62 : 71;

	    	second_x = RD.centerX + w / 2 + 3;
	    	heart_x = RD.centerX - w / 2 - 3;

	    	if (RD.centerX == 109 && digital_style == SE.DIGITAL_STYLE_XBIG) {
	    		second_y  = RD.centerY - second_font_height_half / 2 - (alwayon_style == SE.ALWAYS_ON_STYLE_SMALL ? 3 : 6);
	    	} else {
	    		second_y  = RD.centerY + (h - f_align) / 2 - second_font_height_half * 2 + (alwayon_style == SE.ALWAYS_ON_STYLE_SMALL ? 0 : 5);
	    	}
	    	// DRAW INFOS

	    	// calculate alignment
	    	var bonus_alignment = 0;
	    	var extra_info_alignment = 0;
	    	var vertical_alignment = 0;
	    	if (RD.centerX == 109) {
	    		bonus_alignment = 4;
	    		if (digital_style == SE.DIGITAL_STYLE_XBIG) {
	    			bonus_alignment = 4;
	    			vertical_alignment = -23;
	    		}
	    	} else if (RD.centerX == 120 && digital_style == SE.DIGITAL_STYLE_XBIG) {
	    		bonus_alignment = 6;
	    		extra_info_alignment = 4;
	    	}
	    	var target_info_x = RD.centerX * 1.6;
	    	if (Application.getApp().getProperty("left_digital_info")) {
	    		target_info_x = RD.centerX * 0.4;
	    		bonus_alignment = -bonus_alignment;
	    		extra_info_alignment = -extra_info_alignment;
	    	}

	    	// draw background of date
	    	// this is a need to prevent power save mode not re-render

	    	dc.setColor(gbackground_color, Graphics.COLOR_TRANSPARENT);
    		dc.setPenWidth(20);
	    	if (Application.getApp().getProperty("left_digital_info")) {
				dc.drawArc(RD.centerX, RD.centerY, barRadius, Graphics.ARC_CLOCKWISE, 180 - 10, 120 + 10);
	    	} else {
	    		dc.drawArc(RD.centerX, RD.centerY, barRadius, Graphics.ARC_CLOCKWISE, 60 - 10, 0 + 10);
	    	}
	    	dc.setPenWidth(1);

	    	// draw secondary info
	    	dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
	    	var h2 = dc.getFontHeight(midDigitalFont);
	    	dc.drawText(target_info_x + bonus_alignment, RD.centerY * 0.7 - h2 / 4 + 5 + vertical_alignment,
                    midDigitalFont, smallnumber.format(Constants.ZeroLeadingFormat), alignment);

	    	if (RD.centerX == 109 && digital_style == SE.DIGITAL_STYLE_XBIG) {
	    		return;
	    	}

			// draw date str
			var dateText = RD.formattedDateDataProvider.getFormattedDate();
			dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
			var h3 = dc.getFontHeight(smallDigitalFont);
			dc.drawText(target_info_x-bonus_alignment+extra_info_alignment, RD.centerY * 0.4 - h3 / 4 + 7, smallDigitalFont, dateText, alignment);

			// horizontal line
			var w3 = dc.getTextWidthInPixels(dateText, smallDigitalFont);
			dc.setPenWidth(2);
			dc.setColor(gsecondary_color, Graphics.COLOR_TRANSPARENT);
			dc.drawLine(target_info_x - bonus_alignment - w3 / 2 + extra_info_alignment, RD.centerY * 0.5 + 7,
                    target_info_x-bonus_alignment + w3 / 2 + extra_info_alignment, RD.centerY * 0.5 + 7);

		} else if (digital_style == SE.DIGITAL_STYLE_SMALL || digital_style == SE.DIGITAL_STYLE_MEDIUM) {
			var hourText = hour.format(Constants.ZeroLeadingFormat);
			var minuText = minute.format(Constants.ZeroLeadingFormat);

			var bonus = digital_style == SE.DIGITAL_STYLE_MEDIUM ? -13 : 0;
			var boldF = digital_style == SE.DIGITAL_STYLE_MEDIUM ? xmidBoldFont : midBoldFont;
			var normF = digital_style == SE.DIGITAL_STYLE_MEDIUM ? xmidSemiFont : midSemiFont;

			var hourW = dc.getTextWidthInPixels(hourText, boldF).toFloat();
			var h = dc.getFontHeight(boldF).toFloat();
			var minuW = dc.getTextWidthInPixels(minuText, normF).toFloat();
			var half = (hourW+minuW + 6.0)/2.0;
			var left = RD.centerX - half;

			dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
			dc.drawText(left.toNumber(), RD.centerY - 70 + bonus + bonusy_smallsize, boldF, hourText, Graphics.TEXT_JUSTIFY_LEFT);
			dc.drawText((left + hourW + 6.0).toNumber(), RD.centerY - 70 + bonus+bonusy_smallsize, normF, minuText, Graphics.TEXT_JUSTIFY_LEFT);

			var f_align = 40;
	    	second_x = RD.centerX + half + 1;
	    	heart_x = RD.centerX - half - 1;

	    	second_y = RD.centerY - second_font_height_half/2 - (alwayon_style == 0 ? 3 : 6);
		}

		removeFont();
    }

    private function checkCurrentFont() {
    	var digital_style = Application.getApp().getProperty("digital_style");

        switch (digital_style) {
            case SE.DIGITAL_STYLE_BIG:
                midBoldFont = null;
                midSemiFont = null;
                xmidBoldFont = null;
                xmidSemiFont = null;
                xdigitalFont = null;
                if (digitalFont == null) {
                    digitalFont = Ui.loadResource(Rez.Fonts.bigdigi);
                    midDigitalFont = Ui.loadResource(Rez.Fonts.middigi);
                }
            break;

            case SE.DIGITAL_STYLE_SMALL:
                xdigitalFont = null;
                digitalFont = null;
                xmidBoldFont = null;
                xmidSemiFont = null;
                midDigitalFont = null;
                if(midBoldFont == null) {
                    midBoldFont = Ui.loadResource(Rez.Fonts.midbold);
                    midSemiFont = Ui.loadResource(Rez.Fonts.midsemi);
                }
            break;

            case SE.DIGITAL_STYLE_XBIG:
                midBoldFont = null;
                midSemiFont = null;
                digitalFont = null;
                xmidBoldFont = null;
                xmidSemiFont = null;
                if (xdigitalFont == null) {
                    xdigitalFont = Ui.loadResource(Rez.Fonts.xbigdigi);
                    midDigitalFont = Ui.loadResource(Rez.Fonts.middigi);
                }
            break;

            case SE.DIGITAL_STYLE_MEDIUM:
                xdigitalFont = null;
                digitalFont = null;
                midBoldFont = null;
                midSemiFont = null;
                midDigitalFont = null;
                if(xmidBoldFont == null) {
                    xmidBoldFont = Ui.loadResource(Rez.Fonts.xmidbold);
                    xmidSemiFont = Ui.loadResource(Rez.Fonts.xmidsemi);
                }
            break;

            default:
                throw new Ex.InvalidValueException("Invalid value of 'digital_style' in ':checkCurrentFont'");
        }
    }

    private function removeFont() {
    	midBoldFont = null;
		midSemiFont = null;
		xmidBoldFont = null;
		xmidSemiFont = null;
		xdigitalFont = null;
		digitalFont = null;
		midDigitalFont = null;
    }
}
