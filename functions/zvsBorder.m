function [IZVS , ZVS_border] = zvsBorder(Isw, Vrem,Io,Vo)
% Write a help statement once it works


IZVS = zeros(length(Vo),1);
ZVS_border = ones(1,length(Vo))*length(Io);
for Vo_cnt = length(Vo):-1:1 
    for Io_cnt = 1:length(Io)
        % Find instance of Vrem > 0
        if Vrem(Vo_cnt,Io_cnt) == 0
            % at operating pont Vo(Vo_cnt),Io(Io_cnt), no more ZVS
            ZVS_border(Vo_cnt) = Io_cnt; 
            IZVS(Vo_cnt) = Isw(Vo_cnt,Io_cnt);
           break
        end

    end
end

end