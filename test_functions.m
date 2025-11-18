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
b3 = [0.0015   -0.0020    0.0002   -0.0009    0.0028   -0.0009    0.0002   -0.0020    0.0015]
a3 = [1.0000   -2.7355    5.9780   -7.8335    8.5654   -6.3463    3.9239   -1.4513    0.4299]
chebyBP = tf(b3, a3, pi)

% peak dip 
b4 = [1.0349   -0.9159    0.7704   -0.4199    0.1551]
a4 = [1.0000   -0.9882    0.7910   -0.3476    0.1694]
peakDip = tf(b4, a4, pi)

% butter bandstop
[b5_1, a5_1] = butter(4, [0.1, 0.5], 'stop')
h5_1 = tf(b5_1, a5_1, pi)
%[b5_2, a5_2] = butter(3, 0.6)
%h5_2 = tf(b5_2, a5_2, pi)
%butterStopLP = h5_1 * h5_2
%[b5, a5] = tfdata(butterStopLP, 'v')

[b5_2, a5_2] = bilinear([0 0 0.25],[1 0.0636 0.25], pi)
h5_2 = tf(b5_2, a5_2, pi)
butterStopLP = h5_1 * h5_2
[b5, a5] = tfdata(butterStopLP, 'v')

bode(chebyLP, chebyHP, chebyBP, peakDip, butterStopLP, wb)
subplot(2,1,1)
title('Bode diagram of all test functions')
ylim([-100 10])
h = legend ('Cheby LP', 'Cheby HP', 'Cheby BP', 'Peak & Dip', 'Butterworth Stop & LP                   ', "location", "northwest");
legend (h, "location", "northwest")

subplot(2,1,2)
h = legend ('Cheby LP', 'Cheby HP', 'Cheby BP', 'Peak & Dip', 'Butterworth Stop & LP                   ', "location", "northwest");
legend (h, "location", "northwest")
