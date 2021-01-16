using Toybox.Weather as W;
using Toybox.Activity as A;
using Toybox.System as Sys;

module DataProvider {

    function xxx() {

        // Porovnat GarminWeather observation time vs last activity time

        var activityLocation = A.getActivityInfo().currentLocation;
        var activityLocationDegrees = null;

        var currentConditionsLocation = W.getCurrentConditions();
        if (currentConditionsLocation != null) {
            currentConditionsLocation = currentConditionsLocation.observationLocationPosition;
        }
        var currentConditionsLocationDegrees = null;

        if (activityLocation != null) {
            activityLocationDegrees = activityLocation.toDegrees();
            Sys.println("activityLocationDegrees-lat-" + activityLocationDegrees[0]);
            Sys.println("activityLocationDegrees-lng-" + activityLocationDegrees[1]);
        }

        if (currentConditionsLocation != null) {
            currentConditionsLocationDegrees = currentConditionsLocation.toDegrees();
            Sys.println("currentConditionsLocationDegrees-lat-" + currentConditionsLocationDegrees[0]);
            Sys.println("currentConditionsLocationDegrees-lng-" + currentConditionsLocationDegrees[1]);
        }

        Sys.println("activityLocation-" + activityLocation);
        Sys.println("currentConditionsLocation-" + currentConditionsLocation);
    }

    class LocationProvider {
    }

}
