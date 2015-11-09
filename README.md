# TISnifferPsdFileAnalyzer

I was working with TI CC2540 sniffer in 2012 summer and I wrote my own Matlab code to analyze the BLE packets that are sniffed. I built the code for my research so it is application specific. However, it parses the .psd file byte stream. MATLAB code gives output as Excel file which lists the RSSI, time stamps etc. It also shows if the packet belongs to Master or Slave. The idea is locating the sniffer very close to the slave so that the RSSI is around -35 dbm for slave packets and less for Master. 

Run sniffer_with_role.m. Just change the input .psd file name.

% PSD Input File Name
filename='1m.psd';
filename_output='loc1_out.xls';

So you should write your psd file name by renaming the value of the variable "filename". 
