using Toybox.Math;
using RuntimeData as RD;

module ConversionUtils {

    function degreesToRadians(degrees) {
        return degrees * Math.PI / 180;
    }

    function radiansToDegrees(radians) {
        return radians * 180 / Math.PI;
    }

    function convertCoorX(radians, radius) {
        return RD.centerX + radius * Math.cos(radians);
    }

    function convertCoorY(radians, radius) {
        return RD.centerY + radius * Math.sin(radians);
    }

    function toKValue(value) {
        var valK = value / 1000.0;
        return valK.format("%0.1f");
    }

    function toFahrenheit(celsius) {
        return (celsius * (9.0 / 5)) + 32;
    }

}
