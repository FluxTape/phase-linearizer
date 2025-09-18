% 0 <= w <= 1
function [opt, e_min, best_errs] = octave_opt_ap(w_start, w_end, w_points_internal, order, algo, iterations, gradient_ref, err_weights, show_plot)
    % w_points = numel(gradient_ref)
    w = linspace(w_start, w_end, w_points_internal);
    gradient_ref = refit_points(gradient_ref, w_start, w_end, w_points_internal);
    length_grd_ref = numel(gradient_ref)
    err_weights = refit_points(err_weights, w_start, w_end, w_points_internal);
    
    err_func = @(v) err_sum(err(gradient_ref + gr_ap_m_even(v, w.*pi), err_weights));
    title_txt = "";
    switch (algo)
    case 0
        title_txt = sprintf("order=%d  algo=grid", order);
        divs_search_grid = 15; % determined by experimentation, larger values too slow
        % checks error at all permutations of positions
        best_positions = search_full_grid(err_func, order, divs_search_grid);
        var_vals_start = positions2var_vals(best_positions{end});
        opt = var_vals_start;
        found_solution = false;
        np = numel(best_positions);
        % check best_positions from best to worst until a stable solution is found
        while (np>1 && !found_solution)
            % get next var_vals
            var_vals_start = positions2var_vals(best_positions{np});
            [var_vals_opt,ressquared,eflag,outputu] = fminunc(err_func,var_vals_start);
            if (is_stable(var_vals_opt)) % check if optimization produced stable filter chain
                opt = var_vals_opt;
                found_solution = true;
            else
                disp("result unstable, trying different start values")
                np = np-1;
            endif
        endwhile
        best_errs = [];
    case 1
        title_txt = sprintf("order=%d  algo=random-unc  iterations=%d", order, iterations);
        [opt, var_vals_start, best_errs] = search_full_grid_random(err_func, order, iterations)
    case 2
        title_txt = sprintf("order=%d  algo=random-con  iterations=%d", order, iterations);
        [opt, var_vals_start, best_errs] = search_full_grid_random_bounded(err_func, order, iterations)
    otherwise
        title_txt = sprintf("order=%d  algo=pso  iterations=%d", order, iterations);
        var_min = zeros(1, order*2);
        r_max = 1 - 1e-6;10
        var_max = [];
        for i_ = 1:order
            var_max(end+1) = r_max;
            var_max(end+1) = pi;
        endfor
        [opt, opt_start, best_errs] = pso(err_func, order*2, var_min, var_max, iterations);
        var_vals_start = opt_start;
    endswitch
    
    e_start = err_func(var_vals_start)
    e_fmin = err_func(opt)
    e_min = e_fmin;

    if (show_plot)
        if (numel(best_errs) > 0)
            %% Plot results
            figure;
            plot(best_errs, "LineWidth", 2);
            xlabel("iteration");
            ylabel("best err");
        endif

        g_opt1 = gr_ap_m_even(opt, w.*pi);
        both1 = gradient_ref + g_opt1;
        target1 = zeros(length(w),1) + sum(both1 .* err_weights) / sum(err_weights);
        target_grd = target1(1)
        h = figure;
        plot(w, gradient_ref,
            w, g_opt1,
            w, both1,
            w, err(both1, err_weights),
            w, target1,
            w, err_weights)
        legend('grd ref', 'opt', 'ref+opt', 'err', 'target', 'err weights')
        title(sprintf("%s, mean err=%d", title_txt, e_min))
        grid on
        waitfor(h)
    endif

endfunction

function p_refit = refit_points(v, w_start, w_end, num_points_target)
    n = numel(v);
    rp = [];
    for x = 1:num_points_target
        xq = (x-1)*(n-1)/(num_points_target-1) + 1;
        rp(x) = interp1(v, xq);
    endfor
    p_refit = rp;
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
    % square weights here to account for square in err
    e = ((grd - avg).*err_weights).^2;
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

