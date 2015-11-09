function adv_type = find_adv_type(arr)
    arr=bi2de(arr);
    switch arr
        case 0
            adv_type='ADV_IND';
        case 1
            adv_type='ADV_DIRECT_IND';
        case 2
            adv_type='ADV_NONCONN_IND';
        case 3
            adv_type='ADV_SCAN_REQ';
        case 4
            adv_type='ADV_SCAN_RSP';
        case 5
            adv_type='ADV_CONNECT_REQ';
        case 6
            adv_type='ADV_DISCOVER_IND';
        otherwise
            adv_type='error';
    end
end
