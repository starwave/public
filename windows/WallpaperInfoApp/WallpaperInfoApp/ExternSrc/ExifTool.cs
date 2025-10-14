using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Reflection;
using System.IO;
using System.Diagnostics;
using System.Threading;

public class ExifTool : IDisposable {

	public ExifTool(string path = null) {
		_exe = string.IsNullOrEmpty(path) ? Path.Combine(Path.GetDirectoryName(Assembly.GetEntryAssembly().Location), _exiftoolPath) : path;
		_psi = new ProcessStartInfo {
			FileName = _exe,
			Arguments = _exiftoolArg,
			CreateNoWindow = true,
			UseShellExecute = false,
			RedirectStandardOutput = true,
			RedirectStandardError = true,
			RedirectStandardInput = true
		};
		_status = ExiftoolStatus.Stopped;
	}

	private void OutputDataReceived(object sender, DataReceivedEventArgs e) {
		if (string.IsNullOrEmpty(e.Data))
			return;
		if (_status == ExiftoolStatus.Starting) {
			_exiftoolVersion = e.Data;
			_waitHandle.Set();
		} else {
			if (e.Data.ToLower() == string.Format("{{ready{0}}}", _cmdCnt))
				_waitHandle.Set();
			else
				_output.AppendLine(e.Data);
		}
	}

	public void Start() {
		if (_status != ExiftoolStatus.Stopped)
			throw new InvalidOperationException("Process is not stopped");
		_status = ExiftoolStatus.Starting;
		_proc = new Process { StartInfo = _psi, EnableRaisingEvents = true };
		_proc.OutputDataReceived += OutputDataReceived;
		_proc.Exited += proc_Exited;
		_proc.Start();
		_proc.BeginOutputReadLine();
		_waitHandle.Reset();
		_proc.StandardInput.WriteLine("-ver\n-execute0000");
		_waitHandle.WaitOne();
		_status = ExiftoolStatus.Ready;
	}

	//detect if process is killed
	void proc_Exited(object sender, EventArgs e) {
		if (_proc != null) {
			_proc.Dispose();
			_proc = null;
		}
		_status = ExiftoolStatus.Stopped;
		_waitHandle.Set();
	}

	public void Stop() {
		if (_status != ExiftoolStatus.Ready)
			throw new InvalidOperationException("Process must be ready");
		_status = ExiftoolStatus.Stopping;
		_waitHandle.Reset();
		_proc.StandardInput.WriteLine("-stay_open\nFalse\n");
		if (!_waitHandle.WaitOne(5000)) {
			if (_proc != null) {
				//silently swallow an eventual exception
				try {
					_proc.Kill();
					_proc.WaitForExit(2000);
					_proc.Dispose();
				} catch { }
				_proc = null;
			}
			_status = ExiftoolStatus.Stopped;
		}
	}

	public string SendCommand(string cmd) {
		if (_status != ExiftoolStatus.Ready)
			throw new InvalidOperationException("Process must be ready");
		_waitHandle.Reset();
		_proc.StandardInput.WriteLine("{0}\n-execute{1}", cmd, _cmdCnt);
		_waitHandle.WaitOne();
		_cmdCnt++;
		string r = _output.ToString();
		_output.Clear();
		return r;
	}

	public Dictionary<string, string> FetchExifFrom(string path) {
		Dictionary<string, string> res = new Dictionary<string, string>();
		string sRes = SendCommand(path);
		foreach (string s in sRes.Split(new[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries)) {
			string[] kv = s.Split('\t');
			if (kv.Length == 2) {
				res[kv[0]] = kv[1];
			} else {
				res[kv[0]] = "";
			}
		}
		return res;
	}
	#region IDisposable Members

	public void Dispose() {
		Debug.Assert(_status == ExiftoolStatus.Ready || _status == ExiftoolStatus.Stopped, "Invalid state");
		if (_proc != null && _status == ExiftoolStatus.Ready)
			Stop();
		_waitHandle.Dispose();
	}
	#endregion

	public enum ExiftoolStatus { Stopped, Starting, Ready, Stopping };
	public ExiftoolStatus _status { get; private set; }
	public string _exiftoolVersion { get; private set; }
	public static bool _available = File.Exists(_exiftoolPath);

	private readonly string _exe;
	private static string _exiftoolPath = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile) + @"\bin\exiftool.exe";
	//private const string Arguments = "-fast -m -q -stay_open True -@ - -common_args -d \"%Y.%m.%d %H:%M:%S\" -t";   //-g for groups
	private const string _exiftoolArg = "-fast -m -q -stay_open True -@ - -common_args -exiftoolversion -imagedescription -subject -orientation -t";
	private int _cmdCnt = 1;
	private Process _proc = null;
	private readonly StringBuilder _output = new StringBuilder();
	private readonly ProcessStartInfo _psi;
	private readonly ManualResetEvent _waitHandle = new ManualResetEvent(true);
}

/* Example to Use
	ExifToolWrapper extw = new ExifToolWrapper();
	extw.Start();
	Dictionary<string, string> d = extw.FetchExifFrom(@"c:\Users\starwave\Downloads\Work\DSC09172.JPG");
	Console.WriteLine(d["Image Description"]);
	Console.WriteLine(d["Orientation"]);
	Console.WriteLine(d["Subject"]);
*/