# TISnifferPsdFileAnalyzer

The SmartRF Packet Sniffer is a PC software application used to display and store RF packets captured with a listening RF HW node. Multiple RF protocols are supported. The Packet Sniffer filters and decodes packets and displays them in a convenient way, with options for filtering and storage to a binary file format.

The CC2540 dongle is delivered pre-programmed with dedicated packet sniffer firmware. Dongles that are delivered with the kits CC2540EMK-USB have pre-programmed packet sniffer firmware and can be used for packet sniffing straight away, whereas dongles contained in other kits may have to be programmed. The packet sniffer hex file can be found in the following directory:  <installation directory>\General\Firmware\sniffer_fw_cc2540.hex

The firmware can be programmed with the SmartRF Flash Programmer. To program the firmware on the CC2540 Dongle, it must be connected to SmartRF05EB or the CC Debugger via the debug connector.

On the PC side the packets will be stored in a disk buffer. The total amount of packets that can be stored depends on the packet size and the size of the hard disk. During operation the packets will be cached in a RAM buffer to improve the access time when a packet is to be displayed in the GUI.

If the PC application is not able to read the packets from the connected devices data buffer fast enough, an “Overflow” error will be given by the device and the packet sniffer will show the error on screen.

The capture device currently ignores the connection timeout parameter for an active connection. This means that the sniffer will not know that a connection between two BLE devices is "down" if no new packets are received for the duration of the connection timeout. The reason this is not supported by the sniffer, is to remedy the case where the sniffer follows a data connection between two remote devices and thus is likely to lose a number of packets for a period of time that exceeds the connection timeout. When the actual connection is terminated due to a connection timeout, the sniffer must be stopped (click the pause/stop icon) and restarted (click the play icon) in order to follow a new connection.

Packet Sniffer GUI does not allow the export of the PSD file in any other text format. The output is a binary file. Hence, in order to get meaningful information and analyze the packet traffic in a more structured way, the binary output file is read using MATLAB. To achieve that, the structure of the BLE packets should be analyzed carefully. 

The Link Layer has only one packet format used for both advertising channel and data channel packets. Each packet consists of four fields: the preamble, the access address, the PDU and CRC.

![alt tag](http://i.imgur.com/6Omo7Ya.png?1)

![alt tag](http://i.imgur.com/EtAt4ot.png?1)

![alt tag](http://i.imgur.com/7Aehd5F.jpg?1)


The MATLAB files in are used to read the psd file and export the meaningful information to an excel file. 

Using the MATLAB script information about each packet can be viewed. Table below shows the BLE packets row by row. “Packet no” is the packet sequence number; “Time+” is the time interval between two consequent packets; “NESN” is the next expected sequence number; “SN” is the sequence number; “MD” means More Data; “Role” shows the GAP Role of the sender, “Packet per Event” shows the number of notification packets that are sent in one event; “PDU length” is the length of the payload; “Order” shows the tag of the packet. In this case 4 packets are sent and tag shows the sequence order of the packet. “Error” shows if the packet is lost or has CRC error based on the developed MATLAB script; “FCS” indicates if the sniffer (USB dongle) received the packet with CRC error; and finally “dBm” shows the power strength of each packet in dBm.

Packet NO	  Time+ (ms)	NESN	SN	MD	ROLE	    Packet per Event	  PDU Length	  Order	  ERROR	  FCS	dbm
											
6435	      74	          0	  0	  0	  MASTER	    Event:4	              0			                    OK	-59
6436	      1	            1	  0	  1	  SLAVE		                          27	      #1		          OK	-31
6437	      0	            1	  1	  0	  MASTER		                        0			                    OK	-59
6438	      0	            0	  1	  1	  SLAVE		                          27	      #2		          OK	-30
6439	      1	            0	  0 	0	  MASTER	  	                      0		              	      OK	-59
6440	      0	            1	  0	  1	  SLAVE		                          27	      #3		          OK	-31
6441	      0	            1   1	  0	  MASTER		                        0		           ERROR-FCS	OK	-59
6442	      1	            0	  1	  0	  SLAVE		                          27	      #4		          OK	-30
6443	      0	            1	  1	  0	  MASTER		                        0		LOST-SLAVE	          OK	-59
6444	      73	          1	  1	  ---	MASTER	  Event:1                 	-	---		---	---
6445	      0	            0	  1	  0	  SLAVE		                          27	      #4	          	OK	-30
6446	      74	          0	  0	  0	  MASTER	 Event:0	                0			                    OK	-66
6447	      1	            1	  0	  0	  SLAVE		                          0			                    OK	-30

Table	3.2	Packet information extracted from .psd file


The packet that have “---” value shows that although being sent by either slave or master it is not received by the sniffer. In many cases some of the packets are not received by the sniffer due to some SW or HW problems. These packets are generated by the MATLAB program based on the SN and NESN values of the other received packets. 
It can be seen that although 6441st packet is retransmitted because of CRC error, the sniffer did not indicate any errors. Hence, the error output of sniffer should be ignored. MATLAB scripts in Appendix B, are used to detect the errors and lost packets considering the possible sniffer errors. 
The flow chart of the algorithm to determine the errors is in Figure 3.9. The algorithm is composed of two parts. First, it detects the packets that are missed by the sniffer. The program inserts the missing packets by filling the SN and NESN values. The next part determines the errors and lost packets. The algorithm is generated based on Bluetooth Version.4 core specification. The rules in figure 3.10 are applied to detect errors and lost packets. 

The packet that have “---” value shows that although being sent by either slave or master it is not received by the sniffer. In many cases some of the packets are not received by the sniffer due to some SW or HW problems. These packets are generated by the MATLAB program based on the SN and NESN values of the other received packets. 
It can be seen that although 6441st packet is retransmitted because of CRC error, the sniffer did not indicate any errors. Hence, the error output of sniffer should be ignored. MATLAB scripts in Appendix B, are used to detect the errors and lost packets considering the possible sniffer errors. 
The flow chart of the algorithm to determine the errors is in Figure 3.9. The algorithm is composed of two parts. First, it detects the packets that are missed by the sniffer. The program inserts the missing packets by filling the SN and NESN values. The next part determines the errors and lost packets. The algorithm is generated based on Bluetooth Version.4 core specification. The rules in figure 3.10 are applied to detect errors and lost packets. 

![alt tag](http://i.imgur.com/DHbcdYt.png?1)
