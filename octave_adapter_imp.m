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

w_start              = round(tokens(1))
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

err_at = find(isnan(tokens(1:weights_end)));
if !isempty(err_at)
    disp("failed to parse input at index:");
    err_at
    return
endif
weights_p = tokens(weights_start:weights_end);

data_p = [];
if (input_is_file)
    filename = [str_tokens(data_start:end)]{1}
    [dir_, name, ext] = fileparts(filename)
    if (ext == ".txt" || ext == ".csv")
        data_p = csvread(filename);
    else
        [y, fs] = audioread(filename);
        data_p = [fs y(:, 1)'];
    endif
else
    data_p = tokens(data_start:end);
endif

err_at = find(isnan(data_p));
if !isempty(err_at)
    disp("failed to parse data section at index:");
    err_at
    return
endif

disp("WARNING: Impulse Response mode is very experimental and the generated data should not be trusted")

fs = data_p(1)
h_imp = data_p(2:end);
s_h_imp = size(h_imp)

grpdelay(h_imp, 512, fs)
[grd_ref, wx] = grpdelay(h_imp, 512, fs);
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
    [H2, f_n] = freqz(h_imp, 1, 2048, fs);
    err_weights_ = abs(H2);
    for k = 1:numel(err_weights_)
        err_weights(k) = err_weights_(k);
    endfor
    %err_weights
else
    w_points = numel(grd_ref)
    err_weights  = ones(1, w_points);
endif
gradient_ref = grd_ref;

output_precision(16);
[opt, e_min] = octave_opt_ap(w_start, w_end, w_points_internal, order, algo, iterations, gradient_ref, err_weights, show_graph, output_path);
disp("final opt:");
disp([opt e_min]');



