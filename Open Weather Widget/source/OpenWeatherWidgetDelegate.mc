using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

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
}
