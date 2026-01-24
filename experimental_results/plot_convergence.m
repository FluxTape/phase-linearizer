clear all
close all
warning('off','Octave:shadowed-function')
pkg('load', 'statistics');

data_str    = fread( stdin, 'char' );
data_str    = char( data_str.' );
str_tokens  = strsplit( data_str, {";"} );
filename = str_tokens{1}
experiment = str_tokens{2}

plot_convergence_generic(filename, experiment);