using Toybox.Application as App;
using Toybox.Activity;
using Toybox.Graphics as G;
using Toybox.WatchUi;

class MenuSettingsView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title=>R(Rez.Strings.AppName)});
		// Show GPS location only if currentLocation is null and Garmin Weather is disabled
		if (App.Storage.getValue("last_location") == null ||
			(Activity.getActivityInfo().currentLocation == null &&
			(!(Toybox has :Weather) || App.Properties.getValue("use_garmin_location") == false))
			) {
			Menu2.addItem(new WatchUi.MenuItem(R(Rez.Strings.GetGPSlocation), null, 2,    null));
		}
		if ($.getLocation() != null) {
			Menu2.addItem(new WatchUi.MenuItem(R(Rez.Strings.RefreshWeather), null, 1, null));
		}
		Menu2.addItem(new WatchUi.MenuItem(R(Rez.Strings.AppVersionTitle), R(Rez.Strings.AppVersion), 3, null));
    }
}

//================================================
class MenuSettingsDelegate extends WatchUi.Menu2InputDelegate {

    var mainView;

    function initialize(view) {
    	mainView = view;
        Menu2InputDelegate.initialize();
    }

  	function onSelect(item) {
  		var id=item.getId();
  		if (id.equals(1)) {
	        // Refresh Data immediatelly on Menu press
	        mainView.owmRequest();
	        vibrate();
	        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		} else if (id.equals(2)) {
			mainView.startGPS();
			vibrate();
  			WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
		} else if (id.equals(3)) {
  			WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
  		}
  	}

	function vibrate() {
        if (Attention has :vibrate) {
		    var vibeData = [ new Attention.VibeProfile(100, 300)]; // 100% for 300 mseconds
		    Attention.vibrate(vibeData);
		}
	}
}
