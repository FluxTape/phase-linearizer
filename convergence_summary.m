clear all
close all
warning('off','Octave:shadowed-function')
pkg('load', 'statistics');

% only used to generate filename to open
w_start = 0.0
w_end = 1.0
w_points_internal = 100
order = 5
iterations = 500
show_plot = 0
%tf_num = [0.0023    0.0058    0.0102    0.0118    0.0102    0.0058    0.0023] 
%tf_den = [1.0000   -3.2076    4.6897   -3.8538    1.8573   -0.4931    0.0561]

%tf_num = [0.0014    0.0009    0.0023   -0.0005    0.0005   -0.0023   -0.0009   -0.0014]
%tf_den = [1.0000    4.5142    9.0512   10.3576    7.2715    3.1213    0.7567    0.0798]

%tf_num = [0.0015   -0.0020    0.0002   -0.0009    0.0028   -0.0009    0.0002   -0.0020    0.0015]
%tf_den = [1.0000   -2.7355    5.9780   -7.8335    8.5654   -6.3463    3.9239   -1.4513    0.4299]

tf_num = [1.0349   -0.9159    0.7704   -0.4199    0.1551] 
tf_den = [1.0000   -0.9882    0.7910   -0.3476    0.1694]

algo=1
filename = mat2str([w_start w_end w_points_internal order algo iterations tf_num tf_den])
filepath ="../test-data/"
full_filename = sprintf("%s%s.csv", filepath, filename)
data1 = csvread(full_filename);%(:,1:500);
s_data1 = size(data1)

algo=2
filename = mat2str([w_start w_end w_points_internal order algo iterations tf_num tf_den])
filepath ="../test-data/"
full_filename = sprintf("%s%s.csv", filepath, filename)
data2 = csvread(full_filename);
s_data2 = size(data2)

algo=3
filename = mat2str([w_start w_end w_points_internal order algo iterations tf_num tf_den])
filepath ="../test-data/"
full_filename = sprintf("%s%s.csv", filepath, filename)
data3 = csvread(full_filename);
s_data3 = size(data3)

%grid_err = 0.01742391599277687 % lowpass
%grid_err = 0.04321376912327218 % highpass
%grid_err = 2.724432160024865 % bandpass
grid_err = 0.001266302272128142 % peak&dip
grid_err = grid_err * ones(size(data1(:, end)));

combined_data = [grid_err data1(:, end) data2(:, end) data3(:, end)]
labels = {"grid", "random-unc", "random-con", "pso"}

boxplot (combined_data, 'Labels', labels);
ylabel("Error")
title("Result after 500 iterations, Test Function=Peak&Dip")
%ylim([0, 0.1])