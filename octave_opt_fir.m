function [opt, e_min] = octave_opt_fir(num, den, order, w_start, w_end, w_points_internal, err_weights, show_plot)
    %num = [0.0015   -0.0020    0.0002   -0.0009    0.0028   -0.0009    0.0002   -0.0020    0.0015]  
    %den = [1.0000   -2.7355    5.9780   -7.8335    8.5654   -6.3463    3.9239   -1.4513    0.4299]
    tf_pre = tf(num, den, 1) % TODO samplfe rate of pi instead? see octave_adapter_tf

    num_points = order
    internal_point_target = 240
    multiplier = ceil(internal_point_target/order)

    w = linspace(0, pi, num_points*multiplier);
    [mag, pha, w] = bode(tf_pre, w);

    if (show_plot)
        figure 1
        bode(tf_pre)
    endif

    % pha to radians
    pha = pha*pi/180;
    pha = rm_pi_jumps(pha);
    %{
    start_deg = pha(1)
    deg_mid = pha(end/2)
    end_deg = pha(end)

    [g_pre, w_pre]  = grpdelay(num, den, numel(w)*10);
    n = numel(g_pre)
    pha = [0];
    for k = 2:n
        pha(end+1) = pha(end) + g_pre(k)/n;
    endfor
    pha = -pha;
    end_deg = pha(end)
    deg_mid = pha(end/2)
    pha = downsample(pha, 10)
    %}


    %k = find_target_delay(w, pha)
    %wk = w*k;
    %lin_dif = wk - pha;
    if (show_plot)
        figure 2

        plot(w/pi, pha*180/pi)
        %plot(w, pha, w, wk, w, lin_dif)
        title("Unwrapped Phase Response of Input Transfer Function")
        xlabel("Normalized Frequency (×π rad/sample)")
        ylabel("Phase (deg)")
    endif

    pha = decimate(pha, multiplier, 70, "fir");
    %pha = decimate(pha, multiplier, 12, "iir");
    %pha = downsample(pha, multiplier);
    w = linspace(0, pi, num_points);
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

    if (show_plot)
        figure 3
        plot(w_sym/pi, real(fresp), w_sym/pi, imag(fresp))
        title("Real and Imaginary Components of Phase Response")
        legend("real", "imaginary")
        xlabel("Normalized Frequency (×π rad/sample)")
        ylabel("Value")
    endif

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
    real_order = numel(fir)

    if (show_plot)
        figure 4
        plot(w_sym/pi, fir)
        title("Impulse Response of Compensation FIR Filter")
        xlabel("Normalized Frequency (×π rad/sample)")
        ylabel("FIR Filter Value")
        y_scale = max(abs(fir))*1.2;
        ylim([-y_scale, +y_scale])
    endif

    size_fir = numel(fir)

    %[h, w_n] = freqz(fir, 1, numel(pha)*2);
    [h, w_n] = freqz(fir, 1, 1024);
    w_n = w_n';
    fir_pha = unwrap(angle(h))';
    fir_pha = fir_pha(1:end/2);
    fir_db = mag2db(abs(h));
    fir_db = fir_db(1:end/2);
    w_n = w_n(1:end/2);

    if (show_plot)
        figure 5
        %finer grid for plotting
        subplot (2, 1, 1)
        plot(w_n/pi, fir_db);
        title("Bode Diagram of FIR filter")
        ylabel("Magnitude [dB]")

        subplot (2, 1, 2)
        plot(w_n/pi, fir_pha*180/pi);
        xlabel("Normalized Frequency (×π rad/sample)")
        ylabel("Phase (deg)")
    endif

    numel(w)
    numel(w_n)
    numel(fir_pha)

    [mag_fine, pha_fine, w_] = bode(tf_pre, w_n);
    % pha to radians
    pha_fine = pha_fine*pi/180;
    pha_fine = rm_pi_jumps(pha_fine);
    pha_combined = fir_pha+pha_fine;

    if (show_plot)
        figure 6
        plot(w_n/pi, pha_fine*180/pi, w_n/pi, fir_pha*180/pi, w_n/pi, pha_combined*180/pi)
        title("Phase Response")
        xlabel("Normalized Frequency (×π rad/sample)")
        ylabel("Phase (deg)")
        legend("Input", "Compensation Filter", "Combined")
    endif

        
    [g_fir, w_g] = grpdelay(fir);
    [g_pre, w_g2]  = grpdelay(num, den);
    g_com = g_pre+g_fir;

    s_g1 = numel(w_g)
    s_g2 = numel(w_g2)

    grp_max = max(g_fir)

    avg_grd = mean(g_com)
    err = (g_com - avg_grd).^2;
    avg_err = mean(err)

    if (show_plot)
        figure 7
        plot(w_g/pi, g_pre, w_g/pi, g_fir, w_g/pi, g_com)
        title(sprintf("Group Delay of FIR Filter, order=%d", real_order))
        xlabel("Normalized Frequency (×π rad/sample)")
        ylabel("Group Delay (samples)")
        legend("Input", "Compensation Filter", "Combined")

        %{
        figure 8
        p_ref = polyfit(w_n, pha_combined, 1);
        lin_ref = w_n * p_ref(1);
        err = (lin_ref - pha_combined).^2;
        plot(w_n/pi, err)
        title("Phase Error with FIR Compensation Filter")
        xlabel("Normalized Frequency (×π rad/sample)")
        ylabel("Error")
        %ylim([0, 0.01])
        %}

        h = figure
        plot(w_n/pi, err)
        title(sprintf("Group Delay Error with FIR Compensation Filter, order=%d, avg err=%d", real_order, avg_err))
        xlabel("Normalized Frequency (×π rad/sample)")
        ylabel("Error^2")
        waitfor(h);
    endif

    e_min = avg_err;
    opt = real(fir);
endfunction

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

function p_refit = refit_points(v, w_start, w_end, num_points_target)
    % assume w range [0, 1]
    nv = numel(v)
    wx = linspace(0, 1, numel(v))
    start_idx = 1;
    for k = 1:numel(wx);
        if (wx(k) > w_start)
            start_idx = k;
            break
        endif
    endfor
    end_idx = 1;
    for k = numel(wx):-1:1;
        if (wx(k) < w_end)
            end_idx = k;
            break
        endif
    endfor
    start_idx
    end_idx
    v = v(start_idx:end_idx);

    n = numel(v)
    rp = [];
    for x = 1:num_points_target
        xq = (x-1)*(n-1)/(num_points_target-1) + 1;
        rp(x) = interp1(v, xq);
    endfor
    nrp = numel(rp)
    p_refit = rp;
endfunction