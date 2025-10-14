namespace WallpaperInfoApp {
	partial class WallpaperNotification {
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
		protected override void Dispose(bool disposing) {
			if (disposing && (components != null)) {
				components.Dispose();
			}
			base.Dispose(disposing);
		}

		#region Windows Form Designer generated code

		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent() {
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(WallpaperNotification));
            this._notifyIcon = new System.Windows.Forms.NotifyIcon(this.components);
            this._trayMenuStrip = new System.Windows.Forms.ContextMenuStrip(this.components);
            this._thumbnailMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.separatorMenuItem1 = new System.Windows.Forms.ToolStripSeparator();
            this._wallpaperMenu = new System.Windows.Forms.ToolStripMenuItem();
            this._themeMenu = new System.Windows.Forms.ToolStripMenuItem();
            this.separatorMenuItem2 = new System.Windows.Forms.ToolStripSeparator();
            this._previousMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this._pauseMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this._nextMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.separatorMenuItem3 = new System.Windows.Forms.ToolStripSeparator();
            this._optionsMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this._aBoutMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.separatorMenuItem4 = new System.Windows.Forms.ToolStripSeparator();
            this._quitWallpaperInfoAppMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this._trayMenuStrip.SuspendLayout();
            this.SuspendLayout();
            // 
            // _notifyIcon
            // 
            this._notifyIcon.BalloonTipIcon = System.Windows.Forms.ToolTipIcon.Info;
            this._notifyIcon.ContextMenuStrip = this._trayMenuStrip;
            this._notifyIcon.Icon = ((System.Drawing.Icon)(resources.GetObject("_notifyIcon.Icon")));
            this._notifyIcon.Text = "Wallpaper Info App";
            this._notifyIcon.Visible = true;
            this._notifyIcon.MouseClick += new System.Windows.Forms.MouseEventHandler(this.notifyIconClicked);
            this._notifyIcon.MouseDoubleClick += new System.Windows.Forms.MouseEventHandler(this.notifyIconDoubleClicked);
            // 
            // _trayMenuStrip
            // 
            this._trayMenuStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this._thumbnailMenuItem,
            this.separatorMenuItem1,
            this._wallpaperMenu,
            this._themeMenu,
            this.separatorMenuItem2,
            this._previousMenuItem,
            this._pauseMenuItem,
            this._nextMenuItem,
            this.separatorMenuItem3,
            this._optionsMenuItem,
            this._aBoutMenuItem,
            this.separatorMenuItem4,
            this._quitWallpaperInfoAppMenuItem});
            this._trayMenuStrip.Name = "trayMenuStrip";
            this._trayMenuStrip.Size = new System.Drawing.Size(210, 376);
            // 
            // _thumbnailMenuItem
            // 
            this._thumbnailMenuItem.AutoSize = false;
            this._thumbnailMenuItem.BackColor = System.Drawing.Color.Transparent;
            this._thumbnailMenuItem.BackgroundImage = global::WallpaperInfoApp.Properties.Resources.thirdwave;
            this._thumbnailMenuItem.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this._thumbnailMenuItem.Name = "_thumbnailMenuItem";
            this._thumbnailMenuItem.Size = new System.Drawing.Size(200, 150);
            this._thumbnailMenuItem.TextImageRelation = System.Windows.Forms.TextImageRelation.TextAboveImage;
            this._thumbnailMenuItem.Click += new System.EventHandler(this.imageMenuItemClicked);
            // 
            // separatorMenuItem1
            // 
            this.separatorMenuItem1.Name = "separatorMenuItem1";
            this.separatorMenuItem1.Size = new System.Drawing.Size(206, 6);
            // 
            // _wallpaperMenu
            // 
            this._wallpaperMenu.Name = "_wallpaperMenu";
            this._wallpaperMenu.Size = new System.Drawing.Size(209, 22);
            this._wallpaperMenu.Text = "Wallpapers";
            // 
            // _themeMenu
            // 
            this._themeMenu.Name = "_themeMenu";
            this._themeMenu.Size = new System.Drawing.Size(209, 22);
            this._themeMenu.Text = "Themes";
            // 
            // separatorMenuItem2
            // 
            this.separatorMenuItem2.Name = "separatorMenuItem2";
            this.separatorMenuItem2.Size = new System.Drawing.Size(206, 6);
            // 
            // _previousMenuItem
            // 
            this._previousMenuItem.Name = "_previousMenuItem";
            this._previousMenuItem.Size = new System.Drawing.Size(209, 22);
            this._previousMenuItem.Text = "Previous";
            this._previousMenuItem.Click += new System.EventHandler(this.actionPreviousImage);
            // 
            // _pauseMenuItem
            // 
            this._pauseMenuItem.Name = "_pauseMenuItem";
            this._pauseMenuItem.Size = new System.Drawing.Size(209, 22);
            this._pauseMenuItem.Text = "Pause";
            this._pauseMenuItem.Click += new System.EventHandler(this.actionPauseResume);
            // 
            // _nextMenuItem
            // 
            this._nextMenuItem.Name = "_nextMenuItem";
            this._nextMenuItem.Size = new System.Drawing.Size(209, 22);
            this._nextMenuItem.Text = "Next";
            this._nextMenuItem.Click += new System.EventHandler(this.actionNextImage);
            // 
            // separatorMenuItem3
            // 
            this.separatorMenuItem3.Name = "separatorMenuItem3";
            this.separatorMenuItem3.Size = new System.Drawing.Size(206, 6);
            // 
            // _optionsMenuItem
            // 
            this._optionsMenuItem.Name = "_optionsMenuItem";
            this._optionsMenuItem.Size = new System.Drawing.Size(209, 22);
            this._optionsMenuItem.Text = "Options";
            this._optionsMenuItem.Click += new System.EventHandler(this.showWallpaperInfoOptionWindow);
            // 
            // _aBoutMenuItem
            // 
            this._aBoutMenuItem.Enabled = false;
            this._aBoutMenuItem.Name = "_aBoutMenuItem";
            this._aBoutMenuItem.Size = new System.Drawing.Size(209, 22);
            this._aBoutMenuItem.Text = "About WallpaperInfo App";
            // 
            // separatorMenuItem4
            // 
            this.separatorMenuItem4.Name = "separatorMenuItem4";
            this.separatorMenuItem4.Size = new System.Drawing.Size(206, 6);
            // 
            // _quitWallpaperInfoAppMenuItem
            // 
            this._quitWallpaperInfoAppMenuItem.Name = "_quitWallpaperInfoAppMenuItem";
            this._quitWallpaperInfoAppMenuItem.Size = new System.Drawing.Size(209, 22);
            this._quitWallpaperInfoAppMenuItem.Text = "Quit WallpaperInfoApp";
            this._quitWallpaperInfoAppMenuItem.Click += new System.EventHandler(this.trayMenu_Quit);
            // 
            // WallpaperNotification
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.ClientSize = new System.Drawing.Size(298, 157);
            this.Name = "WallpaperNotification";
            this.ShowIcon = false;
            this.ShowInTaskbar = false;
            this.Text = "WallpaperNotification";
            this.WindowState = System.Windows.Forms.FormWindowState.Minimized;
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.WallpaperNotificationClosed);
            this._trayMenuStrip.ResumeLayout(false);
            this.ResumeLayout(false);

		}

		#endregion

		private System.Windows.Forms.NotifyIcon _notifyIcon;
		private System.Windows.Forms.ContextMenuStrip _trayMenuStrip;
		private System.Windows.Forms.ToolStripMenuItem _quitWallpaperInfoAppMenuItem;
		private System.Windows.Forms.ToolStripMenuItem _wallpaperMenu;
		private System.Windows.Forms.ToolStripSeparator separatorMenuItem2;
		private System.Windows.Forms.ToolStripMenuItem _previousMenuItem;
		private System.Windows.Forms.ToolStripMenuItem _pauseMenuItem;
		private System.Windows.Forms.ToolStripMenuItem _nextMenuItem;
		private System.Windows.Forms.ToolStripSeparator separatorMenuItem3;
		private System.Windows.Forms.ToolStripMenuItem _optionsMenuItem;
		private System.Windows.Forms.ToolStripMenuItem _aBoutMenuItem;
		private System.Windows.Forms.ToolStripSeparator separatorMenuItem4;
		private System.Windows.Forms.ToolStripMenuItem _thumbnailMenuItem;
		private System.Windows.Forms.ToolStripSeparator separatorMenuItem1;
		private System.Windows.Forms.ToolStripMenuItem _themeMenu;
	}
}