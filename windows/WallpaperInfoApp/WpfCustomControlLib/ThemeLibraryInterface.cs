using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using System.IO;
using System.Reflection;
using System.Runtime;
using System.Runtime.Serialization.Json;
using System.Runtime.Serialization;

namespace WpfCustomControlLib {

	public class ThemeLibraryInterface {

		public bool requestUpdateThemeLibrary(String label, String config, Action<String> completion) {
			lock(this) {
				try {
					// Windows escape l to %3B, so no further escape is needed
					String option = "a=u&l=" + Uri.EscapeDataString(label) + "&c=" + Uri.EscapeDataString(config);
					maramboi(option, response => {
						BPUtil.storeStringToFile(_themeJsonPath, response);
						completion(response);
					});
					return true;
				} catch (Exception e) {
					Console.WriteLine("Error in requestUpdateThemeLibrary: " + e.Message);
				}
			}
			return false;
		}

		public String getThemeLibrary(Action<String> completion) {
			lock(this) {
				String contents = "";
				String option = "a=g";
				maramboi(option, response => {
					BPUtil.storeStringToFile(_themeJsonPath, response);
					completion(response);
				});
				if (!BPUtil.fileExists(_themeJsonPath)) {
					if (copyAssetFile("WpfCustomControlLib.resource.themelib.txt", _themeJsonPath)) {
						contents = BPUtil.getStringFromFile(_themeJsonPath);
						if (contents != "") {
							BPUtil.storeStringToFile(_themeJsonPath, contents);
						}
					} else {
						Console.WriteLine("Error: getThemeLibrary - copying asset themeLib.txt file");
					}
				} else {
					contents = BPUtil.getStringFromFile(_themeJsonPath);
				}
				return contents;
			}
		}

		public String getReservedWords(Action<String> completion) {
			lock(this) {
				String contents = "";
				String option = "a=r";
				maramboi(option, response => {
					BPUtil.storeStringToFile(_reservedJsonPath, response);
					completion(response);
				});
				if (!BPUtil.fileExists(_reservedJsonPath)) {
					if (copyAssetFile("WpfCustomControlLib.resource.reservedword.txt", _reservedJsonPath)) {
						contents = BPUtil.getStringFromFile(_reservedJsonPath);
						if (contents != "") {
							BPUtil.storeStringToFile(_reservedJsonPath, contents);
						}
					} else {
						Console.WriteLine("Error: getReservedWords - copying asset reservedword.txt file");
					}
				} else {
					contents = BPUtil.getStringFromFile(_reservedJsonPath);
				}
				return contents;
			}
		}

		public void updateThemeLibLocalFileFromList(List<ThemeLib> parsedThemeLibs) {
			lock(this) {
				try {
					String contents = JsonSerializer<List<ThemeLib>>.Serialize(parsedThemeLibs);
					BPUtil.storeStringToFile(_themeJsonPath, contents);
				} catch (Exception e) {
					Console.WriteLine("Error in updateThemeLibLocalFileFromList : " + e.Message);
				}
			}
		}

		private bool copyAssetFile(String assetName, String fileName) {
			lock(this) {
				try {
					var assembly = Assembly.GetExecutingAssembly();
					using (Stream stream = assembly.GetManifestResourceStream(assetName))
					using (StreamReader reader = new StreamReader(stream)) {
						string contents = reader.ReadToEnd();
						BPUtil.storeStringToFile(fileName, contents);
					}
					return true;
				} catch (Exception e ){
					Console.WriteLine("Error in copying asset " + assetName + " file : " + e.Message);
				}
			}
			return false;
		}

		public List<ThemeLib> parseThemeLib(String themeLibString) {
			try {
				return JsonSerializer<List<ThemeLib>>.DeSerialize(themeLibString);
			} catch (Exception e) {
				Console.WriteLine("Error in parsing json from themelib.txt file. : " + e.Message);
			}
			return new List<ThemeLib>();
		}

		public List<ReservedWord> parseReservedWord(String reservedWordString) {
			try {
				return JsonSerializer<List<ReservedWord>>.DeSerialize(reservedWordString);
			} catch (Exception e) {
				 Console.WriteLine("Error in parsing json from reservedword.txt file. : " + e.Message);
			}
			return new List<ReservedWord>();
		}

		private void maramboi(String option, Action<String> completion) {
			lock(this) {
				try {
					string url = "http://" + _host + ":8080/maramboi?" + option;
					HttpWebRequest httpWebRequest = (HttpWebRequest)WebRequest.Create(url);
					httpWebRequest.Method = "GET";

					using (WebResponse response = httpWebRequest.GetResponse()) {
						HttpWebResponse httpResponse = response as HttpWebResponse;
						using (StreamReader reader = new StreamReader(httpResponse.GetResponseStream())) {
							var json = reader.ReadToEnd();
							completion(json);
						}
					}
				} catch(Exception e) {
					 Console.WriteLine("maramboi error: " + e.Message);
				}
			}
		}

		public static String _themeJsonPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), ".themelib.txt");
		public static String _reservedJsonPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), ".reservedword.txt");
		public static String _host = "192.168.1.111";
	}

	public class JsonSerializer<TType> where TType : class {
		public static string Serialize(TType instance) {
			var serializer = new DataContractJsonSerializer(typeof(TType));
			var stream = new MemoryStream();
			// following Writer makes it more human readable json file.
			using (var writer = JsonReaderWriterFactory.CreateJsonWriter(stream, Encoding.UTF8, true, true, "  ")) {
				serializer.WriteObject(writer, instance);
			}
			return Encoding.UTF8.GetString(stream.ToArray());
		}

		public static TType DeSerialize(string json) {
			using (var stream = new MemoryStream(Encoding.UTF8.GetBytes(json))) {
				var serializer = new DataContractJsonSerializer(typeof(TType));
				return serializer.ReadObject(stream) as TType;
			}
		}
	}

	[DataContract]
	public class ThemeLib {
		[DataMember]
		public String Label { get; set; }
		[DataMember]
		public String Config { get; set; }

		public ThemeLib(String label, String config) {
			Label = label;
			Config = config;
		}
	};

	[DataContract]
	public class ReservedWord {
		[DataMember]
		public String Word;
		[DataMember]
		public String WordPath;

		ReservedWord(String word, String wordPath) {
			Word = word;
			WordPath = wordPath;
		}
	};
}

