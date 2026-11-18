package;

/**
 * Élő újratöltés fejlesztés közben: a böngészőben futó DEV játék (cheat-build, nem teszt) feliratkozik a fejlesztői szerver
 * `/__reload?kind=dev` eseményfolyamára, és újratölt, ha új DEV build készül (scripts/build.ps1 -> scripts/reload.ps1 -> /__built?kind=dev).
 * Release-ben és teszt-buildben nem fordul ki / nem csatlakozik, így a fajták nem keverednek (lásd scripts/devserver.js).
 */
class DevReload
{
	public static function init():Void
	{
		#if (cheats && js && !test)
		js.Syntax.code("
			(function () {
				try {
					if (!window.EventSource || window.__devReload) return;
					var es = new EventSource('/__reload?kind=dev');
					window.__devReload = es;
					es.addEventListener('reload', function () { location.reload(); });
				} catch (e) {}
			})();
		");
		#end
	}
}
