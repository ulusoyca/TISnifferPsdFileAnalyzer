clc, clear all

% PSD Input File Name
filename='15m.psd';
filename_output='loc1_out.xls';

%% CONSTANTS
byte=8; % 1 byte = 8 bits

%%%%%%%%%%% PACKET SNIFFER CONSTANTS %%%%%%%%%%%%%%%%%
% Packet_length_raw_data: 
% Used to allocate data buffer used by the GUI to handle 
% incoming packets. 
Packet_length_raw_data=271*byte; % BITS

%Packet Information:
%Contains information used by the packet sniffer to read the 
%data correctly.
%Bit 0:     Length includes FCS.
%Bit 1:     Correlation used.
%Bit 2:     Incomplete packet.
%Bit 3-7:  Not used
Packet_Info_len=1*byte;

%Packet Number
Packet_num_len=4*byte;

%Timestamp:
% 64 bit counter value. To calculate the time in microseconds this 
% value must be divided by a number  depending on the clock speed 
% used to drive the counter tics on the target. The timestamp on 
% the first packet will be used as offset value for all packets. 
%That means that packet number 1 will be shown in the packet 
%sniffer with time = 0.
Timestamp_len=8*byte;
clock_speed_const=625212569/1490598;

% Length:
%Length:
%The length will or will not include the FCS field 
%depending on Bit 0 in the Packet information.
Length_len=1*byte;

%Payload:
%Packet Information Bit 0 = 0 ? n = Length
%Packet Information Bit 0 = 1 ? n = Length – 2
Payload_len=0; % To be defined

%FCS:
%The checksum of the frame has been replaced by the radio chip 
%in the following way:
%BYTE 1:  RSSI and if Correlation used, this byte is also used to 
%calculate the LQI value.
%BYTE 2:  Bit 7:     Indicate CRC OK or not. 
%Bit 6-0: If Correlation used: Correlation value. 
%         If Correlation not used: LQI.
FCS_len= 2*byte;

%%%%%%%%%%%%%%%%%%%%%% PACKET FORMAT CONSTANTS %%%%%%%%%%%%%%
%Preamble:
Preamble_len=1*byte;
%Access Address:
AccessAddr_len=4*byte;
% Access Address for all advertising channel packets
AccessAddr_ADV=[0 1 1 0 1 0 1 1 ...
                0 1 1 1 1 1 0 1 ...
                1 0 0 1 0 0 0 1 ...
                0 1 1 1 0 0 0 1];
           
%CRC
Crc_len=3*byte;

%%%%%%%% HEADER %%%%%%%%

Header_len=2*byte;

%%%%%%%%%% ADV CHANNEL PDU CONSTANTS %%%%%%%%%%%%
% Advertise channel header length
ADV_header_len=2*byte;

% PDU TYPE:
ADV_pdu_type_len=4;

% RFUs
ADV_header_RFU_1_len=2;
ADV_header_RFU_2_len=2;

% Rx Tx add info specific to PDU Type
Tx_Add_len=1;
RX_Add1_len=1;

% Advertise channel Payload length in octets 6-37 
ADV_payload_length_len=6;

init_addr_len=6*byte;
adv_addr_len=6*byte;
conn_int_len=2*byte;
latency_len=2*byte;
timeout_len=2*byte;

%%%%%%%%%%%%%%%%%%%%%% DATA CHANNEL PDU CONSTANTS %%%%%%%%%%%%
%LLID
LLID_len=2;
%Next Expected Sequence Number
NESN_len=1;
% Sequence Number
SN_len=1;
%More data
MD_len=1;
%RFUs
DATA_RFU_1=3;
DATA_RFU_2=3;

% Data channel Payload length in bits
DATA_payload_length_len=5;


%% LOCAL VARIABLES

% Result Matrix:
% ===================================
% [Seq.Number Packet_Type FCS]
% Packet Type: ADVChan:0 ; DATAChan:1;
% FCS: OK:0 ; ERROR:1

% Packet Type:
% ==============
% ADVERTISING PACKET packet_type=0;
% DATA PACKET packet_type=1;  


%% Generate Packet Matrix

% Read total num of bits
fid=fopen(filename);
[A total_num_of_bits]=fread(fid, inf,'*ubit1','ieee-le');
fclose(fid);
total_num_packets=total_num_of_bits/Packet_length_raw_data;
Packets=zeros(total_num_packets,Packet_length_raw_data);
% Generate the packet matrix: Packets
count=1;
for i=1:total_num_packets
    for j=1:Packet_length_raw_data
        Packets(i,j)=A(count);
        count=count+1;
    end
