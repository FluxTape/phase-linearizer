clear all
close all

function pos = update_positions(pos)
    n = numel(pos);
    total = sum(pos);
    if (pos(n) < total)
        for k = flip(1:n-1)
            if (pos(k) != 0)
                pos(k) = pos(k)-1;
                at_n = pos(n);
                pos(n) = 0;
                pos(k+1) = pos(k+1)+1+at_n;
                break;
            endif
        endfor
    endif
endfunction

n = 2
k = 4

positions = zeros(1, k);
positions(1) = n;
pos_total = sum(positions);
disp(positions)
while true
    positions = update_positions(positions);
    disp(positions)
    if (positions(end) == pos_total)
        break;
    endif
endwhile