clear all
close all
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

[z, p, k] = buttap(2)
[num, den] = zp2tf(z, p, k)
[numz, denz] = bilinear(z, p, k, pi)