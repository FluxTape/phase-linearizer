clear all
close all
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

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

function b = is_steeper(w, pha_in, k)
    b = true;
    for idx = 1:numel(w)
        if (w(idx)*k > pha_in(idx))
            b = false;
            return;
        endif 
    endfor
endfunction

function target_delay = find_target_delay(w, pha_in)
    k = pha_in(end)/w(end) + 0.001;
    while (!is_steeper(w, pha_in, k))
        k *= 1.01;
    endwhile
    target_delay = k;
endfunction

num = [0.0023    0.0058    0.0102    0.0118    0.0102    0.0058    0.0023]
den = [1.0000   -3.2076    4.6897   -3.8538    1.8573   -0.4931    0.0561]
#num = [1.0349   -0.9159    0.7704   -0.4199    0.1551]
#den = [1.0000   -0.9882    0.7910   -0.3476    0.1694]
#num = [0.0015   -0.0020    0.0002   -0.0009    0.0028   -0.0009    0.0002   -0.0020    0.0015]  
#den = [1.0000   -2.7355    5.9780   -7.8335    8.5654   -6.3463    3.9239   -1.4513    0.4299]
tf_pre = tf(num, den, pi/2)

num_points = 60
w = linspace(0, pi, num_points);
[mag, pha, w] = bode(tf_pre, w);

% pha to radians
pha = pha*pi/180;
pha = rm_pi_jumps(pha);

%k = find_target_delay(w, pha)
%wk = w*k;
%lin_dif = wk - pha;
figure 5
plot(w, pha)
%plot(w, pha, w, wk, w, lin_dif)



fresp = [];
for n = 1:numel(w)
    fresp(n)  = 1*exp(1i*pha(n));
endfor

%fresp = [zeros(1, 50), ones(1, 100), zeros(1, 50)];
%fresp = [ones(1, 100), zeros(1, 100)];
Y1=fresp;
Y2 = [Y1(1)/2 Y1(2:end)/2 fliplr(conj(Y1(2:end)))/2 ];
fresp=Y2;

w_sym = linspace(-pi, pi, numel(fresp));

numel(fresp)

figure 1
plot(w_sym, real(fresp), w_sym, imag(fresp))

fir = ifft(fresp);
fir_n = numel(fir)
%fir = [fir((end+1)/2:end) fir(1:(end-1)/2)];
fir = ifftshift(fir);
fir_n2 = numel(fir)
fir = fliplr(fir);
%window = blackman(numel(fir))';
window = hamming(numel(fir))';
%window = hanning(numel(fir))';
%window = kaiser(numel(fir))';
%window = chebwin(numel(fir))';
%window = ultrwin(numel(fir), -0.2, 2.1)';



fir = fir .* window *2;

figure 2
plot(w_sym, fir)

figure 7
freqz(fir, 1, numel(pha)*2);
[h, w_n] = freqz(fir, 1, numel(pha)*2);
fir_pha = unwrap(angle(h))';
fir_pha = fir_pha(1:end/2);
figure 3
numel(w)
numel(fir_pha)
pha_combined = fir_pha+pha;
plot(w, fir_pha, w, pha_combined)

figure 4
p_ref = polyfit(w, pha_combined, 1);
lin_ref = w * p_ref(1);
err = (lin_ref - pha_combined).^2;
plot(w, err)


