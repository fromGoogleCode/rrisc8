namespace SerialCommChat
{
    partial class Form1
    {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows 窗体设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent()
        {
            this.label1 = new System.Windows.Forms.Label();
            this.cbbCOMPorts = new System.Windows.Forms.ComboBox();
            this.btnConnect = new System.Windows.Forms.Button();
            this.btnDisconnect = new System.Windows.Forms.Button();
            this.txtDataReceived = new System.Windows.Forms.RichTextBox();
            this.txtDataToSend = new System.Windows.Forms.TextBox();
            this.btnSend = new System.Windows.Forms.Button();
            this.label2 = new System.Windows.Forms.Label();
            this.cbbBaudrate = new System.Windows.Forms.ComboBox();
            this.btnClear = new System.Windows.Forms.Button();
            this.checkHexSend = new System.Windows.Forms.CheckBox();
            this.checkTextEcho = new System.Windows.Forms.CheckBox();
            this.checkClearSend = new System.Windows.Forms.CheckBox();
            this.checkHexDisplay = new System.Windows.Forms.CheckBox();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(13, 13);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(59, 12);
            this.label1.TabIndex = 0;
            this.label1.Text = "COM Ports";
            // 
            // cbbCOMPorts
            // 
            this.cbbCOMPorts.FormattingEnabled = true;
            this.cbbCOMPorts.Location = new System.Drawing.Point(78, 10);
            this.cbbCOMPorts.Name = "cbbCOMPorts";
            this.cbbCOMPorts.Size = new System.Drawing.Size(77, 20);
            this.cbbCOMPorts.TabIndex = 1;
            // 
            // btnConnect
            // 
            this.btnConnect.Location = new System.Drawing.Point(349, 7);
            this.btnConnect.Name = "btnConnect";
            this.btnConnect.Size = new System.Drawing.Size(75, 23);
            this.btnConnect.TabIndex = 2;
            this.btnConnect.Text = "Connect";
            this.btnConnect.UseVisualStyleBackColor = true;
            this.btnConnect.Click += new System.EventHandler(this.btnConnect_Click);
            // 
            // btnDisconnect
            // 
            this.btnDisconnect.Location = new System.Drawing.Point(430, 7);
            this.btnDisconnect.Name = "btnDisconnect";
            this.btnDisconnect.Size = new System.Drawing.Size(75, 23);
            this.btnDisconnect.TabIndex = 3;
            this.btnDisconnect.Text = "Disconnect";
            this.btnDisconnect.UseVisualStyleBackColor = true;
            this.btnDisconnect.Click += new System.EventHandler(this.btnDisconnect_Click);
            // 
            // txtDataReceived
            // 
            this.txtDataReceived.Location = new System.Drawing.Point(12, 61);
            this.txtDataReceived.Name = "txtDataReceived";
            this.txtDataReceived.Size = new System.Drawing.Size(493, 225);
            this.txtDataReceived.TabIndex = 4;
            this.txtDataReceived.Text = "";
            // 
            // txtDataToSend
            // 
            this.txtDataToSend.Location = new System.Drawing.Point(12, 293);
            this.txtDataToSend.Multiline = true;
            this.txtDataToSend.Name = "txtDataToSend";
            this.txtDataToSend.Size = new System.Drawing.Size(493, 57);
            this.txtDataToSend.TabIndex = 5;
            // 
            // btnSend
            // 
            this.btnSend.Location = new System.Drawing.Point(430, 356);
            this.btnSend.Name = "btnSend";
            this.btnSend.Size = new System.Drawing.Size(75, 23);
            this.btnSend.TabIndex = 6;
            this.btnSend.Text = "Send";
            this.btnSend.UseVisualStyleBackColor = true;
            this.btnSend.Click += new System.EventHandler(this.btnSend_Click);
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(162, 13);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(59, 12);
            this.label2.TabIndex = 7;
            this.label2.Text = "Baud Rate";
            // 
            // cbbBaudrate
            // 
            this.cbbBaudrate.FormattingEnabled = true;
            this.cbbBaudrate.Location = new System.Drawing.Point(228, 10);
            this.cbbBaudrate.Name = "cbbBaudrate";
            this.cbbBaudrate.Size = new System.Drawing.Size(81, 20);
            this.cbbBaudrate.TabIndex = 8;
            // 
            // btnClear
            // 
            this.btnClear.Location = new System.Drawing.Point(349, 356);
            this.btnClear.Name = "btnClear";
            this.btnClear.Size = new System.Drawing.Size(75, 23);
            this.btnClear.TabIndex = 9;
            this.btnClear.Text = "Clear";
            this.btnClear.UseVisualStyleBackColor = true;
            this.btnClear.Click += new System.EventHandler(this.btnClear_Click);
            // 
            // checkHexSend
            // 
            this.checkHexSend.AutoSize = true;
            this.checkHexSend.Location = new System.Drawing.Point(254, 360);
            this.checkHexSend.Name = "checkHexSend";
            this.checkHexSend.Size = new System.Drawing.Size(72, 16);
            this.checkHexSend.TabIndex = 10;
            this.checkHexSend.Text = "HEX Send";
            this.checkHexSend.UseVisualStyleBackColor = true;
            // 
            // checkTextEcho
            // 
            this.checkTextEcho.AutoSize = true;
            this.checkTextEcho.Checked = true;
            this.checkTextEcho.CheckState = System.Windows.Forms.CheckState.Checked;
            this.checkTextEcho.Location = new System.Drawing.Point(170, 360);
            this.checkTextEcho.Name = "checkTextEcho";
            this.checkTextEcho.Size = new System.Drawing.Size(78, 16);
            this.checkTextEcho.TabIndex = 11;
            this.checkTextEcho.Text = "Send Echo";
            this.checkTextEcho.UseVisualStyleBackColor = true;
            // 
            // checkClearSend
            // 
            this.checkClearSend.AutoSize = true;
            this.checkClearSend.Checked = true;
            this.checkClearSend.CheckState = System.Windows.Forms.CheckState.Checked;
            this.checkClearSend.Location = new System.Drawing.Point(41, 360);
            this.checkClearSend.Name = "checkClearSend";
            this.checkClearSend.Size = new System.Drawing.Size(114, 16);
            this.checkClearSend.TabIndex = 12;
            this.checkClearSend.Text = "Auto Clear Send";
            this.checkClearSend.UseVisualStyleBackColor = true;
            // 
            // checkHexDisplay
            // 
            this.checkHexDisplay.AutoSize = true;
            this.checkHexDisplay.Location = new System.Drawing.Point(15, 39);
            this.checkHexDisplay.Name = "checkHexDisplay";
            this.checkHexDisplay.Size = new System.Drawing.Size(90, 16);
            this.checkHexDisplay.TabIndex = 13;
            this.checkHexDisplay.Text = "HEX Display";
            this.checkHexDisplay.UseVisualStyleBackColor = true;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(517, 388);
            this.Controls.Add(this.checkHexDisplay);
            this.Controls.Add(this.checkClearSend);
            this.Controls.Add(this.checkTextEcho);
            this.Controls.Add(this.checkHexSend);
            this.Controls.Add(this.btnClear);
            this.Controls.Add(this.cbbBaudrate);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.btnSend);
            this.Controls.Add(this.txtDataToSend);
            this.Controls.Add(this.txtDataReceived);
            this.Controls.Add(this.btnDisconnect);
            this.Controls.Add(this.btnConnect);
            this.Controls.Add(this.cbbCOMPorts);
            this.Controls.Add(this.label1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "Form1";
            this.Text = "Serial Chat";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ComboBox cbbCOMPorts;
        private System.Windows.Forms.Button btnConnect;
        private System.Windows.Forms.Button btnDisconnect;
        private System.Windows.Forms.RichTextBox txtDataReceived;
        private System.Windows.Forms.TextBox txtDataToSend;
        private System.Windows.Forms.Button btnSend;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox cbbBaudrate;
        private System.Windows.Forms.Button btnClear;
        private System.Windows.Forms.CheckBox checkHexSend;
        private System.Windows.Forms.CheckBox checkTextEcho;
        private System.Windows.Forms.CheckBox checkClearSend;
        private System.Windows.Forms.CheckBox checkHexDisplay;
    }
}

