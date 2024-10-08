clear all
close all
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

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
    %d = min(real(a + ac), 1.62) % ????? 1.62 > pi/2 but should be stable up to 1.999 for small imaginary part 
    d = real(a + ac)
    %b = real(a)^2 + imag(a)^2 
    %d = 2*real(a)
    h_z = (b - d*z + z*z)/(1 - d*z + b*z*z);
endfunction

function h_z = r_th_to_tf_d2(r, theta)
    z = 1/tf('z', pi);
    c = -r;
    d = theta;

    h_z = (-c + d*(1-c)*z + z*z)/(1 + d*(1-c)*z - c*z*z);
endfunction


%[num,den] = cheby2(6,80,0.5)
num = [0.0023    0.0058    0.0102    0.0118    0.0102    0.0058    0.0023]
den = [1.0000   -3.2076    4.6897   -3.8538    1.8573   -0.4931    0.0561]
tf_pre = tf(num, den, pi)

opt = [
    0.770318571380094
    0.143547265193154
    0.782946847174799
    0.437100618941892
    0.819646740700653
    0.937598420828408
    0.836273788136607
    1.199486749246289
    0.875485715778325
    1.444510042645609
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

endfreq = 0.5
for i = 1:numel(w)
    if (w(i) > endfreq)
        len = i;
        break
    endif
endfor

w_cut = w(1:len);
pha_cut = pha(1:len);
p = polyfit(w_cut, pha_cut, 1);
lin = p(2) + w_cut * p(1);

pha_pre_cut = pha_pre(1:len);
p_pre = polyfit(w_cut, pha_pre_cut, 1);
lin_pre = p_pre(2) + w_cut * p_pre(1);

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

