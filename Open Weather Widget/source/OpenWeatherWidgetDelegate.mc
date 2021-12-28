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
        WatchUi.pushView(new MenuSettingsView(), new MenuSettingsDelegate(mainView), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
