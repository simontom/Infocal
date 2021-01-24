module RuntimeData {

    // In-memory current location.
    // Previously persisted in App.Storage, but now persisted in Object Store due to #86 workaround for App.Storage firmware bug.
    // Current location retrieved/saved in requestWeatherUpdate().
    // Persistence allows weather and sunrise/sunset features to be used after watch face restart, even if watch no longer has current
    // location available.
    var gLocationLat = null;
    var gLocationLng = null;

    var centerX;
    var centerY;

    var forceRenderComponent = false;

    var formattedDateDataProvider = null;
    var batteryDataProvider = null;
    var themeDataProvider = null;
}
