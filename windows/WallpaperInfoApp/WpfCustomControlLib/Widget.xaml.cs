using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace WpfCustomControlLib {
	/// <summary>
	/// Interaction logic for Widget.xaml
	/// </summary>
	public partial class Widget : Window {
		public Widget() {
			InitializeComponent();
		}

		public void setWidgetText(String text) {
			if (text == null) {
				text = "";
			}
			_widgetLabel.Dispatcher.Invoke(new Action(() => {
				_widgetLabel.Text = text;
				_widgetLabelShadow.Text = text;
			}));
		}

		public String getWidgetText() {
			return _widgetLabel.Dispatcher.Invoke(() => {
				return _widgetLabel.Text;
			});
		}

		public bool getVisible() {
			return _widgetLabel.Dispatcher.Invoke(() => {
				return (_widgetLabel.Visibility == Visibility.Visible);
			});
		}

		public void setVisible(bool visible) {
			_widgetLabel.Dispatcher.Invoke(new Action(() => {
				_widgetLabel.Visibility = (visible) ? Visibility.Visible : Visibility.Hidden;
				_widgetLabelShadow.Visibility = (visible) ? Visibility.Visible : Visibility.Hidden;
			}));
		}

		public void closeWidget() {
			_widgetLabel.Dispatcher.Invoke(new Action(() => {
				this.Close();
			}));
		}

	}
}
