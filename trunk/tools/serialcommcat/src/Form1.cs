using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Globalization;


namespace SerialCommChat
{
    public partial class Form1 : Form
    {
        private System.IO.Ports.SerialPort serialPort = new System.IO.Ports.SerialPort();
        //---Delegate and subroutine to update the TextBox control---
        public delegate void myDelegate();
        public void updateTextBox()
        {
            if (checkHexDisplay.Checked)    //---以16进制显示---
            {
                int bytes = serialPort.BytesToRead;
                byte[] bBuffer = new byte[bytes];
                //从串口读数据存放到bBuffer缓冲区
                serialPort.Read(bBuffer, 0, bytes);
                txtDataReceived.AppendText(BytesToHexString(bBuffer) + " ");
 
            }
            else  //---以ASCII字符串显示
            {
                //---append the received data into the TextBox control---
                txtDataReceived.AppendText(serialPort.ReadExisting());
            }
                txtDataReceived.ScrollToCaret();

        }

        //---event handler for the DataReceived event---
        private void DataReceived(object sender, System.IO.Ports.SerialDataReceivedEventArgs e)
        {
            //---invoke the delegate to retrieve the received data---
            txtDataReceived.BeginInvoke(new myDelegate(updateTextBox));
        }

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            //---set the event handler for the DataReceived event---
            serialPort.DataReceived += new System.IO.Ports.SerialDataReceivedEventHandler(DataReceived);

            //---display all the serial port names on the local computer---
            string[] portNames = System.IO.Ports.SerialPort.GetPortNames();
            for (int i = 0; i <= portNames.Length - 1; i++)
            {
                cbbCOMPorts.Items.Add(portNames[i]);
            }
            cbbCOMPorts.Text = portNames[0];

            //---display all baud rate on serial port.---
            int[] baudRate = { 110, 300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600 };
            foreach(int _baudRate in baudRate)
            {
                cbbBaudrate.Items.Add(_baudRate.ToString());
            }
            cbbBaudrate.Text = baudRate[5].ToString();

            btnDisconnect.Enabled = false;
        }

        private void btnConnect_Click(object sender, EventArgs e)
        {
            //---close the serial port if it is open---
            if (serialPort.IsOpen)
            {
                serialPort.Close();
            }
            try
            {
                //---configure the various parameters of the serial port---
                serialPort.PortName = cbbCOMPorts.Text;
                serialPort.BaudRate = int.Parse(cbbBaudrate.Text);
                serialPort.Parity = System.IO.Ports.Parity.None;
                serialPort.DataBits = 8;
                serialPort.StopBits = System.IO.Ports.StopBits.One;

                //---open the serial port---
                serialPort.Open();

                //--updata the status of the serial port and
                // enable/disable the buttons---
                this.Text = "Serial Chat [" + cbbCOMPorts.Text + " connected. Parity.None, 8, StopBits.One]";
                btnConnect.Enabled = false;
                btnDisconnect.Enabled = true;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }

        private void btnDisconnect_Click(object sender, EventArgs e)
        {
            try
            {
                //---close the serial port---
                serialPort.Close();

                //---update the status of the serial port and 
                //enable/disable the button---
                this.Text = "Serial Chat";
                btnConnect.Enabled = true;
                btnDisconnect.Enabled = false;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }
        //---将Hex字符串转化为字节数组---
        private byte[] HexStringToBytes(string hexString)
        {
            if (hexString == null)
            {
                throw new ArgumentNullException("hexString");
            }

            if ((hexString.Length & 1) != 0)
            {
                throw new ArgumentOutOfRangeException("hexString", hexString, "hexString must contain an even number of characters.");
            }

            byte[] result = new byte[hexString.Length / 2];

            for (int i = 0; i < hexString.Length; i += 2)
            {
                result[i / 2] = byte.Parse(hexString.Substring(i, 2), NumberStyles.HexNumber);
            }

            return result;
        }
        //---将字节数组转化为Hex字符串
        private string BytesToHexString(byte[] byteArray)
        {
            string hexString = BitConverter.ToString(byteArray).Replace("-", " ");

            return hexString;
        }

        //---每隔spacingIndex加1空格---
        private string AddSpace(string text, int spacingIndex)
        {
            StringBuilder sb = new StringBuilder(text);
            for (int i = spacingIndex; i <= sb.Length; i += spacingIndex + 1)
            {
                sb.Insert(i, " ");
            }
            return sb.ToString();
        } 


        private void btnSend_Click(object sender, EventArgs e)
        {
            try
            {
                if (checkHexSend.Checked == false)  
                {
                    //---发送ASCII文本---
                    //---write the string to the serial port---
                    serialPort.Write(txtDataToSend.Text);
                    //---echo send text
                    if (checkTextEcho.Checked)
                    {
                        //---append the sent string to the Textbox control---
                        txtDataReceived.AppendText(Environment.NewLine + ">" + txtDataToSend.Text + Environment.NewLine);
                        txtDataReceived.ScrollToCaret();
                    }
                }
                else
                {
                    //---发送二进制数据---
    //                byte[] buffer = hexToBin(txtDataToSend.Text);
                    string hexValues = txtDataToSend.Text;
                    hexValues = hexValues.Replace(" ","").Replace("\r\n","");
                    byte[] buffer = HexStringToBytes(hexValues);
                    //---Convert Hex to Byte
                    serialPort.Write(buffer, 0, buffer.Length);
                    //--echo send hex string
                    if (checkTextEcho.Checked)
                    {
                        //---append the sent string to the Textbox control---
                        //---格式化hex字符串每隔2个字符加1空格---
                        hexValues = AddSpace(hexValues, 2);
                        txtDataReceived.AppendText(Environment.NewLine + ">" + hexValues + Environment.NewLine);
                        txtDataReceived.ScrollToCaret();
                    }
                }
                if(checkClearSend.Checked)
                    //---clear the TextBox control---
                    txtDataToSend.Text = string.Empty;
            }
            catch(Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }

        private void btnClear_Click(object sender, EventArgs e)
        {
            txtDataReceived.Text = string.Empty;
        }
    }
}
