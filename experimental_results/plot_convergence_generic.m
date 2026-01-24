function [max_emin, avg_emin, median_emin, min_emin] = plot_convergence_generic(filename, experiment)
    data = csvread(filename);
    s_data = size(data)

    e_min = data(:, 1);
    data = data(:, 2:end);
    algo  = data(:, 1);
    data = data(:, 2:end);
    num_param = data(:, 1)(1);
    data = data(:, 2:end);
    opt = data(:, 1:num_param);
    data = data(:, num_param+1:end);
    num_errs = data(:, 1);
    data = data(:, 2:end);
    best_errs = data(:, 1:end);
    n1 = size(best_errs)

    % only plot every tenth iteration
    pruned_data = [];
    every_x = 10
    for k = 1:size(data)(2)
        if (mod(k, every_x) == 0)
            pruned_data(:,end+1) = best_errs(:,k);
        endif
    endfor
    s_pruned_data = size(pruned_data)

    labels = {};
    label_every_x = 4;
    for k = 1:size(pruned_data)(2)
        if (mod(k, label_every_x) == 0)
            labels{end+1} = num2str(k*every_x);
        else
            labels{end+1} = "";
        endif
    endfor

    med = [];
    for k = 1:size(pruned_data)(2)
        med(end+1) = median(pruned_data(:,k));
    endfor

    algoname = "";
    switch (algo(1))
    case 0
        algoname = "grid";
    case 1
        algoname = "random-unc";
    case 2
        algoname = "random-con";
    case 3
        algoname = "pso";
    case 4
        algoname = "pso-k";
    endswitch
    algoname

    max_emin = max(e_min)
    avg_emin = mean(e_min)
    median_emin = median(e_min)
    min_emin = min(e_min)

    p = figure();
    plot(med, 'color', 'k', 'lineWidth', 1.5)
    legend('median err               ')
    legend ("autoupdate", "off");
    hold on
    boxplot (pruned_data, 'Labels', labels);
    ylabel("Error")
    xlabel("Iterations")
    title(sprintf("%s, runs=%d, median err=%d", experiment, size(pruned_data)(1), median_emin))
    %ylim([0.4, 1])
    hold off
    %pause(1)
    waitfor(p);
endfunction
