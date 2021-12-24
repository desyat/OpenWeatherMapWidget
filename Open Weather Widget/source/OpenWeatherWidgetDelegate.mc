using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Attention;

class OpenWeatherWidgetDelegate extends Ui.BehaviorDelegate {

    var mainView;

    function initialize(view) {
        mainView = view;
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        //$.p("onSelect");
        mainView.screenNum = mainView.screenNum == 1 ? 2 : 1;
        Ui.requestUpdate();
    }

    function onMenu() {
        //$.p("onMenu");
        // Refresh Data immediatelly on Menu press
        makeOWMwebRequest(false);
        if (Attention has :vibrate) {
		    var vibeData = [ new Attention.VibeProfile(100, 300)]; // 100% for 300 mseconds
		    Attention.vibrate(vibeData);
		}
        return true;
    }
}
