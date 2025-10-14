using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace WallpaperInfoApp {

	class PlatformHotKey {

		public PlatformHotKey(Form form) {
			_formForMessageLoop = form;
			_hwnd = form.Handle;
			_instance = this;
		}

		~PlatformHotKey() {
			foreach (var hotKeyId in _hotKeyIds) {
				UnregisterHotKey(_hwnd, hotKeyId);
			}
		}

		public int RegisterHotKey(Keys key, KeyModifiers modifiers) {
			int hotKeyId = System.Threading.Interlocked.Increment(ref _id);
			_hotKeyIds.Add(hotKeyId);
			RegisterHotKeyInternal(_hwnd, hotKeyId, (uint)modifiers, (uint)key);
			return hotKeyId;
		}

		private void RegisterHotKeyInternal(IntPtr hwnd, int id, uint modifiers, uint key) {      
			RegisterHotKey(hwnd, id, modifiers, key);      
		}

		private void OnHotKeyPressed(HotKeyEventArgs e) {
			if (HotKeyPressed != null) {
				HotKeyPressed(null, e);
			}
		}

		public static bool HookWndProc(Message m) {
			if (_instance == null) {
				return false;
			}
			if (m.Msg == WM_HOTKEY) {
				HotKeyEventArgs e = new HotKeyEventArgs(m.LParam);
				_instance.OnHotKeyPressed(e);
				return true;
			}
			return false;
		}

		public event EventHandler<HotKeyEventArgs> HotKeyPressed;

		public const uint WM_HOTKEY = 0x312;
		private Form _formForMessageLoop;
		private IntPtr _hwnd;
		private int _id = 0;
		private List<int> _hotKeyIds = new List<int>();
		private static PlatformHotKey _instance = null;

		[DllImport("user32", SetLastError=true)]
		private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

		[DllImport("user32", SetLastError = true)]
		private static extern bool UnregisterHotKey(IntPtr hWnd, int id);
	}

	public class HotKeyEventArgs : EventArgs {
		public readonly Keys Key;
		public readonly KeyModifiers Modifiers;

		public HotKeyEventArgs(Keys key, KeyModifiers modifiers) {
			this.Key = key;
			this.Modifiers = modifiers;
		}

		public HotKeyEventArgs(IntPtr hotKeyParam) {
			uint param = (uint)hotKeyParam.ToInt64();
			Key = (Keys)((param & 0xffff0000) >> 16);
			Modifiers = (KeyModifiers)(param & 0x0000ffff);
		}
	}

	[Flags]
	public enum KeyModifiers {
		None = 0,
		Alt = 1,
		Control = 2,
		Shift = 4,
		Windows = 8
	}
}
