using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

	class WallpaperServiceConnection {

		WallpaperServiceConnection(WallpaperInfoUI wallpaperInfoUI ) {
			_wallpaperInfoUI = wallpaperInfoUI;
		}
	
		public static void startService() {
			WallpaperServiceHandler.startService();
		}
    
		public static void stopService() {
			WallpaperServiceHandler.stopService();
		}

		public static void broadcastToService(int action, int extra = 0) {
			WallpaperServiceInfo.getInstance().getWallpaperService().broadcastReceiver(action, extra);
		}
	
		public void sendMessageToService(int command, int intOption = 0, object objectOption = null) {
			if (_wallpaperServiceHandler != null) {
				_wallpaperServiceHandler.handleMessage(command, intOption, objectOption);
			}
		}
	
		public static WallpaperServiceConnection bindService(WallpaperInfoUI wallpaperInfoUI) {
			WallpaperServiceConnection wallpaperServiceConnection = new WallpaperServiceConnection(wallpaperInfoUI);
			wallpaperServiceConnection._wallpaperServiceHandler = WallpaperServiceHandler.incomingHandler(incomingMessenger: wallpaperServiceConnection);
			return wallpaperServiceConnection;
		}
	
		public void unbindService() {
			_wallpaperServiceHandler.unbind();
			_wallpaperServiceHandler = null;
		}

		public WallpaperInfoUI _wallpaperInfoUI;
		private WallpaperServiceHandler _wallpaperServiceHandler = null;
	}
}
