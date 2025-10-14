using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

	class PlatformTimer {

		public PlatformTimer(WallpaperService wallpaperService) {
			_wallpaperService = wallpaperService;
		}

		private void scheduleSwitchWallpaper(int seconds) {
			if (_switchHandler != null) {
				cancelSwitchWallpaper();
			}
			_switchHandler = new System.Timers.Timer(seconds*1000);
			_switchHandler.Elapsed += (sender, args) => {
				// Console.WriteLine("PlatformTimer.eventHandler{}");
				if (!_pause) {
					_wallpaperService.wallpaperSwitchCallback();
				}
			};
			_pause = false;
			_switchHandler.Start();
		}
    
		void cancelSwitchWallpaper() {
			if (_switchHandler != null) {
				_switchHandler.Stop();
				_switchHandler = null;
			}
			_pause = true;
		}
    
		public void resetTimer() {
			if (!_pause) {
				resume();
			}
		}
    
		public void pause() {
			// print("PlatformTimer.pause()")
			cancelSwitchWallpaper();
		}
    
		public void resume() {
			// print("PlatformTimer.resume()")
			scheduleSwitchWallpaper(seconds: _interval);
		}
    
		public void setInterval(int interval) {
			_interval = interval;
			if (!_pause) {
				resume();
			}
		}

		private WallpaperService _wallpaperService;
		private System.Timers.Timer _switchHandler = null;
		private int _interval = 15;
		private bool _pause = false;
	}
}
