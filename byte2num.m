function [result] = byte2num(Cell)
total_bytes=length(Cell{1})/8;
sub_Cells=cell(total_bytes,1);
j=1;
for i=total_bytes:-1:1
    sub_Cells{i}=Cell{1}((j-1)*8+1:j*8);
    sub_Cells{i}=fliplr(sub_Cells{i});
    j=j+1;
end
result=[];
for i=1:total_bytes;
    result=horzcat(result,sub_Cells{i});
end
result=bi2de(fliplr(result));
end
