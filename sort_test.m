clear all
close all

function [s_position, s_velocity] = sort_position_and_velocity(position, velocity)
    n = numel(position);
    thetas = [];
    for i = 1:2:n
      thetas(end+1, 1) = position(i);
      thetas(end, 2)   = position(i+1);
      thetas(end, 3)   = velocity(i);
      thetas(end, 4)   = velocity(i+1);
    endfor
    [s, idx] = sortrows(thetas, 2);
    s_position = [];
    s_velocity = [];
    n1 = size(s)(1);
    for k = 1:n1
        s_position(end+1) = s(k, 1);
        s_position(end+1) = s(k, 2);
        s_velocity(end+1) = s(k, 3);
        s_velocity(end+1) = s(k, 4);
    endfor
endfunction

opt = [
   9.324561528623484e-01
   1.742045408892912e+00
   9.573440013241119e-01
   4.149326989478893e-01
   4.822211931513635e-17
   1.279755970567187e-01
   9.186945193250494e-01
   2.106444323994736e+00
   9.344215195281387e-01
   7.469642280243450e-01
   9.272259902086910e-01
   8.945331360229645e-01
   9.163857549731541e-01
   1.457099666814106e+00
   8.987173977001984e-01
   1.179829340717768e+00
   9.209777590312364e-01
   1.598082617793265e+00
   9.511212812996584e-01
   5.971264976789403e-01
]'
vel = [
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
    11
    12
    13
    14
    15
    16
    17
    18
    19
    20
]';

[opt, vel] = sort_position_and_velocity(opt, vel)