end

%%

Packet_num=cell(total_num_packets,1);
Timestamp=cell(total_num_packets,1);
Time_plus=cell(total_num_packets,1);
Length=cell(total_num_packets,1);
AccessAddr=cell(total_num_packets,1);
Header=cell(total_num_packets,1);
LLID=cell(total_num_packets,1);
NESN=cell(total_num_packets,1);
SN=cell(total_num_packets,1);
MD=cell(total_num_packets,1);
ADV_TYPE{i,1}=cell(total_num_packets,1);
PDU_length{i,1}=cell(total_num_packets,1);
FCS=cell(total_num_packets,1);
PDU=cell(total_num_packets,1);
CRC_OK=cell(total_num_packets,1);
Packet_type=cell(total_num_packets,1);
dbm=cell(total_num_packets,1);
GAPRole=cell(total_num_packets,1);
num_of_FCS_error=0;
num_of_ADV_packets=0;
num_of_DATA_packets=0;


for i=1:total_num_packets
    
    %The length will or will not include the FCS field 
    %depending on Bit 0
    TEMP=Packets(i,1:Packet_length_raw_data);
    
    % Is FCS included?
    offset=1; %first bit
    FCS_not_included=Packets(i,offset); %0->n=length (Yes); 1->n=length-2(No)
    
    % Is packet incomplete?
    Is_packet_incomplete=Packets(i,offset+2);
    offset=offset+Packet_Info_len; % offset=1+8=9
    
    % Packet Sequence Number 
    Packet_num{i,1}=TEMP(1,offset:offset+Packet_num_len-1);
    offset=offset+Packet_num_len; % offset=9+32=41
    Packet_num{i,1}=byte2num(Packet_num(i,1));
    
    % Timestamp - milliseconds
    Timestamp{i,1}=TEMP(1,offset:offset+Timestamp_len-1);
    offset=offset+Timestamp_len; % offset=41+64=105
    Timestamp{i,1}=byte2num(Timestamp(i,1));
    if i==1
        time_offset=Timestamp{i,1};
    end
    Timestamp{i,1}=round((Timestamp{i,1}-time_offset)/(1000*clock_speed_const));
    
    %Time+
    if i~=1
    Time_plus{i,1}=Timestamp{i,1}-Timestamp{i-1,1};
    else
    Time_plus{i,1}=0;
    end
    
    % Length
    Length{i,1}=TEMP(1,offset:offset+Length_len-1);
    offset=offset+Length_len; % offset=105+8=113
    Length{i,1}=byte2num(Length(i,1));
    
    offset_PACKET_end=offset+Length{i,1}*byte;
    % This can be used to access the packets following the payload
    
    %%%%%%%%%%%%%%%%%%% Payload %%%%%%%%%%%%%%%%%%%%%
        
    % Access Addres
    AccessAddr{i,1}=TEMP(1,offset:offset+AccessAddr_len-1);
    offset=offset+AccessAddr_len; % offset=113+32=145
    AccessAddr{i,1}=dec2hex(byte2num(... 
        AccessAddr(i,1)));
    
    %----> Determine Packet Type using Access Address
    switch strcmp(AccessAddr(i,1), '8E89BED6')
        case 1;  % ADVERTISING PACKET
            Packet_type{i,1}='ADV';
        case 0;  % DATA PACKET
            Packet_type{i,1}='DATA';
        otherwise
            Packet_type{i,1}='ERROR';
    end
    
    % Header
    Header{i,1}=TEMP(1,offset:offset+Header_len-1);
    offset=offset+Header_len; % offset=145+16=161
    
    
    %----> Extract Data from Header
    
    % If it is Advertisement Packet
    if strcmp(Packet_type{i,1},'ADV')  % ADVERTISING PACKET
        ADV_TYPE{i,1} = find_adv_type(Header{i,1}(1:4));         
        PDU_length{i,1} = bi2de((Header{i,1}(9:14)));
        PDU_len=PDU_length{i,1}*byte;
    end
    
    % If it is DATA Packet
    if strcmp(Packet_type{i,1},'DATA');  % DATA PACKET
        LLID{i,1} = find_llid_type(Header{i,1}(1:2));
        NESN{i,1} = Header{i,1}(3);
        SN{i,1} = Header{i,1}(4);
        MD{i,1} = Header{i,1}(5);
        PDU_length{i,1} = bi2de((Header{i,1}(9:13)));
        PDU_len=PDU_length{i,1}*byte;
    end
    
    % PDU
    PDU{i,1}=TEMP(1,offset:offset+PDU_len-1);
    %offset=offset+PDU_len; % offset=145+PDU_len
    
    % If it is Advertisement Packet
    if strcmp(Packet_type{i,1},'ADV') ...
            && strcmp(ADV_TYPE{i,1},'ADV_CONNECT_REQ')
            
            init_addr=PDU{i,1}(1,1:init_addr_len);
             init_addr=dec2hex(bi2de(init_addr));
            pdu_offset=init_addr_len+1;
            
            adv_addr=PDU{i,1}(pdu_offset:pdu_offset+...
                adv_addr_len-1);
            adv_addr=dec2hex(bi2de(adv_addr));
            pdu_offset=pdu_offset+adv_addr_len+10*byte;
            
            conn_interval=PDU{i,1}(pdu_offset:...
                pdu_offset+conn_int_len-1);
            pdu_offset=pdu_offset+conn_int_len;
            conn_interval=bi2de(conn_interval)*1.25;
            
            latency=PDU{i,1}(pdu_offset:...
                pdu_offset+latency_len-1);
            pdu_offset=pdu_offset+latency_len;
            latency=bi2de(latency)*1.25;
            
            timeout=PDU{i,1}(pdu_offset:...
                pdu_offset+timeout_len-1);
            timeout=bi2de(timeout)*10;
    end
    
    %FCS
    if FCS_not_included
        offset=offset_PACKET_end;
        FCS{i,1}=TEMP(1,offset:offset+FCS_len-1);
        [dbm{i,1} CRC_OK{i,1}] = eval_FCS(FCS{i,1});
        
    else
        offset=offset_PACKET_end-1;
        FCS{i,1}=TEMP(1,offset-FCS_len+1:offset);
        [dbm{i,1} CRC_OK{i,1}] = eval_FCS(FCS{i,1});
    end
    
    %GAP Role
    if dbm{i,1}<-60
        GAPRole{i,1}='MASTER';
    elseif dbm{i,1}>-50
        GAPRole{i,1}='SLAVE';
    else GAPRole{i,1}='?';
    end
    if strcmp(CRC_OK{i,1},'ERROR') 
        num_of_FCS_error=num_of_FCS_error+1;
    end
    if strcmp(Packet_type{i,1},'ADV')
        num_of_ADV_packets=num_of_ADV_packets+1;
    end
    if strcmp(Packet_type{i,1},'DATA')
        num_of_DATA_packets=num_of_DATA_packets+1;
    end
