function [dbm CRC_OK] = eval_FCS(arr)

%Find RSSI2dbm
    RSSI=bi2de(arr(1,1:8)); 
    dbm=-93+RSSI-1; %-93 is the highest sensitivity
%CRC_OK
    switch arr(16)
        case 1;
          CRC_OK='OK';
        otherwise
          CRC_OK='ERROR';
    end
end
