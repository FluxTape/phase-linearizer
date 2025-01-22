clear all
close all
warning('off','Octave:shadowed-function')
pkg('load', 'statistics');

% only used to generate filename to open
w_start = 0.1
w_end = 0.9
w_points_internal = 150
order = 8
algo = 3
iterations = 1000
show_plot = 0
tf_num = [0.0015   -0.0020    0.0002   -0.0009    0.0028   -0.0009    0.0002   -0.0020    0.0015]
tf_den = [1.0000   -2.7355    5.9780   -7.8335    8.5654   -6.3463    3.9239   -1.4513    0.4299]

filename = mat2str([w_start w_end w_points_internal order algo iterations tf_num tf_den])
filepath ="../test-data/"
full_filename = sprintf("%s%s.csv", filepath, filename)
data = csvread(full_filename);
s_data = size(data)

% only plot every tenth iteration
pruned_data = [];
every_x = 20
for k = 1:size(data)(2)
    if (mod(k, every_x) == 0)
        pruned_data(:,end+1) = data(:,k);
    endif
endfor
s_pruned_data = size(pruned_data)

labels = {};
label_every_x = 5;
for k = 1:size(pruned_data)(2)
    if (mod(k, label_every_x) == 0)
        labels{end+1} = num2str(k*every_x);
    else
        labels{end+1} = "";
    endif
endfor

algoname = "";
switch (algo)
case 0
    algoname = "grid";
case 1
    algoname = "random-unc";
case 2
    algoname = "random-con";
case 3
    algoname = "pso";
endswitch

boxplot (pruned_data, 'Labels', labels);
ylabel("error")
xlabel("iterations")
title(sprintf("convergence behavior algorithm=%s", algoname))
ylim([0, 3])