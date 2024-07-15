function Num = obtainNumbersInStr(fileName)
% obtain the numerics from the file name (group number and run)
    B = regexp(fileName,'(\d*)','tokens');
    for ii= 1:length(B)
      if ~isempty(B{ii})
          Num(ii,1)=str2double(B{ii}(end));
      else
          Num(ii,1)=NaN;
      end
    end

end