using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.Application;
using ConversionUtils as CU;
using RuntimeData as RD;
using SettingsEnums as SE;

class BackgroundView extends Ui.Drawable {

    private var bgcir_font, bgcir_info;
    var radius;

    function initialize(params) {
        Drawable.initialize(params);
        radius = RD.centerX - (10 * RD.centerX / 120).toNumber();
    }

    function draw(dc) {
        drawMarks(dc);
        drawTicks(dc);
    }

    private function drawMarks(dc) {
        dc.setPenWidth(4);
        dc.setColor(gsecondary_color, Graphics.COLOR_TRANSPARENT);

        for(var i = 0; i < 6; i += 1) {
            var rad = (i.toFloat() / 6.0) * 2 * Math.PI;
            dc.drawLine(
                CU.convertCoorX(rad, radius - 5),
                CU.convertCoorY(rad, radius - 5),
                CU.convertCoorX(rad, radius + 5),
                CU.convertCoorY(rad, radius + 5)
            );
        }
    }

    private function drawTicks(dc) {
        var ticks_style = Application.getApp().getProperty("ticks_style");
        var digital_style = Application.getApp().getProperty("digital_style");
        var left_digital_info = Application.getApp().getProperty("left_digital_info");

        if (ticks_style == SE.TICKS_STYLE_EMPTY) {
            return;
        } else if (ticks_style == SE.TICKS_STYLE_ARC) {
            var excluded = 0;

            if (digital_style == SE.DIGITAL_STYLE_SMALL || digital_style == SE.DIGITAL_STYLE_MEDIUM) {
                excluded = -1;
            } else if (left_digital_info) {
                excluded = 2;
            }

            dc.setPenWidth(2);
            dc.setColor(garc_color, Graphics.COLOR_TRANSPARENT);
            for(var i = 0; i < 6; i += 1) {
                if (i == excluded) {
                    continue;
                }

                var rad = (i.toFloat() / 6.0) * 360;
                dc.drawArc(
                    RD.centerX,
                    RD.centerY,
                    radius - 15,
                    dc.ARC_COUNTER_CLOCKWISE,
                    rad + 5,
                    rad + 55
                );
            }
        } else if (ticks_style == SE.TICKS_STYLE_MARKS) {
            dc.setColor(garc_color, Graphics.COLOR_TRANSPARENT);
            var bonus = 0;
            if (RD.centerX == 130) {
                bonus = 2;
            } else if (RD.centerX == 140) {
                bonus = 3;
            } else if (RD.centerX == 109) {
                bonus = -2;
            }

            for(var i = 0; i < 12 * 5; i += 1) {
                if (digital_style == SE.DIGITAL_STYLE_XBIG || digital_style == SE.DIGITAL_STYLE_BIG) {
                    if (left_digital_info) {
                        if (i > 45 && i < 55) { continue; }
                    } else {
                        if (i > 5 && i < 15) { continue; }
                    }
                }

                var rad = (i.toFloat() / (5 * 12.0)) * 2 * Math.PI - 0.5 * Math.PI;
                if (i % 5 == 0) {
                    dc.setPenWidth(3);
                } else {
                    dc.setPenWidth(1);
                }

                dc.drawLine(
                    CU.convertCoorX(rad, radius - 20 - bonus),
                    CU.convertCoorY(rad, radius - 20 - bonus),
                    CU.convertCoorX(rad, radius - 13),
                    CU.convertCoorY(rad, radius - 13)
                );
            }
        }
    }
}
