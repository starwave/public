using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.IO;
using ExifLib;

class ExifInterface {

	public ExifInterface(String path) {

		#pragma warning disable 0162
		switch (_exifMethod) {
			case ExifMethods.ExifLib:
				_exifReader = new ExifReader(path);
				break;
			case ExifMethods.ExifTool:
				if (ExifTool._available) {
					if (_exiftool == null) {
						_exiftool = new ExifTool();
						_exiftool.Start();
					}
					_exifDic = _exiftool.FetchExifFrom(path);
				}
				break;
			case ExifMethods.ImageProperty:
				Image image = new Bitmap(path);
				_propItems = image.PropertyItems;
				image.Dispose();
				// To print out all items for debug
				/*
				foreach (var propItem in _propItems) {
					if (propItem.Type == 2) {
						string utfString = Encoding.UTF8.GetString(propItem.Value, 0, propItem.Value.Length - 1);
						Console.WriteLine(propItem.Id.ToString("x") + ":" + utfString);
					}
				}
				 */
				break;
			default:
				break;
		}
		#pragma warning restore 0162
	}

	public String getAttribute(Attr attribute) {
		#pragma warning disable 0162
		switch (_exifMethod) {
			case ExifMethods.ExifLib:
				object val;
				switch (attribute) {
					case Attr.ImageDescription:
						if (_exifReader.GetTagValue(ExifTags.ImageDescription, out val)) {
							return (String)val;
						}
						break;
					case Attr.Orientation:
						if (_exifReader.GetTagValue(ExifTags.Orientation, out val)) {
							return (String)val;
						}
						break;
					case Attr.Subject:
						if (_exifReader.GetTagValue(ExifTags.XPSubject, out val)) {
							return (String)val;
						}
						break;
					default:
						return "";
				}
				
				break;
			case ExifMethods.ExifTool:
				if (ExifTool._available) {
					String attributeString;
					switch (attribute) {
						case Attr.ImageDescription:
							attributeString = "Image Description";
							break;
						case Attr.Orientation:
							attributeString = "Orientation";
							break;
						case Attr.Subject:
							attributeString = "Subject";
							break;
						default:
							return "";
					}
					string value = _exifDic.TryGetValue(attributeString, out value) ? value : "";
					return value;
				}
				break;
			case ExifMethods.ImageProperty:
				int attributeId;
				switch (attribute) {
					case Attr.ImageDescription:
						attributeId = TAG_IMAGE_DESCRIPTION;
						break;
					case Attr.Orientation:
					case Attr.Subject:
					default:
						return "";
				}
				foreach (var propItem in _propItems) {
					if (propItem.Id == attributeId) {
						// Should use length - 1 since it contains \0 at the end
						string utfString = Encoding.UTF8.GetString(propItem.Value, 0, propItem.Value.Length - 1);
						return utfString;
					}
				}
				return "";
					break;
			default:
				break;
		}
		return "";
		#pragma warning restore 0162
	}

	public enum ExifMethods { ExifLib, ExifTool, ImageProperty };
	private const ExifMethods _exifMethod = ExifMethods.ExifLib;
	public enum Attr { ImageDescription, Orientation, Subject };

	// ExifMethods.ExifLib
	private ExifReader _exifReader;

	// ExifMethods.Exiftool
	private ExifTool _exiftool = null;
	private Dictionary<string, string> _exifDic;

	// ExifMethods.ImageProperty
	private System.Drawing.Imaging.PropertyItem[] _propItems;
	private const int TAG_IMAGE_DESCRIPTION = 0x10e;	// "ImageDescription"
	private const int TAG_IMAGE_TITLE = 0x0320;			// "Image title"
	private const int TAG_MANUFACTURER = 0x010F;		// "Equipment manufacturer"
	private const int TAG_MODEL = 0x0110;				// "Equipment model"
	private const int TAG_DT_ORIGINAL = 0x9003;			// "ExifDTOriginal"
	private const int TAG_EXPOSURE_TIME = 0x829A;		// "Exif exposure time"
	private const int TAG_LUMINANCE_TABLE = 0x5090;		// "Luminance table"
	private const int TAG_CHROMINANCE_TABLE = 0x5091;	// "Chrominance table"
}

