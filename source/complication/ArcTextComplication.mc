using Toybox.WatchUi as Ui;
using Toybox.Math;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Application;
using RuntimeData as RD;

class ArcTextComplication extends Ui.Drawable {

    hidden var barRadius;
    hidden var baseRadian;
    hidden var baseDegree;
    hidden var alignment;
    hidden var font;
    hidden var perCharRadius;
    hidden var text;
    hidden var last_draw_text;
    hidden var curved_radian;

    var accumulation_sign;
    var angle;
    var kerning = 1.0;

    function initialize(params) {
        Drawable.initialize(params);
    	barRadius = centerX - (13*centerX/120).toNumber();
    	if (centerX == 109) {
    		kerning = 1.1;
    		barRadius = centerX-11;
    	} else if (centerX == 130) {
    		kerning = 0.95;
    	} else if (centerX == 195) {
    		kerning = 0.95;
    		barRadius = barRadius+4;
    	}

    	baseDegree = params.get(:base);
    	baseRadian = degreesToRadians(baseDegree);
    	curved_radian = 60.0;

    	text = params.get(:text);
    	angle = params.get(:angle);
    	perCharRadius = kerning*4.70*Math.PI/100;
    	barRadius += ((baseDegree < 180 ? 8 : -3)*centerX/120).toNumber();
    	accumulation_sign = (baseDegree < 180 ? -1 : 1);

    	alignment = Graphics.TEXT_JUSTIFY_VCENTER|Graphics.TEXT_JUSTIFY_CENTER;

		last_draw_text = "";
    }

    function get_text() {
    	return text;
    }

    function need_draw() {
		return true;
	}

