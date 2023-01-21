function force_struct = get_bone_forces_and_points_for_plot(point_data, point_cols, ...
    vector_data, vector_cols, so_data, so_cols, all_muscles, bone_name)

assert(isequal(vector_cols, point_cols), 'Point and vector columns must be identical!');
%Make sure points and vectors are the same!

%% First order of business is to fix the missing first/last point bug

%Get time from good data (not processed)
t_col = so_data(:,1);

%Extrapolate first row. using pchip is a lil extra but speed is not an issue here
point_row_one = interp1(point_data(:,1), point_data(:,2:end), t_col(1), 'pchip', 'extrap');
vector_row_one = interp1(vector_data(:,1), vector_data(:,2:end), t_col(1), 'pchip', 'extrap');

point_row_end = interp1(point_data(:,1), point_data(:,2:end), t_col(end), 'pchip', 'extrap');
vector_row_end = interp1(vector_data(:,1), vector_data(:,2:end), t_col(end), 'pchip', 'extrap');

%Concat to get extrapolated values
point_data_full = [t_col, [point_row_one; point_data(:,2:end); point_row_end]];
vector_data_full = [t_col, [vector_row_one; vector_data(:,2:end); vector_row_end]];


%% Now back to calcs

%leg = 'r';
%forces, directions, and points for: recfem_r, vasint_r, vaslat_r, vasmed_r, patlig_r


%For results
force_struct = struct();

%Get an index to point us to the x-y-z cols of each muscle
for m=1:length(all_muscles)

    this_muscle = all_muscles{m}; %for clarity

    this_index = ~cellfun(@isempty, regexp(point_cols, ...
        [this_muscle, '_.*_on_', bone_name]));
    assert(nnz(this_index) == 3, 'Failed to find correct number of columns!');

    %Get forces while we're at it
    so_index = matches(so_cols, this_muscle);
    assert(nnz(so_index) == 1, 'Faield to find muscle in SO data!')
    this_muscle_force = so_data(:, so_index);

    %Muscle attachment points
    force_struct.(this_muscle).points = point_data_full(:,this_index);

    %Unit vector in force direction
    force_struct.(this_muscle).uvec = vector_data_full(:,this_index);

    %Actual muscle force
    force_struct.(this_muscle).force = this_muscle_force;

    %Muscles force vectors: multiply by unit vector (so norm is now the muscle force!)
    force_struct.(this_muscle).force_vec = vector_data_full(:,this_index).*repmat(this_muscle_force,1,3);
end


