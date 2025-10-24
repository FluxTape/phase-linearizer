% based on https://github.com/mschof/ParticleSwarmOptimization/blob/master/PSO1.m
function [ret, ret_start, ret_best_costs, ret_wi] = pso(cf, nr_variables, var_min, var_max, max_iterations)

    %% Problem Definition
    % nr_variables                          % Number of variables unknown (part of the decision)
    variable_size = [1 nr_variables];       % Vector representation
    % var_min                               % Lower bound of decision space
    % var_max                               % Upper bound of decision space
  
    %% Parameter Adjustment
    swarm_size = 500;                       % Swarm size (number of particles)
    w = 1.0;                                % initally no damping: w=1
    w_damp = 0.998;                         % damping of inertia coefficient, lower = faster damping
    c1 = 1.43;                              % Cognitive acceleration coefficient (c1 + c2 = 4)
    c2 = 1.43;                              % Social acceleration coefficient (c1 + c2 = 4)
    %w_fun_start = 0.95
    %w_fun_end = 0.45
    %w_fun = @(iteration) w_fun_start - (w_fun_start - w_fun_end) * ((iteration-1)/(max_iterations-1))^2 
    %w_fun_start = 0.95
    %w_fun_end = 0.55
    %w_fun = @(iteration) w_fun_start - (w_fun_start - w_fun_end) * ((iteration-1)/(max_iterations-1))

    sort_by_theta = false;
  
    %% Init
    template_particle.position = [];
    template_particle.velocity = [];
    template_particle.cost = 0;
    template_particle.best.position = [];   % Local best
    template_particle.best.cost = inf;       % Local best
  
    % Copy and put the particle into a matrix
    particles = repmat(template_particle, swarm_size, 1);
  
    % Initialize global best (current worst value, inf for minimization, -inf for maximization)
    global_best.cost = inf;
  
    for i=1:swarm_size
  
      % Initialize all particles with random position inside the search space
      position = [];
      for k = 1:nr_variables
        d = var_max(k) - var_min(k);
        position(k) = var_min(k) + d*rand(1);
      endfor
      particles(i).position = position;
  
      % Initiliaze velocity to the 0 vector
      particles(i).velocity = zeros(variable_size);

      % Initiliaze with random velocity
      %velocity = [];
      %for k = 1:nr_variables
      %  d = var_max(k) - var_min(k);
      %  % at most, particles should move no faster than half the search space per iteration
      %  % velocities can be positive and negative
      %  velocity(k) = d*(rand(1)-0.5); 
      %endfor
      %particles(i).velocity = velocity;
      % TODO: velocity limit??? -------------------------------------------------------------------------

      % Experiment: sort by theta
      if (sort_by_theta)
        [ps, vs] = sort_position_and_velocity(particles(i).position, particles(i).velocity); 
        particles(i).position = ps;
        particles(i).velocity = vs;
      endif
  
      % Evaluate the current cost
      particles(i).cost = cf(particles(i).position);
  
      % Update the local best to the current location
      particles(i).best.position = particles(i).position;
      particles(i).best.cost = particles(i).cost;
  
      % Update global best
      if (particles(i).best.cost < global_best.cost)
        global_best.position = particles(i).best.position;
        global_best.cost = particles(i).best.cost;
      endif
  
    endfor
  
    % Best cost at each iteration
    best_costs = [];
    wi = [];
  
    %% PSO Loop
  
    for iteration=1:max_iterations

      % experiment: use w_fun to set w
      %w = w_fun(iteration)
  
      iteration_best_cost = inf;
      for i=1:swarm_size
  
        % Initialize two random vectors
        r0 = rand(variable_size);
        r1 = rand(variable_size);
        r2 = rand(variable_size);
  
        % Update velocity %* (r0 * 0.5 + 0.75)
        particles(i).velocity = (w .* particles(i).velocity) ...
          + (c1 * r1 .* (particles(i).best.position - particles(i).position)) ...
          + (c2 * r2 .* (global_best.position - particles(i).position));

        % TODO limit velocity (scale each dimension by the same factor to preserve direction)
  
        % Update position
        particles(i).position = particles(i).position + particles(i).velocity;

        % Clamp position to limits and reflect and damp velocity
        for k = 1:nr_variables
          if (particles(i).position(k) < var_min(k))
            particles(i).position(k) = var_min(k);
            particles(i).velocity(k) = -particles(i).velocity(k) * 0.5; 
          elseif (particles(i).position(k) > var_max(k))
            particles(i).position(k) = var_max(k);
            particles(i).velocity(k) = -particles(i).velocity(k) * 0.5; 
          endif
        endfor

        % Experiment: sort by theta
        if (sort_by_theta)
          [ps, vs] = sort_position_and_velocity(particles(i).position, particles(i).velocity); 
          particles(i).position = ps;
          particles(i).velocity = vs;
        endif
  
        % Update cost
        particles(i).cost = cf(particles(i).position);

        % Update best cost of iteration
        particles(i).cost = cf(particles(i).position);
        if (particles(i).cost < iteration_best_cost)
          iteration_best_cost = particles(i).cost;
        endif
  
        % Update local best (and maybe global best) if current cost is better
        if (particles(i).cost < particles(i).best.cost)
          particles(i).best.position = particles(i).position;
          particles(i).best.cost = particles(i).cost;
  
          % Update global best
          if (particles(i).best.cost < global_best.cost)
            global_best.position = particles(i).best.position;
            global_best.cost = particles(i).best.cost;
          endif
  
        endif
  
      endfor
  
      % Get best value
      %best_costs(iteration) = global_best.cost;
      best_costs(iteration) = iteration_best_cost;
      wi(iteration) = w;
  
      % Display information for this iteration
      % disp(["Iteration " num2str(iteration) ": best cost = " num2str(best_costs(iteration))]);
  
      % Damp w
      w = w * w_damp;

      if (iteration == 1)
        ret_start = global_best.position;
      endif
  
    endfor
  
    %% Print results
    ["Best cost: " num2str(global_best.cost)]

    ret = global_best.position;
    ret_best_costs = best_costs;
    ret_wi = wi;
  
  endfunction

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