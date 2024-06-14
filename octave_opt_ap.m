% 0 <= w <= 1
function opt = octave_opt_ap(w_start, w_end, w_points_internal, order, divs_search_grid, gradient_ref, err_weights)
    % w_points = numel(gradient_ref)
    w = linspace(w_start, w_end, w_points_internal);
    gradient_ref = refit_points(gradient_ref, w_start, w_end, w_points_internal);
    err_weights = refit_points(err_weights, w_start, w_end, w_points_internal);
    
    err_func = @(v) err_sum(err(gradient_ref + gr_ap_m_even(v, w.*pi), err_weights));
    var_vals_start = search_full_grid(err_func, order, divs_search_grid)
    e_start = err_func(var_vals_start)
    [xunc1,ressquared,eflag,outputu] = fminunc(err_func,var_vals_start);
    e_fmin = err_func(xunc1)
    opt = xunc1;

    % plot stuff
    %g_opt1 = gr_ap_m_even(opt, w.*pi);
    %both1 = gradient_ref + g_opt1;
    %target1 = zeros(length(w),1) + sum(both1 .* err_weights) / sum(err_weights);
    %figure
    %plot(w, gradient_ref,
    %    w, g_opt1,
    %    w, both1,
    %    w, err(both1, err_weights),
    %    w, target1);
    %legend('grd ref', 'opt', 'ref+opt', 'err', 'target')
    %grid on

endfunction

function p_refit = refit_points(p, w_start, w_end, num_points_target)
    x = linspace(w_start, w_end, numel(p));
    p_refit = [];
    for i = 1:num_points_target
        xi = w_start + (w_end - w_start) * (i-1) / (num_points_target-1);
        xi = min(xi, w_end);
        p_refit(i) = interp1(x, p, xi);
    endfor
endfunction

% group delay allpass
% 0 <= r <= 1
% 0 <= theta <= pi
function grd = gr_ap(r, theta, w)
    if (r < 0)
        r = 0;
    elseif (r > 1)
        r = 1;
    endif
    rsq = r*r;
    if (theta <= 0)
        grd = (1-rsq)./(1+rsq-2.*r.*cos(w));
    elseif (theta > 0 && theta < pi)
        grd = (1-rsq)./(1+rsq-2.*r.*cos(w-theta)) + (1-rsq)./(1+rsq-2.*r.*cos(w+theta));
    else
        grd = (1-rsq)./(1+rsq+2.*r.*cos(w));
    endif
endfunction

function grd = gr_ap_m_even(var_vals, w)
    n = numel(var_vals);
    grd = 0;
    for i = 1:2:n
        grd = grd + gr_ap(var_vals(i), var_vals(i+1), w);
    endfor
endfunction

function e = err(grd, err_weights)
    avg = sum(grd .* err_weights) / sum(err_weights);
    %avg = mean(grd);
    e = ((grd - avg).^2).*err_weights;
endfunction

function e = err_sum(err)
    n = numel(err);
    e = sum(err)/n;
endfunction

function p = range2point(r)
    p = (r(1) + r(2)) /2;
endfunction

function r = range2subranges(r, n)
    if (r(2)==1)
        p = log10(linspace(1, 10, n+1));
    else
        p = linspace(r(1), r(2), n+1);
    endif
    
    r = cell();
    for i = 1:n
        ri = cell();
        ri{1} = [p(i), p(i+1)];
        r{i} = ri;
    endfor
endfunction

function pi = ranges2points(ri) 
    p = [];
    n = numel(ri);
    for i = 1:n
        p(i) = range2point(ri{i});
    endfor
    pi = p;
endfunction

function th = gen_thetas(num_grid_points)
    p = linspace(0, pi, num_grid_points+2);
    th = p(2:end-1);
endfunction

function v = positions2var_vals(positions)
    order_half = sum(positions);
    num_pos = numel(positions);
    thetas = gen_thetas(num_pos);
    default_r = 1/sqrt(2);
    v = [];
    pos = 1;
    for p_idx = 1:num_pos
        theta = thetas(p_idx);
        for k = 0:positions(p_idx)-1
            v(pos) = default_r; % 0.707106
            if (p_idx < num_pos)
                v(pos+1) = theta*(1+0.01*k);
            else
                v(pos+1) = theta*(1-0.01*k);
            endif
            pos = pos+2;
        endfor
    endfor
endfunction

function pos = update_positions(pos)
    n = numel(pos);
    total = sum(pos);
    if (pos(n) < total)
        for k = flip(1:n-1)
            if (pos(k) != 0)
                pos(k) = pos(k)-1;
                at_n = pos(n);
                pos(n) = 0;
                pos(k+1) = pos(k+1)+1+at_n;
                break;
            endif
        endfor
    endif
endfunction

function var_vals = search_full_grid(func, order_half, num_grid_points)
    thetas = gen_thetas(num_grid_points)
    done = false;
    positions = zeros(1, num_grid_points);
    positions(1) = order_half;
    pos_total = sum(positions);
    best_positions = cell();
    best_err = 9e9;
    while (!done)
        err = func(positions2var_vals(positions));
        if (err <= best_err) 
            best_err = err;
            positions;
            best_positions{end+1} = positions;
        endif
        if (positions(end) == pos_total)
            done = true;
        endif
        positions = update_positions(positions);
    endwhile
    %best_positions
    best_positions{end}
    var_vals = positions2var_vals(best_positions{end});
endfunction