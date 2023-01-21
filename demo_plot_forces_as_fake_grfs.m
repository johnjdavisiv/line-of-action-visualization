%Show demo of fooling opensim into thinking muscle forces are GRFs
%(for visualization purposes only!)
%John J Davis
%john@johnjdavis.io


%Divide force by this much (for scaling how big arrows are). In OSim ~2 body weigths is about the height of the body
scale_factor = 2; %2 is about right for running


% Read result files
so_results_file = 'subject_scale_run_StaticOptimization_force.sto'; %Static optimization muscle forces
mfd_run_points_file = 'line_of_action_results/muscle_line_of_action_global_MuscleForceDirection_attachments.sto'; %Muscle force direction points
mfd_run_vectors_file = 'line_of_action_results/muscle_line_of_action_global_MuscleForceDirection_vectors.sto'; %Muscle force direction vectors
% *** note we are loading the GLOBAL reference frame line of action results here! ***
% ^^ also remember the plugin must be run in OpenSim 4.1, not 4.2+, for the global option to work


[so_data, so_header] = read_mot(so_results_file); %read_mot() works on .sto too
so_cols = strip(strsplit(so_header{end}, '\t'));

[point_data, point_header] = read_mot(mfd_run_points_file);
point_cols = strip(strsplit(point_header{end}, '\t'));

[vector_data, vector_header] = read_mot(mfd_run_vectors_file);
vector_cols = strip(strsplit(vector_header{end}, '\t'));

time_col = so_data(:,1); %Needed for first/last timestep bug

%% extrapolate to work around first/last timestep bug

%Extrapolate first row
point_row_one = interp1(point_data(:,1), point_data(:,2:end), time_col(1), 'pchip', 'extrap');
vector_row_one = interp1(vector_data(:,1), vector_data(:,2:end), time_col(1), 'pchip', 'extrap');

point_row_end = interp1(point_data(:,1), point_data(:,2:end), time_col(end), 'pchip', 'extrap');
vector_row_end = interp1(vector_data(:,1), vector_data(:,2:end), time_col(end), 'pchip', 'extrap');

%Concat to get extrapolated values
point_full = [time_col, [point_row_one; point_data(:,2:end); point_row_end]];
vector_full = [time_col, [vector_row_one; vector_data(:,2:end); vector_row_end]];

%Get all muscles in the muscle force direction file
all_muscles = unique(regexprep(vector_cols(2:end), '_[X|Y|Z][1|2].*', ''))';



n_muscles = length(all_muscles);


%Six components for each pseudo-force (px, py, pz, vx, vy, vz)
osim_mot = zeros(size(point_full,1), n_muscles*6);

mot_cols = cell(1,n_muscles+1);
mot_cols(:) = {''};
mot_cols{1} = 'time';


block_ix = 1;
%Will not be in same order bc of alphabetizing of unique()!
for a=1:n_muscles
    %make block of columns in mot format (slightly hack solution)
    col_block = [sprintf('ground_force_%i_vx\t', a),sprintf('ground_force_%i_vy\t', a), sprintf('ground_force_%i_vz\t', a), ...
        sprintf('ground_force_%i_px\t', a),sprintf('ground_force_%i_py\t', a), sprintf('ground_force_%i_pz', a)];
    
    mot_cols{a+1} = col_block;
    %a+1 because index 1 is time!

    
    this_muscle = all_muscles{a};
    
    att_ix = contains(point_cols, [this_muscle, '_X2']);
    att_iy = contains(point_cols, [this_muscle, '_Y2']);
    att_iz = contains(point_cols, [this_muscle, '_Z2']);
    
    vec_ix = contains(vector_cols, [this_muscle, '_X2']);
    vec_iy = contains(vector_cols, [this_muscle, '_Y2']);
    vec_iz = contains(vector_cols, [this_muscle, '_Z2']);
    
    muscle_px = point_full(:,att_ix);
    muscle_py = point_full(:,att_iy);
    muscle_pz = point_full(:,att_iz);
    
    %Need SO force to multiply
    statopt_ix = contains(so_cols, this_muscle);
    so_force = so_data(:,statopt_ix);
    
    muscle_vx = vector_full(:,vec_ix).*so_force/scale_factor;
    muscle_vy = vector_full(:,vec_iy).*so_force/scale_factor;
    muscle_vz = vector_full(:,vec_iz).*so_force/scale_factor;
    
    osim_mot(:,block_ix:block_ix+5) = [muscle_vx, muscle_vy, muscle_vz, muscle_px, muscle_py, muscle_pz];
    
    block_ix = block_ix + 6;

end

%Save as a .mot file that OpenSim will think is a GRF file
save_name = 'muscle_forces_as_pseudo_grfs.mot';

%Add time col back in!
osim_mot_t = [time_col, osim_mot];

n_rows = size(osim_mot_t,1);
n_columns = size(osim_mot_t,2);
full_cols = [strip(sprintf('%s\t', mot_cols{:})), '\n'];


%Write header per .mot file specs
fid = fopen(save_name, 'w'); %w for (over)write
fprintf(fid, 'nRows=%i\n', n_rows);
fprintf(fid, 'nColumns=%i\n', n_columns);
fprintf(fid, 'DataType=double\n');
fprintf(fid, 'version=3\n');
fprintf(fid, 'OpenSimVersion=4.2-2021-03-12-fcedec9\n');
fprintf(fid, 'endheader\n');
fprintf(fid, full_cols);

%Write the data, line by line. Lil slow but reliable and not buggy
for a=1:size(osim_mot, 1)
    line_string = strip(sprintf('%.12f\t', osim_mot_t(a,:)));
    fprintf(fid, line_string);
    fprintf(fid, '\n');
end

fclose(fid);
disp('Wrote a pseudo-GRF file!');

%% To view this file:

% 1) Start OpenSim
% 2) Open the subject_run_adjusted.osim model
% 3) Load the inverse kinematics data (File > Load Motion... > ik_output_run.mot)
% 4) Load the faked GRFs as experimental data (File > Preview Experimental Data... > muscle_forces_as_pseudo_grfs.mot)
% 5) Hold control and click on both the IK "Coordinates" Motions and the Experimental Data to select
% both of them at the same time
% 6) Right click and select "Sync Motions"
% 7) Play the motion file! 

