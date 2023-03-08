function tune_alpha(design_id, rank_sim)

    % get design
    design = yaml.loadFile(fullfile( ...
        'simulation', 'designs', sprintf('%s.yml', design_id) ...
        ));
    
    % get configs
    d = dir(fullfile('simulation', 'data', design_id));
    dfolders = d([d(:).isdir]);
    config_ids = dfolders(~ismember({dfolders(:).name},{'.','..'}));
    
    % estimate Ls
    disp("----- START ALPHA TUNING -----")
    start = tic;
    parfor i = 1:length(config_ids)
        config_id = config_ids(i).name;
        if config_id == 'config-46' | config_id == 'config-76'  % TODO: Remove
            fprintf("\t%s\n", config_id)
            tune_alpha_for_config(config_id, design_id, design.scratch_root, rank_sim);
        end
    end
    comp_time = toc(start);
    disp("----- END ALPHA TUNING -----")
    fprintf("Elapsed Time: %.03f s\n", comp_time)

end