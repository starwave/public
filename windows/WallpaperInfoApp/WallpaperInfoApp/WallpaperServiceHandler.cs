using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WallpaperInfoApp {

	class WallpaperServiceHandler {

		public WallpaperServiceHandler(WallpaperService wallpaperService) {
			_service = wallpaperService;
		}

		public static WallpaperServiceHandler incomingHandler(WallpaperServiceConnection incomingMessenger) {
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
			wpsi.getWallpaperService()._wallpaperServiceHandler._incomingMessenger = incomingMessenger;
			return wpsi.getWallpaperService()._wallpaperServiceHandler;
		}
    
		public static void startService() {
			WallpaperServiceInfo.getInstance().getWallpaperService().startService();
		}
    
		public static void stopService() {
			WallpaperServiceInfo.getInstance().getWallpaperService().stopService();
		}
	
		public void replyToClient(Bitmap thumbnail, WPath currentWPath, bool pause) {
			if (_incomingMessenger != null) {
				_incomingMessenger._wallpaperInfoUI.broadcastReceiver(thumbnail, currentWPath, pause);
			}
		}
    
		public void handleMessage(int command, int intOption, object objectparm = null) {
		
			WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
		
			switch (command) {
			
			case MSG.REQUEST_INFO:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.REQUEST_INFO");
				break;

			case MSG.PAUSE:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.PAUSE");
				wpsi.setPause(intOption == 1);
				_service.pause_resume_service();
				break;

			case MSG.PREVIOUS:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.PREVIOUS");
				_service.restartTimer();
				_service.naviageWallpaper(offset: -1);
				break;

			case MSG.NEXT:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.NEXT");
				_service.restartTimer();
				_service.naviageWallpaper(offset: 1);
				break;

			case MSG.SET_ROOT:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_ROOT");
				String path = (String)objectparm;
				_service.setNewRootPath(newRootPath: path);
				break;

			case MSG.ACTIVITY_REPORT:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.ACTIVITY_REPORT");
				break;

			case MSG.SET_WALLPAPER:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_WALLPAPER");
				break;

			case MSG.SET_INTERVAL:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_INTERVAL");
				if (intOption > 0) {
					wpsi.setInterval(intOption);
					_service.setInterval(interval: intOption);
					_service.restartTimer();
				}
				break;

			case MSG.SERVICE_INFO:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.SERVICE_INFO");
				break;

			case MSG.SET_THEME:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.SET_THEME");
				_service.updateServiceTheme(ThemeMethods.rawValue(intOption));
				_service.restartTimer();
				break;

			case MSG.PREVIOUS_THEME:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.PREVIOUS_THEME");
				_service.updateServiceThemeWithPrevious();
				break;

			case MSG.NEXT_THEME:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.NEXT_THEME");
				_service.updateServiceThemeWithNext();
				break;

			case MSG.CUSTOM_CONFIG:
				BPUtil.BPLog("WallpaperServiceHandler - MSG.CUSTOM_CONFIG");
				String customConfigString = (String)objectparm;
				_service.updateServiceCustomConfig(customConfigString);
				_service.restartTimer();
				break;

			default:
				BPUtil.BPLog("WallpaperServiceHandler - Invalid Command Error");
				break;
			}
		}
	
		public void unbind() {
			_incomingMessenger = null;
		}

		private WallpaperServiceConnection _incomingMessenger = null;
		private WallpaperService _service = null;
	}
}
