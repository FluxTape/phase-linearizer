clear all
close all
pkg('load', 'optim');
pkg('load', 'control');

function h_z = tf_ref2()
    b = [0.0023    0.0058    0.0102    0.0118    0.0102    0.0058    0.0023];
    a = [1.0000   -3.2076    4.6897   -3.8538    1.8573   -0.4931    0.0561];
    h_z = tf(b, a, pi);
endfunction

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

w_start = 0
w_end = 0.45
w_points = 100


w = linspace(w_start, w_end, w_points);

tf_ref = tf_ref2();

fq = tf_ref(w);

%bode(tf_ref_old())

err_weights_ = abs(fq);
for k = 1:numel(err_weights_)
    err_weights(k) = err_weights_(k);
endfor
err_weights

ph = unwrap(angle(fq));
dw = w(2)-w(1);
grd_ref = rm_jumps(grad(ph, dw))

output_precision(16);
opt = octave_opt_ap(w_start, w_end, w_points, 6, 0, 0, grd_ref, err_weights, 1)
disp("final opt:");
disp(opt');