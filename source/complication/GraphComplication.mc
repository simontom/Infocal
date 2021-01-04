using Toybox.WatchUi as Ui;
using ConversionUtils as CU;
using RuntimeData as RD;
using SettingsEnums as SE;
using Toybox.Lang as Ex;
using Toybox.Math;
using Toybox.System;
using Toybox.Graphics;

module Complications {

    class GraphComplication extends Ui.Drawable {

        hidden var position;
        hidden var position_x;
        hidden var position_y;
        hidden var graph_width;
        hidden var graph_height;
        var settings;

        function initialize(params) {
            Drawable.initialize(params);

            position = params.get(:position);
            if (position == SE.COMPLICATION_GRAPH_POSITION_TOP) {
                position_x = RD.centerX;
                position_y = 0.5 * RD.centerY;
            } else if (position == SE.COMPLICATION_GRAPH_POSITION_BOTTOM) {
                position_x = RD.centerX;
                position_y = 1.45 * RD.centerY;
            }

            graph_width = 90;
            graph_height = Math.round(0.25 * RD.centerX);
        }

        function need_draw() {
            return get_data_type() > 0;
        }

        function parse_data_value(type, value) {
            switch (type) {
                case SE.GRAPH_FIELD_TYPE_HEARTRATE:
                    return value;

                case SE.GRAPH_FIELD_TYPE_ALTITUDE:
                    if (settings.elevationUnits == System.UNIT_METRIC) {
                        // Metres
                        return value;
                    } else {
                        // Feet
                        return  value * 3.28084;
                    }

                case SE.GRAPH_FIELD_TYPE_BAROMETER:
                    return value / 100.0;

                case SE.GRAPH_FIELD_TYPE_TEMPERATURE:
                    if (settings.temperatureUnits == System.UNIT_STATUTE) {
                    return CU.toFahrenheit(value);
                } else {
                    return value;
                }
            }

            throw new Ex.InvalidValueException("Invalid value of 'type' in ':parse_data_value'");
        }

        function draw(dc) {
            if (!need_draw()) {
                return;
            }

            try {
                settings = System.getDeviceSettings();

                var primaryColor = position == SE.COMPLICATION_GRAPH_POSITION_BOTTOM ? gbar_color_1 : gbar_color_0;

                //Calculation
                var targetdatatype = get_data_type();
                var HistoryIter = get_data_interator(targetdatatype);

                if (HistoryIter == null) {
                    dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(position_x, position_y, smallDigitalFont, "--", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    return;
                }

                var HistoryMin = HistoryIter.getMin();
                var HistoryMax = HistoryIter.getMax();

                if (HistoryMin == null || HistoryMax == null) {
                    dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(position_x, position_y, smallDigitalFont, "--", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    return;
                }

                var minMaxDiff = (HistoryMax - HistoryMin).toFloat();

                var xStep = graph_width;
                var height = graph_height;
                var HistoryPresent = 0;

                var HistoryNew = 0;
                var lastyStep = 0;
                var step_max = -1;
                var step_min = -1;

                var latest_sample = HistoryIter.next();
                if (latest_sample != null) {
                    HistoryPresent = latest_sample.data;
                    if (HistoryPresent != null) {
                        // draw diagram
                        var historyDifPers = (HistoryPresent - HistoryMin) / minMaxDiff;
                        var yStep = historyDifPers * height;
                        yStep = (yStep > height) ? height : yStep;
                        yStep = (yStep < 0) ? 0 : yStep;
                        lastyStep = yStep;
                    } else {
                        lastyStep = null;
                    }
                }

                dc.setPenWidth(2);
                dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);

                // Build and draw Iteration
                for(var i = 90; i > 0; i--) {
                    var sample = HistoryIter.next();

                    if (sample != null) {
                        HistoryNew = sample.data;
                        if (HistoryNew == HistoryMax) {
                            step_max = xStep;
                        } else if (HistoryNew == HistoryMin) {
                            step_min = xStep;
                        }

                        if (HistoryNew != null) {
                            // draw diagram
                            var historyDifPers = ((HistoryNew - HistoryMin)) / minMaxDiff;
                            var yStep = historyDifPers * height;
                            yStep = (yStep > height) ? height : yStep;
                            yStep = yStep<0?0:yStep;

                            if (lastyStep != null) {
                                // draw diagram
                                dc.drawLine(position_x + (xStep - graph_width / 2),
                                            position_y - (lastyStep-graph_height / 2),
                                            position_x + (xStep - graph_width / 2),
                                            position_y - (yStep - graph_height / 2));
                            }
                            lastyStep = yStep;
                        }
                    }
                    xStep--;
                }

                dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);

                if (HistoryPresent == null) {
                    dc.drawText(
                            position_x,
                            position_y + (position == SE.COMPLICATION_GRAPH_POSITION_BOTTOM ? (graph_height / 2 + 10) : (-graph_height / 2 - 16)),
                            smallDigitalFont,
                            "--",
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    return;
                }

                var value_label = parse_data_value(targetdatatype, HistoryPresent);
                var labelll = value_label.format("%d");
                dc.drawText(
                        position_x,
                        position_y + (position == SE.COMPLICATION_GRAPH_POSITION_BOTTOM ? (graph_height / 2 + 10) : (-graph_height / 2 - 16)),
                        smallDigitalFont,
                        labelll,
                        Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

                settings = null;
            } catch(ex) {
                // currently unkown, weird bug
                System.println(ex);
                dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(position_x, position_y, smallDigitalFont, "--", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        private function get_data_type() {
            if (position == SE.COMPLICATION_GRAPH_POSITION_TOP) {
                return Application.getApp().getProperty("compgrapht");
            } else if (position == SE.COMPLICATION_GRAPH_POSITION_BOTTOM) {
                return Application.getApp().getProperty("compgraphb");
            }

            throw new Ex.InvalidValueException("Invalid value of 'position' in ':get_data_type'");
        }

        private function get_data_interator(graphType) {
            switch (graphType) {
                case SE.GRAPH_FIELD_TYPE_HEARTRATE:
                    return Toybox.SensorHistory.getHeartRateHistory({});

                case SE.GRAPH_FIELD_TYPE_ALTITUDE:
                    return Toybox.SensorHistory.getElevationHistory({});

                case SE.GRAPH_FIELD_TYPE_BAROMETER:
                    return Toybox.SensorHistory.getPressureHistory({});

                case SE.GRAPH_FIELD_TYPE_TEMPERATURE:
                    return Toybox.SensorHistory.getTemperatureHistory({});

                case SE.GRAPH_FIELD_TYPE_EMPTY:
                    return null;
            }

            throw new Ex.InvalidValueException("Totally nonsense throw!");
        }
    }

}
