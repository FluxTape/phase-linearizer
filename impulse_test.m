clear all
close all
pkg('load', 'optim');
pkg('load', 'control');

function b = approx_eq(v1, v2, epsilon)
    d = abs(v1 - v2);
    b = (d < epsilon);
endfunction

function pha_out = rm_pi_jumps(pha_in)
    n = numel(pha_in);
    epsilon = 0.2;
    rolling_offset = 0;
    pha_out = [pha_in(1)];
    for idx = 2:n;
        if (approx_eq(pha_in(idx) - pha_in(idx-1), pi, epsilon))
            rolling_offset -= pi;
        elseif (approx_eq(pha_in(idx) - pha_in(idx-1), -pi, epsilon))
            rolling_offset += pi;
        endif
        pha_out(idx) = pha_in(idx) + rolling_offset;
    endfor
endfunction

[y, fs] = audioread("../test-data/impulse3b.wav");
mono = sum(y')/2;
s_y = size(y)
s_mono = size(mono)
fs

n1 = size(y)
% fresp = fft(mono);
% n2 = size(fresp)
fi = linspace(0, fs, numel(mono));
% numel(fi)
% figure 1
% plot(fi, real(fresp), fi, imag(fresp))
% grid on

figure 1
freqz(mono, 1, 512, fs)

figure 2
[H2, f_n] = freqz(mono, 1, 2048, fs);
pha = unwrap(angle(H2))';
pha = rm_pi_jumps(pha);
plot(f_n, pha*180/pi)
grid on