    function draw(dc) {

    	dc.setPenWidth(1);

    	var text = get_text();


    	if (last_draw_text.equals(text) && !RD.forceRenderComponent) {
    		// do not draw
    	} else {
    		dc.setColor(gbackground_color, Graphics.COLOR_TRANSPARENT);

    		dc.setPenWidth(20);
    		var target_r = barRadius-((baseDegree < 180 ? 6 : -3)*centerX/120).toNumber();
			dc.drawArc(centerX, centerY, target_r, Graphics.ARC_CLOCKWISE, 360.0-(baseDegree-30.0), 360.0-(baseDegree+30.0));

			dc.setPenWidth(1);
			dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);

    		drawArcText(dc, text);
    		last_draw_text = text;
    	}
    }

    hidden function drawArcText(dc, text) {
    	var totalChar = text.length().toFloat();
    	var charArray = text.toUpper().toCharArray();

    	var totalRad = 0.0;
    	for (var i=0; i<totalChar; i++) {
    		var ra = perCharRadius * Complications.kerningRatios[charArray[i]];
    		totalRad += ra;
    	}
    	var lastRad = -totalRad/2.0;

    	for (var i=0; i < totalChar; i++) {
    		var ra = perCharRadius * Complications.kerningRatios[charArray[i]];

			lastRad += ra;
			if (charArray[i] == ' ') {
			} else {
				var centering = ra/2.0;
	    		var targetRadian = baseRadian + (lastRad-ra/2.0)*accumulation_sign;

	    		var labelCurX = convertCoorX(targetRadian, barRadius);
	    		var labelCurY = convertCoorY(targetRadian, barRadius);

	    		set_font(targetRadian);

	    		dc.drawText(labelCurX, labelCurY, font, charArray[i], alignment);
	    		font = null;
    		}
    	}
    }

    function set_font(current_rad) {
    	var converted = current_rad + Math.PI;
    	var degree = radiansToDegrees(converted).toNumber();
    	var idx = ((degree % 180) / 3).toNumber();
    	font = get_font(idx);
    }

    function get_font(idx) {
    	switch (idx) {
            case 0: return Ui.loadResource(Rez.Fonts.e0);
            case 1: return Ui.loadResource(Rez.Fonts.e1);
            case 2: return Ui.loadResource(Rez.Fonts.e2);
            case 3: return Ui.loadResource(Rez.Fonts.e3);
            case 4: return Ui.loadResource(Rez.Fonts.e4);
            case 5: return Ui.loadResource(Rez.Fonts.e5);
            case 6: return Ui.loadResource(Rez.Fonts.e6);
            case 7: return Ui.loadResource(Rez.Fonts.e7);
            case 8: return Ui.loadResource(Rez.Fonts.e8);
            case 9: return Ui.loadResource(Rez.Fonts.e9);
            case 10: return Ui.loadResource(Rez.Fonts.e10);
            case 11: return Ui.loadResource(Rez.Fonts.e11);
            case 12: return Ui.loadResource(Rez.Fonts.e12);
            case 13: return Ui.loadResource(Rez.Fonts.e13);
            case 14: return Ui.loadResource(Rez.Fonts.e14);
            case 15: return Ui.loadResource(Rez.Fonts.e15);
            case 16: return Ui.loadResource(Rez.Fonts.e16);
            case 17: return Ui.loadResource(Rez.Fonts.e17);
            case 18: return Ui.loadResource(Rez.Fonts.e18);
            case 19: return Ui.loadResource(Rez.Fonts.e19);
            case 20: return Ui.loadResource(Rez.Fonts.e20);
            case 21: return Ui.loadResource(Rez.Fonts.e21);
            case 22: return Ui.loadResource(Rez.Fonts.e22);
            case 23: return Ui.loadResource(Rez.Fonts.e23);
            case 24: return Ui.loadResource(Rez.Fonts.e24);
            case 25: return Ui.loadResource(Rez.Fonts.e25);
            case 26: return Ui.loadResource(Rez.Fonts.e26);
            case 27: return Ui.loadResource(Rez.Fonts.e27);
            case 28: return Ui.loadResource(Rez.Fonts.e28);
            case 29: return Ui.loadResource(Rez.Fonts.e29);
            case 30: return Ui.loadResource(Rez.Fonts.e30);
            case 31: return Ui.loadResource(Rez.Fonts.e31);
            case 32: return Ui.loadResource(Rez.Fonts.e32);
            case 33: return Ui.loadResource(Rez.Fonts.e33);
            case 34: return Ui.loadResource(Rez.Fonts.e34);
            case 35: return Ui.loadResource(Rez.Fonts.e35);
            case 36: return Ui.loadResource(Rez.Fonts.e36);
            case 37: return Ui.loadResource(Rez.Fonts.e37);
            case 38: return Ui.loadResource(Rez.Fonts.e38);
            case 39: return Ui.loadResource(Rez.Fonts.e39);
            case 40: return Ui.loadResource(Rez.Fonts.e40);
            case 41: return Ui.loadResource(Rez.Fonts.e41);
            case 42: return Ui.loadResource(Rez.Fonts.e42);
            case 43: return Ui.loadResource(Rez.Fonts.e43);
            case 44: return Ui.loadResource(Rez.Fonts.e44);
            case 45: return Ui.loadResource(Rez.Fonts.e45);
            case 46: return Ui.loadResource(Rez.Fonts.e46);
            case 47: return Ui.loadResource(Rez.Fonts.e47);
            case 48: return Ui.loadResource(Rez.Fonts.e48);
            case 49: return Ui.loadResource(Rez.Fonts.e49);
            case 50: return Ui.loadResource(Rez.Fonts.e50);
            case 51: return Ui.loadResource(Rez.Fonts.e51);
            case 52: return Ui.loadResource(Rez.Fonts.e52);
            case 53: return Ui.loadResource(Rez.Fonts.e53);
            case 54: return Ui.loadResource(Rez.Fonts.e54);
            case 55: return Ui.loadResource(Rez.Fonts.e55);
            case 56: return Ui.loadResource(Rez.Fonts.e56);
            case 57: return Ui.loadResource(Rez.Fonts.e57);
            case 58: return Ui.loadResource(Rez.Fonts.e58);
            case 59: return Ui.loadResource(Rez.Fonts.e59);
            case 60: return Ui.loadResource(Rez.Fonts.e60);
        }
    }
}
