using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace WallpaperInfoApp
{
    static class WallpaperInfoApp {
		// To Ensure single instance of application
		static Mutex mutex = new Mutex(true, "{8F6F0AC4-B9A1-45fd-A8CF-72F04E6BDE8F}");
        [STAThread]
        static void Main() {
            string[] args = Environment.GetCommandLineArgs();
            if (args.Count() > 1 && args[1] == "quit") {
                NativeMethods.SendNotifyMessage(
                    (IntPtr)NativeMethods.HWND_BROADCAST,
                    NativeMethods.WM_QUIT_REQUEST,
                    0,
                    0);
                Application.Exit();
                return;
            }
			if (mutex.WaitOne(TimeSpan.Zero, true)) {
                //if (Environment.OSVersion.Version.Major >= 6)
                //    NativeMethods.SetProcessDPIAware();
				Application.EnableVisualStyles();
				Application.SetCompatibleTextRenderingDefault(false);
				WallpaperServiceInfo wpsi = WallpaperServiceInfo.getInstance();
				wpsi.getWallpaperService().startService();
				Application.Run(wpsi.getWallpaperService()._wallpaperNotification);
				mutex.ReleaseMutex(); 
			} else {
                NativeMethods.SendNotifyMessage(
                    (IntPtr)NativeMethods.HWND_BROADCAST,
                    NativeMethods.WM_EXTRA_EXECUTED,
                    0,
                    0);
			}
		}
    }
}

internal class NativeMethods {
    public static IntPtr HWND_BROADCAST = (IntPtr)0xffff;
    public static uint WM_EXTRA_EXECUTED = RegisterWindowMessage("WM_EXTRA_EXECUTED");
    public static uint WM_QUIT_REQUEST = RegisterWindowMessage("WM_QUIT_REQUEST");
    public static uint WM_WININICHANGE = 0x001A;
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool SendNotifyMessage(IntPtr hWnd, uint msg, int wParam, int lParam);
	[DllImport("user32.dll")]
    public static extern uint RegisterWindowMessage(string message);
    //[DllImport("user32.dll")]
    //public static extern bool SetProcessDPIAware();
}
