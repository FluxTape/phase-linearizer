clear all
close all
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

function g = grad(v, delta)
    n = numel(v);
    d = [];
    for i = 2:(n-1)
        d(i) = v(i+1)-v(i-1);
    endfor
    % interpolate first and last point
    d(1) = 2*d(2) - d(3);
    d(n) = 2*d(n-1) - d(n-2);
    g = -d./(2*delta);
endfunction

function g = rm_jumps(v)
    n = numel(v);
    last_good_idx = 1
    i = 1;
    need_fix = false;
    for i = 1:n;
        d = v(i) - v(last_good_idx);
        if (abs(d) < 100) % -> i = next good idx
            if (need_fix) % fix up entries
                d_idx = i - last_good_idx;
                for k = 1:d_idx;
                    v(last_good_idx+k) = v(last_good_idx) + (d*k/d_idx)
                endfor
            endif
            last_good_idx = i;
            need_fix = false;
        else
            need_fix = true;
        endif;
    endfor
    g = v;
endfunction

data_str   = fread( stdin, 'char' );
data_str   = char( data_str.' );
str_tokens = strsplit( data_str );
tokens     = cellfun( @str2double, str_tokens );
if isnan(tokens(end))
    tokens = tokens(1:end-1);
endif
err_at = find(isnan(tokens));
if !isempty(err_at)
    disp("failed to parse input at index:");
    err_at
    return
endif
w_start              = tokens(1)
w_end                = tokens(2)
w_points_internal    = round(tokens(3))
order                = round(tokens(4))
show_graph           = (tokens(5) > 0)
algo                 = round(tokens(6))
iterations           = round(tokens(7))
includes_err_weights = round(tokens(8))
length_data          = round(tokens(9))
length_weights       = round(tokens(10))
data_start = 11
data_end = data_start+length_data-1
weights_start = data_end+1
weights_end = weights_start+length_weights-1
data_p = tokens(data_start:data_end);
weights_p = tokens(weights_start:weights_end);

tf_order = idivide(numel(data_p), int32(2), "fix")
tf_num = data_p(1:tf_order)
tf_den = data_p(tf_order+1:end)
if numel(tf_num) != numel(tf_den)
    disp("transfer function numerator and denominator have mismatched length");
    return
endif

w = linspace(w_start, w_end, w_points_internal);
h_z = tf(tf_num, tf_den, pi)
[tf_num, tf_den] = tfdata(h_z, 'v'); % override tf_num, tf_den
fq = h_z(w);


%ph = unwrap(angle(fq));
%dw = w(2)-w(1);
%grd_ref = rm_jumps(grad(ph, dw));

[grd_ref, wx] = grpdelay(tf_num, tf_den);
wx /= pi;
start_idx = 1;
for k = 1:numel(wx);
    if (wx(k) > w_start)
        start_idx = k;
        break
    endif
endfor
end_idx = 1;
for k = numel(wx):-1:1;
    if (wx(k) < w_end)
        end_idx = k;
        break
    endif
endfor
start_idx
end_idx

grd_ref = grd_ref(start_idx:end_idx)';
n_grd = numel(grd_ref)

maxgrp = 0;
maxgrp_w = 0;
for i = 1:numel(grd_ref) 
    if (grd_ref(i) > maxgrp)
        maxgrp = grd_ref(i);
        maxgrp_w = wx(i);
    endif
endfor
maxgrp
maxgrp_w

if (includes_err_weights == 2)
    err_weights  = weights_p;
elseif (includes_err_weights == 1)
    err_weights_ = abs(fq);
    for k = 1:numel(err_weights_)
        err_weights(k) = err_weights_(k);
    endfor
    err_weights
else
    w_points = numel(grd_ref)
    err_weights  = ones(1, w_points)
endif

%grd_ref

output_precision(16);
[opt, e_min] = octave_opt_ap(w_start, w_end, w_points_internal, order, algo, iterations, grd_ref, err_weights, show_graph);
disp("final opt:");
disp([opt e_min]');
