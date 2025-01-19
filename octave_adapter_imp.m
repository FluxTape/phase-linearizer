clear all
close all
warning('off','Octave:shadowed-function')
pkg('load', 'optim');
pkg('load', 'control');
pkg('load', 'signal');

data_str   = fread( stdin, 'char' );
data_str   = char( data_str.' );
str_tokens = strsplit( data_str );
tokens     = cellfun( @str2double, str_tokens );
if isnan(tokens(end))
    tokens = tokens(1:end-1);
endif

w_start              = round(tokens(1))
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

err_at = find(isnan(tokens(1:weights_end)));
if !isempty(err_at)
    disp("failed to parse input at index:");
    err_at
    return
endif
weights_p = tokens(weights_start:weights_end);

data_p = [];
if (input_is_file)
    filename = [str_tokens(data_start:end)]{1}
    [dir_, name, ext] = fileparts(filename)
    if (ext == ".txt" || ext == ".csv")
        data_p = csvread(filename);
    else
        [y, fs] = audioread(filename);
        data_p = [fs y(:, 1)'];
    endif
else
    data_p = tokens(data_start:end);
endif

err_at = find(isnan(data_p));
if !isempty(err_at)
    disp("failed to parse data section at index:");
    err_at
    return
endif

fs = data_p(1)
h_imp = data_p(2:end);
s_h_imp = size(h_imp)


