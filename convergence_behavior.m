clear all
close all
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

num_runs = 30

w_start = 0.1
w_end = 0.9
w_points_internal = 150
order = 8
algo = 3
iterations = 300
show_plot = 0
tf_num = [0.0015   -0.0020    0.0002   -0.0009    0.0028   -0.0009    0.0002   -0.0020    0.0015]
tf_den = [1.0000   -2.7355    5.9780   -7.8335    8.5654   -6.3463    3.9239   -1.4513    0.4299]

% -- taken from octave_adapter_tf
w = linspace(w_start, w_end, w_points_internal);
h_z = tf(tf_num, tf_den, pi)
[tf_num, tf_den] = tfdata(h_z, 'v'); % override tf_num, tf_den
fq = h_z(w);

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

err_weights_ = abs(fq);
for k = 1:numel(err_weights_)
    err_weights(k) = err_weights_(k);
endfor
gradient_ref = grd_ref;
% --------------

filename = mat2str([w_start w_end w_points_internal order algo iterations tf_num tf_den])
filepath ="../test-data/"
full_filename = sprintf("%s%s.csv", filepath, filename)
for i = 1:num_runs
    [opt, e_min, best_errs] = octave_opt_ap(w_start, w_end, w_points_internal, order, algo, iterations, gradient_ref, err_weights, show_plot);
    csvwrite(full_filename, best_errs, "-append")
endfor
