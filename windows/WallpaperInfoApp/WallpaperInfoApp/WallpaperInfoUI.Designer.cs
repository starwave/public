namespace WallpaperInfoApp
{
    partial class WallpaperInfoUI
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>      
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(WallpaperInfoUI));
            this._customConfigStringSetButton = new System.Windows.Forms.Button();
            this._customConfigStringTextBox = new System.Windows.Forms.TextBox();
            this._rootPathTextBox = new System.Windows.Forms.TextBox();
            this._dirButton = new System.Windows.Forms.Button();
            this._intervalTrackBar = new System.Windows.Forms.TrackBar();
            this._thumbnailView = new System.Windows.Forms.PictureBox();
            this._previousButton = new System.Windows.Forms.Button();
            this._pauseButton = new System.Windows.Forms.Button();
            this._nextButton = new System.Windows.Forms.Button();
            this._startStopButton = new System.Windows.Forms.Button();
            this._lastUsedPathsListView = new System.Windows.Forms.ListView();
            this._themeComboBox = new System.Windows.Forms.ComboBox();
            this.textBox1 = new System.Windows.Forms.TextBox();
            this.textBox2 = new System.Windows.Forms.TextBox();
            ((System.ComponentModel.ISupportInitialize)(this._intervalTrackBar)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this._thumbnailView)).BeginInit();
            this.SuspendLayout();
            // 
            // _customConfigStringSetButton
            // 
            this._customConfigStringSetButton.AccessibleName = "";
            this._customConfigStringSetButton.FlatAppearance.BorderSize = 0;
            this._customConfigStringSetButton.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this._customConfigStringSetButton.Image = global::WallpaperInfoApp.Properties.Resources.gear;
            this._customConfigStringSetButton.Location = new System.Drawing.Point(275, 244);
            this._customConfigStringSetButton.Margin = new System.Windows.Forms.Padding(1);
            this._customConfigStringSetButton.Name = "_customConfigStringSetButton";
            this._customConfigStringSetButton.Size = new System.Drawing.Size(75, 30);
            this._customConfigStringSetButton.TabIndex = 0;
            this._customConfigStringSetButton.UseVisualStyleBackColor = true;
            this._customConfigStringSetButton.Click += new System.EventHandler(this.customConfigStringSetButtonClicked);
            // 
            // _customConfigStringTextBox
            // 
            this._customConfigStringTextBox.AccessibleName = "_filterString";
            this._customConfigStringTextBox.Location = new System.Drawing.Point(60, 251);
            this._customConfigStringTextBox.Name = "_customConfigStringTextBox";
            this._customConfigStringTextBox.Size = new System.Drawing.Size(214, 20);
            this._customConfigStringTextBox.TabIndex = 1;
            this._customConfigStringTextBox.Leave += new System.EventHandler(this.customConfigStringChanged);
            // 
            // _rootPathTextBox
            // 
            this._rootPathTextBox.Location = new System.Drawing.Point(12, 12);
            this._rootPathTextBox.Name = "_rootPathTextBox";
            this._rootPathTextBox.ReadOnly = true;
            this._rootPathTextBox.Size = new System.Drawing.Size(246, 20);
            this._rootPathTextBox.TabIndex = 2;
            // 
            // _dirButton
            // 
            this._dirButton.FlatAppearance.BorderSize = 0;
            this._dirButton.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this._dirButton.Image = global::WallpaperInfoApp.Properties.Resources.folder;
            this._dirButton.Location = new System.Drawing.Point(269, 9);
            this._dirButton.Margin = new System.Windows.Forms.Padding(1);
            this._dirButton.Name = "_dirButton";
            this._dirButton.Size = new System.Drawing.Size(75, 30);
            this._dirButton.TabIndex = 3;
            this._dirButton.UseVisualStyleBackColor = true;
            this._dirButton.Click += new System.EventHandler(this.chooseDirButtonClicked);
            // 
            // _intervalTrackBar
            // 
            this._intervalTrackBar.Location = new System.Drawing.Point(5, 69);
            this._intervalTrackBar.Maximum = 30;
            this._intervalTrackBar.Minimum = 5;
            this._intervalTrackBar.Name = "_intervalTrackBar";
            this._intervalTrackBar.Size = new System.Drawing.Size(341, 45);
            this._intervalTrackBar.TabIndex = 4;
            this._intervalTrackBar.Value = 5;
            this._intervalTrackBar.MouseDown += new System.Windows.Forms.MouseEventHandler(this.intervalTrackBar_MouseDown);
            this._intervalTrackBar.MouseMove += new System.Windows.Forms.MouseEventHandler(this.intervalTrackBar_MouseMove);
            this._intervalTrackBar.MouseUp += new System.Windows.Forms.MouseEventHandler(this.intervalTrackBar_MouseUp);
            // 
            // _thumbnailView
            // 
            this._thumbnailView.BackColor = System.Drawing.SystemColors.Window;
            this._thumbnailView.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Center;
            this._thumbnailView.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this._thumbnailView.Location = new System.Drawing.Point(12, 100);
            this._thumbnailView.Name = "_thumbnailView";
            this._thumbnailView.Size = new System.Drawing.Size(332, 130);
            this._thumbnailView.SizeMode = System.Windows.Forms.PictureBoxSizeMode.CenterImage;
            this._thumbnailView.TabIndex = 5;
            this._thumbnailView.TabStop = false;
            this._thumbnailView.Click += new System.EventHandler(this.thumbnailViewClicked);
            // 
            // _previousButton
            // 
            this._previousButton.Image = global::WallpaperInfoApp.Properties.Resources.media_previous;
            this._previousButton.Location = new System.Drawing.Point(102, 284);
            this._previousButton.Margin = new System.Windows.Forms.Padding(1);
            this._previousButton.Name = "_previousButton";
            this._previousButton.Size = new System.Drawing.Size(75, 30);
            this._previousButton.TabIndex = 7;
            this._previousButton.UseVisualStyleBackColor = true;
            this._previousButton.Click += new System.EventHandler(this.previousButtonClicked);
            // 
            // _pauseButton
            // 
            this._pauseButton.Image = global::WallpaperInfoApp.Properties.Resources.media_play_pause;
            this._pauseButton.Location = new System.Drawing.Point(186, 285);
            this._pauseButton.Margin = new System.Windows.Forms.Padding(1);
            this._pauseButton.Name = "_pauseButton";
            this._pauseButton.Size = new System.Drawing.Size(75, 30);
            this._pauseButton.TabIndex = 8;
            this._pauseButton.UseVisualStyleBackColor = true;
            this._pauseButton.Click += new System.EventHandler(this.pauseButtonClicked);
            // 
            // _nextButton
            // 
            this._nextButton.Image = global::WallpaperInfoApp.Properties.Resources.media_next;
            this._nextButton.Location = new System.Drawing.Point(268, 285);
            this._nextButton.Margin = new System.Windows.Forms.Padding(1);
            this._nextButton.Name = "_nextButton";
            this._nextButton.Size = new System.Drawing.Size(75, 30);
            this._nextButton.TabIndex = 9;
            this._nextButton.UseVisualStyleBackColor = true;
            this._nextButton.Click += new System.EventHandler(this.nextButtonClicked);
            // 
            // _startStopButton
            // 
            this._startStopButton.FlatAppearance.BorderSize = 0;
            this._startStopButton.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this._startStopButton.Image = global::WallpaperInfoApp.Properties.Resources.power_on;
            this._startStopButton.Location = new System.Drawing.Point(15, 284);
            this._startStopButton.Margin = new System.Windows.Forms.Padding(1);
            this._startStopButton.Name = "_startStopButton";
            this._startStopButton.Size = new System.Drawing.Size(75, 30);
            this._startStopButton.TabIndex = 10;
            this._startStopButton.UseVisualStyleBackColor = true;
            this._startStopButton.Click += new System.EventHandler(this.startStopButtonClicked);
            // 
            // _lastUsedPathsListView
            // 
            this._lastUsedPathsListView.BackColor = System.Drawing.SystemColors.Window;
            this._lastUsedPathsListView.Location = new System.Drawing.Point(12, 324);
            this._lastUsedPathsListView.Name = "_lastUsedPathsListView";
            this._lastUsedPathsListView.Size = new System.Drawing.Size(334, 201);
            this._lastUsedPathsListView.TabIndex = 11;
            this._lastUsedPathsListView.UseCompatibleStateImageBehavior = false;
            // 
            // _themeComboBox
            // 
            this._themeComboBox.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this._themeComboBox.FormattingEnabled = true;
            this._themeComboBox.Location = new System.Drawing.Point(60, 43);
            this._themeComboBox.Name = "_themeComboBox";
            this._themeComboBox.Size = new System.Drawing.Size(284, 21);
            this._themeComboBox.TabIndex = 13;
            this._themeComboBox.SelectedValueChanged += new System.EventHandler(this.themeComboBoxChanged);
            // 
            // textBox1
            // 
            this.textBox1.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.textBox1.Location = new System.Drawing.Point(12, 46);
            this.textBox1.Name = "textBox1";
            this.textBox1.ReadOnly = true;
            this.textBox1.Size = new System.Drawing.Size(42, 13);
            this.textBox1.TabIndex = 14;
            this.textBox1.Text = "Theme";
            // 
            // textBox2
            // 
            this.textBox2.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.textBox2.Location = new System.Drawing.Point(15, 254);
            this.textBox2.Name = "textBox2";
            this.textBox2.ReadOnly = true;
            this.textBox2.Size = new System.Drawing.Size(42, 13);
            this.textBox2.TabIndex = 15;
            this.textBox2.Text = "Custom";
            // 
            // WallpaperInfoUI
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.ClientSize = new System.Drawing.Size(358, 543);
            this.Controls.Add(this.textBox2);
            this.Controls.Add(this.textBox1);
            this.Controls.Add(this._themeComboBox);
            this.Controls.Add(this._lastUsedPathsListView);
            this.Controls.Add(this._startStopButton);
            this.Controls.Add(this._nextButton);
            this.Controls.Add(this._pauseButton);
            this.Controls.Add(this._previousButton);
            this.Controls.Add(this._thumbnailView);
            this.Controls.Add(this._intervalTrackBar);
            this.Controls.Add(this._dirButton);
            this.Controls.Add(this._rootPathTextBox);
            this.Controls.Add(this._customConfigStringTextBox);
            this.Controls.Add(this._customConfigStringSetButton);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "WallpaperInfoUI";
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.Manual;
            this.Text = "WallpaperInfo App Option";
            this.TransparencyKey = System.Drawing.Color.Gainsboro;
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.wallpapaerInfoUIClosed);
            this.Load += new System.EventHandler(this.windowLoad);
            ((System.ComponentModel.ISupportInitialize)(this._intervalTrackBar)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this._thumbnailView)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button _customConfigStringSetButton;
        private System.Windows.Forms.TextBox _customConfigStringTextBox;
		private System.Windows.Forms.TextBox _rootPathTextBox;
		private System.Windows.Forms.Button _dirButton;
		private System.Windows.Forms.TrackBar _intervalTrackBar;
		private System.Windows.Forms.PictureBox _thumbnailView;
		private System.Windows.Forms.Button _previousButton;
		private System.Windows.Forms.Button _pauseButton;
		private System.Windows.Forms.Button _nextButton;
		private System.Windows.Forms.Button _startStopButton;
		private System.Windows.Forms.ListView _lastUsedPathsListView;
		private System.Windows.Forms.ComboBox _themeComboBox;
		private System.Windows.Forms.TextBox textBox1;
		private System.Windows.Forms.TextBox textBox2;
    }
}

