function llid_type = find_llid_type(arr)
    arr=bi2de(arr);
    switch arr
        case 1
            llid_type='LL DATA PDU (EMPTY)';
        case 2
            llid_type='LL DATA PDU (COMPLETE)';
        case 3
            llid_type='LL CONTROL PDU';
        otherwise
            llid_type='error';
    end
end
