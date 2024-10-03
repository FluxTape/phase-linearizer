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
    d = min(real(a + ac), 1.62) % ????? 1.62 > pi/2 but should be stable up to 1.999 for small imaginary part 
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


[num,den] = cheby2(6,80,0.5)
tf_pre = tf(num, den, pi)

opt = [
8.428744405373375e-01
8.897940216355185e-02
8.472149612570028e-01
2.714757678578220e-01
8.550548822826953e-01
4.649625348131670e-01
8.997544094546336e-01
9.084872915841748e-01
9.158553304070369e-01
1.078717065385790e+00
9.307309968182335e-01
1.243548666871110e+00
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
full_tf = 1;
tf_aps = {};
for i = 1:numel(rs)
    tf_ap = r_th_to_tf_d(rs(i), thetas(i));
    tf_aps{end+1} = tf_ap;
    full_tf *= tf_ap;
endfor
%full_tf *= tf_pre;
bode(tf_aps{:})

figure 2
bode(full_tf)
[mag, pha, w] = bode(full_tf);
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
[num_full, den_full] = tfdata(full_tf, 'v');
grpdelay(num_full, den_full)
figure 5
%[num, den] = tfdata(tf_pre * full_tf, 'v');
grpdelay(num, den)