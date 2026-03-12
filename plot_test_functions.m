clear all
close all
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

figure 1;
wb = linspace(0.01, 1, 512);

% cheby lp
[b1,a1] = cheby2(6,80,0.5)
chebyLP = tf(b1, a1, pi)

% cheby hp
[b2,a2] = cheby2(7,60,0.7,'high')
chebyHP = tf(b2, a2, pi)

% cheby bp (matlab cheby2(4,70,[0.2, 0.6],'bandpass'))
b3 = [1.5451e-03  -1.9713e-03   2.1760e-04  -9.3270e-04   2.7666e-03  -9.3270e-04   2.1760e-04  -1.9713e-03   1.5451e-03]
a3 = [1.0000e+00  -2.7355e+00   5.9780e+00  -7.8335e+00   8.5654e+00  -6.3463e+00   3.9239e+00  -1.4513e+00   4.2989e-01]
chebyBP = tf(b3, a3, pi)

% peak dip 
b4 = [1.0349   -0.9159    0.7704   -0.4199    0.1551]
a4 = [1.0000   -0.9882    0.7910   -0.3476    0.1694]
peakDip = tf(b4, a4, pi) ^2
[b4_1, a4_1] = tfdata(peakDip, 'v')
%results in:
%num = [1.071018  -1.895730   2.433447  -2.280328   1.683715  -0.931094   0.415294  -0.130253   0.024056]
%den = [1.000000  -1.976400   2.558539  -2.258532   1.651478  -0.884705   0.388817  -0.117767   0.028696]


% butter bandstop
[b5_1, a5_1] = butter(4, [0.1, 0.5], 'stop')
h5_1 = tf(b5_1, a5_1, pi)
[b5_2, a5_2] = bilinear([0 0 0.25],[1 0.07 0.25], pi)
h5_2 = tf(b5_2, a5_2, pi)
butterStopLP = h5_1 * h5_2
[b5, a5] = tfdata(butterStopLP, 'v')
%results in:
%b5 = [0.059720  -0.227672   0.360950  -0.130451  -0.415327   0.726934  -0.415327  -0.130451   0.360950  -0.227672   0.059720]
%a5 = [1.0000e+00  -3.9182e+00   7.9612e+00  -1.1212e+01   1.1767e+01  -9.4018e+00   5.8497e+00  -2.7816e+00   9.3618e-01  -2.0557e-01   2.6283e-02]

bode(chebyLP, chebyHP, chebyBP, peakDip, butterStopLP, wb)
subplot(2,1,1)
title('Bode diagram of all test functions')
ylim([-100 10])
h = legend ('Cheby LP', 'Cheby HP', 'Cheby BP', 'Peak & Dip', 'Stop & LP                   ', "location", "northwest");

subplot(2,1,2)
h = legend ('Cheby LP', 'Cheby HP', 'Cheby BP', 'Peak & Dip', 'Stop & LP                   ', "location", "southwest");

figure 2;
grpdelay(b1, a1)
hold on;
grpdelay(b2, a2)
grpdelay(b3, a3)
grpdelay(b4_1, a4_1)
grpdelay(b5, a5)
hold off;
title('Group delay of test functions')
h = legend ('Cheby LP', 'Cheby HP', 'Cheby BP', 'Peak & Dip', 'Stop & LP                   ', "location", "northeast");
