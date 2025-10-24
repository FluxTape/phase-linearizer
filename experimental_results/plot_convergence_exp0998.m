clear all
close all
warning('off','Octave:shadowed-function')
pkg('load', 'statistics');


filename = "pso_tuning_exp0998.csv"
experiment = "PSO tuning v1: exp 0.998"
data = csvread(filename);
s_data = size(data)

e_min = data(:, 1)
data = data(:, 2:end);
algo  = data(:, 1)
data = data(:, 2:end);
num_param = data(:, 1)
data = data(:, 2:end);
opt = data(:, 1:num_param)
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

med = []
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

max_emin = max(e_min)
avg_emin = mean(e_min)
median_emin = median(e_min)
min_emin = min(e_min)

%plot(med, 'color', 'k', 'lineWidth', 2)
%hold on
iter = 1:num_errs(1);
wi = arrayfun(@(iteration) 0.998^(iteration-1), iter);
%plot(iter/10, wi, 'color', 'g');
[ax, h1, h2] = plotyy(1:numel(med), med, iter/10, wi);
set (h2, "color", "g")
set (h1, "color", "k")
set (ax(1), "ycolor", "k")
set (ax(2), "ycolor", "k")
legend('median err               ', 'w')
legend ("autoupdate", "off");

% Hide x-axis ticks and labels from both plotyy axes
set(ax, "xtick", []);
set(ax, "xticklabel", []);

hold on
boxplot (pruned_data, 'Labels', labels);

ylabel(ax(1), "Error")
ylim(ax(1), [0, 3])
ylabel(ax(2), "w")
ylim(ax(2), [0, 1])
xlabel("Iterations")
title(sprintf("Experiment=%s, Algorithm=%s, runs=%d, median min err=%d", experiment, algoname, size(pruned_data)(1), median_emin))


hold off

