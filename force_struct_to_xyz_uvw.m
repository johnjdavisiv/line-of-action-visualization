function [x,y,z,u,v,w] = force_struct_to_xyz_uvw(force_struct, t_ix, unit_or_force, all_muscles)

%Return point and vector components of muscle forces for plotting. 
%John J Davis
% john@johnjdavis.io


% t_ix is an integer index into the timeseries data in force_struct
%  for example if t_ix = 10, that means "return the 10th sample"

%unit_or_force = 'unit' if you just want unit vectors, 'force' if you want to scale the unit vector
%by muscle force (recommended for plotting)

%all_muscles is a cell array of muscles you want. can use all_muscles = fieldnames(force_struct) if
%you want to get all muscles from the muscle line of action analysis.

n_muscles = length(all_muscles);

%Get insertion point and unit vector for each muscle and store in matrix for plotting
xyz = nan(n_muscles,3);
uvw = nan(n_muscles,3);
uvw_force = nan(n_muscles,3); %<-- scale unit vectors by muscle force

for m=1:n_muscles
    this_muscle = all_muscles{m};
    xyz(m,:) = force_struct.(this_muscle).points(t_ix,:);
    uvw(m,:) = force_struct.(this_muscle).uvec(t_ix,:);
    uvw_force(m,:) = force_struct.(this_muscle).force_vec(t_ix,:);   
end

%Scale unit vectors by force only if user asks
if matches(unit_or_force, 'force')
    uvw = uvw_force;
end

x = xyz(:,1);
y = xyz(:,2);
z = xyz(:,3);
u = uvw(:,1);
v = uvw(:,2);
w = uvw(:,3);