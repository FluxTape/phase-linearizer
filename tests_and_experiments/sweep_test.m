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

% https://dsp.stackexchange.com/questions/87030/how-can-i-convert-the-sweep-signal-into-the-impulse-response

[sweep, sweep_fs] = audioread("../test-data/sweep.wav");
[y, fs] = audioread("../test-data/impulse3_sweep.wav");
if (fs != sweep_fs)
    disp("err sample rates don't match")
    return
endif
sweep = sweep(:,1)'; % select left channel
%sweep = [sweep, zeros(1, numel(sweep))];
s_sweep = size(sweep)

mono = sum(y')/2;
%mono = [mono, zeros(1, numel(mono))];
s_y = size(y)
s_mono = size(mono)
fs

% x is the sweep used for the measurement
% y is the measurement (output of the DUT when excited with the sweep)

% Here I assume the length of the measurement vector is adequately long to avoid aliasing artefacts from the DUT's impulse response
X = fft(sweep, numel(mono)); % Input signal in frequency domain
Y = fft(mono); % Output signal in frequency domain

% Calculate the transfer function
H = Y./X; % Transfer function (frequency-domain)

% Go back to the time domain
h = ifft(H); % Impulse response (time-domain)
h_s = fftshift(h); % This is needed due to the implementation of the FFT algorithm

figure 1
samples = linspace(-numel(h_s)/2, numel(h_s)/2, numel(h_s));
plot(samples, h_s)
grid on

% remove upper half (mirror)
hl = h(1:end/2);

figure 2
fi = linspace(0, 1000, numel(hl));
freqz(hl, 1, 512, fi, fs)

figure 3
[H2, f_n] = freqz(hl, 1, 512, fi, fs)
pha = unwrap(angle(H2))';
pha = rm_pi_jumps(pha);
plot(f_n, pha*180/pi)
grid on
