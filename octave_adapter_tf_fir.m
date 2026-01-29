clear all
close all
warning('off','Octave:shadowed-function')
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

data_str    = fread( stdin, 'char' );
data_str    = char( data_str.' );
str_tokens  = strsplit( data_str );
output_path = str_tokens{1}
tokens = cellfun( @str2double, str_tokens );
tokens = tokens(2:end);
if isnan(tokens(end))
    tokens = tokens(1:end-1);
endif
err_at = find(isnan(tokens));
if !isempty(err_at)
    disp("failed to parse input at index:");
    err_at
    return
endif
w_start              = tokens(1)
w_end                = tokens(2)
w_points_internal    = round(tokens(3))
order                = round(tokens(4))
show_graph           = (tokens(5) > 0)
algo                 = round(tokens(6))
iterations           = round(tokens(7))
input_is_file        = (tokens(8) > 0)
includes_err_weights = round(tokens(9))
length_weights       = round(tokens(10))
weights_start = 11
weights_end   = weights_start + length_weights - 1
data_start    = weights_end + 1

disp("warning: this optimziation mode is experimental and does not support all options")

if (w_start != 0)
    disp("warning: start freq will be set to 0")
endif
if (w_end != 1)
    disp("warning: end freq will be set to 1")
endif
if (algo != 0)
    disp("warning: algo setting will be ignored in this mode")
endif
if (iterations != 0)
    disp("warning: iteration setting will be ignored in this mode")
endif
if (input_is_file != 0)
    disp("error: file input not implemented")
    return
endif
if (includes_err_weights != 0)
    disp("warning: err weights will be ignored in this mode")
endif

weights_p = tokens(weights_start:weights_end);
data_p    = tokens(data_start:end);

tf_order = idivide(numel(data_p), int32(2), "fix")
tf_num = data_p(1:tf_order)
tf_den = data_p(tf_order+1:end)
if numel(tf_num) != numel(tf_den)
    disp("transfer function numerator and denominator have mismatched length");
    return
endif

w = linspace(w_start, w_end, w_points_internal);
inputtf = tf(tf_num, tf_den, pi)
[tf_num, tf_den] = tfdata(inputtf, 'v'); % override tf_num, tf_den
%fq = inputtf(w);

[opt, e_min] = octave_opt_fir(tf_num, tf_den, order, w_points_internal, show_graph);
disp("final opt:");
disp([opt e_min]');