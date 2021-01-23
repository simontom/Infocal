using Toybox.WatchUi as Ui;
using RuntimeData as RD;
using SettingsEnums as SE;
using Toybox.Graphics;

module Complications {

    /* abstract */ class BarComplication extends Ui.Drawable {

        hidden var position;
        hidden var position_y_draw;
        hidden var position_y_draw_bonus;
        hidden var font;
        hidden var fontInfo;
        hidden var arrFont;
        hidden var arrInfo;
        hidden var textFont;
        hidden var weatherFont;

        private var factor = 1;

        function initialize(params) {
            Drawable.initialize(params);
            position = params.get(:position);
            if (position == SE.COMPLICATION_BAR_POSITION_TOP) {
                // up
                if (RD.centerX == 120) {
                    position_y_draw = 52; // centerY - 36 - 18 - 14; // font height 14
                    position_y_draw_bonus = -13;
                } else if (RD.centerX == 130) {
                    position_y_draw = 58; // centerY - 36 - 18 - 14 - 4; // font height 14
                    position_y_draw_bonus = -18;
                } else if (RD.centerX == 140) {
                    position_y_draw = 64; // centerY - 36 - 18 - 14 - 8; // font height 14
                    position_y_draw_bonus = -18;
                } else {
                    position_y_draw = 44; // centerY - 36 - 18 - 14 + 5; // font height 14
                    position_y_draw_bonus = -13;
                }
            } else {
                // down
                if (RD.centerX == 120) {
                    position_y_draw = 156; // centerY + 36;
                    position_y_draw_bonus = 29;
                } else if (RD.centerX == 130) {
                    position_y_draw = 170; // centerY + 36 + 4;
                    position_y_draw_bonus = 33;
                } else if (RD.centerX == 140) {
                    position_y_draw = 184; // centerY + 36 + 8;
                    position_y_draw_bonus = 33;
                } else {
                    position_y_draw = 140; // centerY + 36 - 5;
                    position_y_draw_bonus = 29;
                }
            }
        }

        function min_val() {
            return 0.0;
        }

        function max_val() {
            return 5.0;
        }

        function cur_val() {
            return 3.0;
        }

        function get_title() {
            return "Step 2577";
        }

        function get_weather_icon() {
            return null;
        }

        function need_draw() {
            return true;
        }

        function bar_data() {
            return false;
        }

        function draw(dc) {
            var is_bar_data = bar_data();
            if (is_bar_data) {
                load_font();
            }

            if (field_type == SE.FIELD_TYPE_WEATHER) {
                weatherFont = Ui.loadResource(Rez.Fonts.weather);
            } else {
                weatherFont = null;
            }

            var primaryColor = (position == SE.COMPLICATION_BAR_POSITION_BOTTOM)
                    ? RD.themeDataProvider.gbar_color_1
                    : RD.themeDataProvider.gbar_color_0;

            var bonus_padding = 0;

            if (is_bar_data) {
                var mi = min_val().toFloat(); // 0
                var ma = max_val().toFloat(); // 5
                var cu = cur_val().toFloat(); // 1

                var i = 0;
                if (cu >= ma) {
                    i = 4;
                } else if (cu <= mi) {
                    i = -1;
                } else {
                    var fraction = (cu - mi) / (ma - mi);
                    if (fraction > 0.81) {
                        i = 4;
                    } else if (fraction > 0.61) {
                        i = 3;
                    } else if (fraction > 0.41) {
                        i = 2;
                    } else if (fraction > 0.21) {
                        i = 1;
                    } else {
                        i = 0;
                    }
                }

                for (var j = 0; j <= 4; j++) {
                    if (j == i) {
                        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
                    } else {
                        dc.setColor(RD.themeDataProvider.gbar_color_back, Graphics.COLOR_TRANSPARENT);
                    }
                    drawTiles(fontInfo[j], font, dc);
                }

                if (i >= 0) {
                    dc.setColor(RD.themeDataProvider.gbar_color_indi, Graphics.COLOR_TRANSPARENT);
                    drawTiles(arrInfo[i], arrFont, dc);
                }
            } else if (field_type == SE.FIELD_TYPE_WEATHER) {
                var icon = get_weather_icon();
                if (icon != null) {
                    dc.setColor(RD.themeDataProvider.gmain_color, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(RD.centerX, position_y_draw + position_y_draw_bonus, weatherFont, icon,
                            Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
                }
                bonus_padding = position == 0 ? 2 : -2;
            } else {
                bonus_padding = position == 0 ? -7 : 5;
            }

            var title = get_title();
            if (title == null) {
                title = "--";
            }

            title = title.toUpper();
            dc.setColor(RD.themeDataProvider.gmain_color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(RD.centerX, position_y_draw+bonus_padding, RD.themeDataProvider.smallDigitalFont, title, Graphics.TEXT_JUSTIFY_CENTER);

            font = null;
            fontInfo = null;
            arrFont = null;
            arrInfo = null;
            weatherFont = null;
        }

        private function drawTiles(packed_array, font, dc) {
            for(var i = 0; i < packed_array.size(); i++) {
                var val = packed_array[i];
                var char = (val >> 16) & 255;
                var xpos = (val >> 8) & 255;
                var ypos = (val >> 0) & 255;
                var flag = (val >> 24) & 255;
                var xpos_bonus = (flag & 0x01) == 0x01 ? 1 : 0;
                var ypos_bonus = (flag & 0x10) == 0x10 ? 1 : 0;

                dc.drawText(
                        (xpos * factor + xpos_bonus).toNumber(),
                        (ypos * factor + ypos_bonus).toNumber(),
                        font, char.toNumber().toChar(), Graphics.TEXT_JUSTIFY_LEFT);
            }
        }

        private function load_font() {
            if (position == SE.COMPLICATION_BAR_POSITION_TOP) {
                font = Ui.loadResource(Rez.Fonts.cur_up);
                arrFont = Ui.loadResource(Rez.Fonts.arr_up);
                fontInfo = Ui.loadResource(Rez.JsonData.bar_font_top);
                arrInfo = Ui.loadResource(Rez.JsonData.bar_pos_top);
            } else if (position == SE.COMPLICATION_BAR_POSITION_BOTTOM) {
                font = Ui.loadResource(Rez.Fonts.cur_bo);
                arrFont = Ui.loadResource(Rez.Fonts.arr_bo);
                fontInfo = Ui.loadResource(Rez.JsonData.bar_font_bottom);
                arrInfo = Ui.loadResource(Rez.JsonData.bar_pos_bottom);
            }
        }
    }

}
