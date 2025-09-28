clear all
close all
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

function [k, d] = wlinfit(x, y, err_weights)
    w = err_weights;
    n1 = size(x)
    n2 = size(y)
    n3 = size(w)

    xmw = sum(x.*w)/sum(w)
    ymw = sum(y.*w)/sum(w)
    k = sum(w.*(x - xmw).*(y - ymw)) / sum(((x - xmw).^2).*w)
    d = ymw - k*xmw;
endfunction

function h_z = r_th_to_tf(r, theta)
    a1 = 2*r/theta;
    b1 = 1/(theta*theta);
    num = [b1   -a1    1];
    den = [b1    a1    1];
    h_z = tf(num, den);
endfunction

function h_z = r_th_to_tf_d(r, theta)
    %s = tf('s')
    %z = c2d(1/s, pi)
    r
    theta
    z = 1/tf('z', pi);
    a = r*exp(1i * theta)
    ac = conj(a);
    b = real(a*ac)
    d = real(a + ac)
    h_z = (b - d*z + z*z)/(1 - d*z + b*z*z);
endfunction

function h_z = r_th_to_tf_d2(r, theta)
    z = 1/tf('z', pi);
    c = -r;
    d = theta;

    h_z = (-c + d*(1-c)*z + z*z)/(1 + d*(1-c)*z - c*z*z);
endfunction


%[num,den] = cheby2(4,70,[0.2, 0.6],'bandpass')
num = [0.0015   -0.0020    0.0002   -0.0009    0.0028   -0.0009    0.0002   -0.0020    0.0015]
den = [1.0000   -2.7355    5.9780   -7.8335    8.5654   -6.3463    3.9239   -1.4513    0.4299]
tf_pre = tf(num, den, pi)

opt = [
   9.086818539165293e-01
   1.123662242021393e+00
   1.896829765404781e-05
   3.141592653343406e+00
   9.052555094140565e-01
   1.240505687310595e+00
   9.876779354484179e-04
   1.193221305861999e-06
   9.623245079376546e-01
   8.269680192297365e-01
   9.352862713438788e-01
   1.421952529288832e+00
   9.432252821699838e-01
   9.323536855164043e-01
   9.512443308399032e-01
   1.530049160067190e+00
]';
rs = [];
thetas = [];
for i = 1:numel(opt)
    if (rem (i, 2) == 1) 
        rs(end+1) = opt(i);
    else 
        thetas(end+1) = opt(i);
    endif
endfor

rs
thetas

figure 1
tf_ap_chain = 1;
tf_aps = {};
for i = 1:numel(rs)
    tf_ap = r_th_to_tf_d(rs(i), thetas(i));
    tf_aps{end+1} = tf_ap;
    tf_ap_chain *= tf_ap;
endfor
tf_full = tf_ap_chain * tf_pre;
bode(tf_aps{:})

figure 2
bode(tf_full)
[mag, pha, w] = bode(tf_full);
[mag_pre, pha_pre, w_pre] = bode(tf_pre, w);
err_weights = mag_pre';

startfreq = 0.2
for i = 1:numel(w)
    if (w(i) > startfreq)
        startidx = i;
        break
    endif
endfor

endfreq = 0.6
for i = 1:numel(w)
    if (w(i) > endfreq)
        endidx = i;
        break
    endif
endfor

w_cut = w(startidx:endidx);
pha_cut = pha(startidx:endidx);
[k1, d1] = wlinfit(w, pha', err_weights);
lin = d1 + w_cut * k1;

pha_pre_cut = pha_pre(startidx:endidx);
[k2, d2] = wlinfit(w, pha_pre', err_weights);
lin_pre = d2 + w_cut * k2;

figure 3
plot(w_cut, pha_cut, w_cut, lin, w_cut, pha_pre_cut, w_cut, lin_pre)

figure 4
[num_full, den_full] = tfdata(tf_full, 'v');
[g1, w1] = grpdelay(num_full, den_full);
[num_ap, den_ap] = tfdata(tf_ap_chain, 'v');
[g2, w2] = grpdelay(num_ap, den_ap);
[num_pre, den_pre] = tfdata(tf_pre, 'v');
[g3, w3] = grpdelay(num_pre, den_pre);
plot(w1, g1, w2, g2, w3, g3)

maxgrp = 0;
maxgrp_w = 0;
for i = 1:numel(g3) 
    if (g3(i) > maxgrp)
        maxgrp = g3(i);
        maxgrp_w = w3(i);
    endif
endfor
maxgrp
maxgrp_w