% returns the grid frequencies used for searching
function th = gen_thetas(num_grid_points)
    p = linspace(0, pi, num_grid_points+2);
    th = p(2:end-1);
endfunction

function stable = is_stable(var_vals)
    stable = true;
    n = numel(var_vals);
    for i = 1:n
        v = var_vals(i);
        if (v < 0)
            disp("val below 0")
            stable = false;
        endif
        if (mod(i,2)) % r
            if (v >= 1)
                r = v
                disp("r too big")
                stable = false;
            endif
        else % theta
            if (v > pi)
                theta = v
                disp("theta too big")
                stable = false;
            endif
        endif
    endfor
endfunction

%converts positions array into (r, theta) using default_r for r
function v = positions2var_vals(positions)
    order_half = sum(positions);
    num_pos = numel(positions);
    thetas = gen_thetas(num_pos);
    default_r = 1/sqrt(2); % 0.707106
    v = [];
    pos = 1;
    for p_idx = 1:num_pos
        theta = thetas(p_idx);
        for k = 0:positions(p_idx)-1
            v(pos) = default_r;
            if (p_idx < num_pos)
                v(pos+1) = theta*(1+0.01*k);
            else
                v(pos+1) = theta*(1-0.01*k);
            endif
            pos = pos+2;
        endfor
    endfor
endfunction

function v = thetas2var_vals(thetas)
    default_r = 1/sqrt(2);
    v = [];
    for theta = thetas
        v(end+1) = default_r;
        v(end+1) = theta;
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

function best_positions = search_full_grid(func, order_half, num_grid_points)
    thetas = gen_thetas(num_grid_points)
    done = false;
    positions = zeros(1, num_grid_points);
    positions(1) = order_half;
    pos_total = sum(positions);
    best_positions = cell();
    best_err = inf;
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
    %best_positions{end}
    %var_vals = positions2var_vals(best_positions{end});
endfunction

function [best_var_vals, var_vals_start, best_errs] = search_full_grid_random(func, order_half, num_variations)
    var_vals_start = zeros(1, order_half*2);
    r_max = 1 - 1e-3;
    best_var_vals = var_vals_start;
    best_err = inf;
    best_errs = []
    for i_ = 1:num_variations
        var_vals = [];
        for k_ = 1:order_half
            var_vals(end+1) = rand(1)*r_max; % r
            var_vals(end+1) = rand(1)*pi; % theta 
        endfor

        [var_vals_opt,ressquared,eflag,outputu] = fminunc(func,var_vals);
        if (is_stable(var_vals_opt))
            err = func(var_vals_opt);
            if (err < best_err)
                best_err = err
                best_var_vals = var_vals_opt
                var_vals_start = var_vals
            endif
        endif
        best_errs(end+1) = best_err;
    endfor
endfunction

function [best_var_vals, var_vals_start, best_errs] = search_full_grid_random_bounded(func, order_half, num_variations)
    best_var_vals = [];
    best_err = 9e9;
    order = order_half*2;
    r_max = 1 - 1e-6;
    lb = zeros(1, order);
    ub = [];
    for k_ = 1:order_half
        ub(end+1) = r_max; % r
        ub(end+1) = pi; % theta 
    endfor
    ub
    best_errs = []
    for i_ = 1:num_variations
        var_vals = [];
        for k_ = 1:order_half
            var_vals(end+1) = rand(1)*r_max; % r
            var_vals(end+1) = rand(1)*pi; % theta 
        endfor

        [var_vals_opt, objf, cvg, outp] = fmincon(func,var_vals',[],[],[],[],lb,ub);
        var_vals_opt = var_vals_opt';

        if (is_stable(var_vals_opt))
            err = func(var_vals_opt);
            if (err < best_err)
                best_err = err
                best_var_vals = var_vals_opt
                var_vals_start = var_vals
            endif
        endif
        best_errs(end+1) = best_err;
    endfor
endfunction