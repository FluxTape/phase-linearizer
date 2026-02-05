clear all
close all
warning('off','Octave:shadowed-function')
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

data_str    = fread( stdin, 'char' );
data_str    = char( data_str.' );
str_tokens  = strsplit( data_str );
output_path = str_tokens{1}
tokens = cellfun( @str2double, str_tokens );
tokens = tokens(2:end);
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
input_is_file        = (tokens(8) > 0)
includes_err_weights = round(tokens(9))
length_weights       = round(tokens(10))
weights_start = 11
weights_end   = weights_start + length_weights - 1
data_start    = weights_end + 1

disp("warning: this optimziation mode is experimental and does not support all options")

if (w_start != 0)
    disp("info: start freq will only be used for error calculation")
endif
if (w_end != 1)
    disp("info: end freq will only be used for error calculation")
endif
if (algo != 0)
    disp("warning: algo setting will be ignored in this mode")
endif
if (iterations != 0)
    disp("warning: iteration setting will be ignored in this mode")
endif
if (input_is_file != 0)
    disp("error: file input not implemented")
    return
endif
if (includes_err_weights != 0)
    disp("warning: err weights will only be used for error calculation")
endif

weights_p = tokens(weights_start:weights_end);
data_p    = tokens(data_start:end);

tf_order = idivide(numel(data_p), int32(2), "fix")
tf_num = data_p(1:tf_order)
tf_den = data_p(tf_order+1:end)
if numel(tf_num) != numel(tf_den)
    disp("transfer function numerator and denominator have mismatched length");
    return
endif

w = linspace(w_start, w_end, w_points_internal);
inputtf = tf(tf_num, tf_den, pi)
[tf_num, tf_den] = tfdata(inputtf, 'v'); % override tf_num, tf_den
fq = inputtf(w);

%{
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
%}

if (includes_err_weights == 2)
    err_weights  = weights_p;
elseif (includes_err_weights == 1)
    err_weights_ = abs(fq);
    for k = 1:numel(err_weights_)
        err_weights(k) = err_weights_(k);
    endfor
    %err_weights
else
    w_points = numel(grd_ref)
    err_weights  = ones(1, w_points);
endif

output_precision(16);
[opt, e_min] = octave_opt_fir(tf_num, tf_den, order, w_start, w_end, w_points_internal, err_weights, show_graph);
disp("final opt:");
disp([opt e_min]');