end

Packet_Err_Rate=num_of_FCS_error/Packet_num{length(Packet_num)};


XLS_cells=[ {'Connection Interval: (milliseconds)'}, {conn_interval}, {''},{''}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Latency: (milliseconds)'}, {latency}, {''}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Supervision Timeout: (milliseconds)'}, {timeout}, {''}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Advertiser Address:'}, {adv_addr}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Initiator Address:'}, {init_addr}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {''},{''},{''}, {''}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Total Number of packets:'}, {Packet_num{length(Packet_num)}}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Total Number of ADV packets:'}, {num_of_ADV_packets}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Total Number of DATA packets:'}, {num_of_DATA_packets},{''}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Number of FEC Errors:'}, {num_of_FCS_error},{''}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Packet Error Rate:'}, {Packet_Err_Rate},{''}, {''},{''},{''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {''},{''},{''}, {''},{''}, {''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {''},{''},{''}, {''},{''}, {''},{''},{''},{''},{''},{''},{''},{''},{''};...
    {'Packet Number'}, {'Timestamp (us)'},{'Time+ (us)'}, {'Access Address'}, {'Packet Type'}, {'ADV Type'}, {'LLID'}, {'NESN'}, {'SN'}, {'MD'}, {'PDU Length'}, {'ROLE'}, {'CRC_OK'}, {'dbm'};...
    Packet_num, Timestamp, Time_plus, AccessAddr, Packet_type, ADV_TYPE, LLID, NESN, SN, MD, PDU_length, GAPRole, CRC_OK, dbm];

XLS_cells2=[ 
    {'Packet Number'},{'Time+ (us)'}, {'LLID'}, {'NESN'}, {'SN'}, {'MD'}, {'ROLE'},{'PDU Length'}, {'CRC_OK'}, {'dbm'};...
    Packet_num, Time_plus,  LLID, NESN, SN, MD, GAPRole, PDU_length, CRC_OK, dbm];

xlswrite('analyze_flow.xls', XLS_cells2, 1);




