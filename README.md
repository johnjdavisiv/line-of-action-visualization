# Demo line of action visualization

>John J. Davis  
>john@johnjdavis.io

The OpenSim [Line of Action plugin by van Arkel et al. 2013](https://simtk.org/projects/force_direction/) is super useful. I have come up with two clever ways to visualize its results. Because of my workflow, both methods assume you've already calculated muscle forces via static optimization, CMC, MoCo, or some other method (this demo uses static optimization).  

This demo uses the model and data distributed with the [Rajagopal 2015](https://simtk.org/projects/full_body/) model but should be adaptible easily to other models and datasets. 

## Method 1: Trick OpenSim into thinking the muscle forces are ground reaction forces  

<img src="https://raw.githubusercontent.com/johnjdavisiv/line-of-action-visualization/main/demo_pseudo_grfs.png" height="600">  

*As illustrated in* `demo_plot_forces_as_fake_grfs.m`  

This method requires running the muscle line of action plugin with the `local_ref_system` set to `false`, so the muscle directions are exported as vectors in the global reference frame, and the muscle origins are exported as points in the global reference frame.  

By some clever reformatting, we can combine the muscle forces, lines of action, and origin points and format them as if they are point forces applied in the global reference frame. Then you can preview it in the OpenSim GUI using the "Preview Experimental Data..." feature!  

OpenSim can handle these fake GRFs just fine, running smoothly even if you do lines of action for all muscles in a model.  

However...you can *only* run the global reference frame analysis in OpenSim 4.1. It will crash in later versions (I am not sure why). Old versions of OpenSim are on SimTK. The plugin creator knows about this issue, and the local reference frame version works fine in later versions of OpenSim. Once you've run the plugin in 4.1, you can view the pseudo-GRFs in later versions of OpenSim just fine.   

This method is fast and simple, so if you don't mind keeping OpenSim 4.1 installed it's great for quick checks of your results (it's perfectly fine to keep multiple versions of OpenSim installed at the same time, by the way).

Do note that this demo plots all forces as coming out of the insertion point of the muscle, by selecting only the "X/Y/Z1" component from the points and vectors file. This has the consequence of making the gastroc forces show up as coming out of the calcaneus (which they do, of course, since that's the insertion point of that muscle) but if you were actually analyzing the muscle forces on the femur, you'd want these particular muscle forces to come out of the origin point instead. This is simple and easy to do in the local coordinate system (as below).  

**Demo:** Run `demo_plot_forces_as_fake_grfs.m` then:  

1) Start OpenSim
2) Open the `subject_run_adjusted.osim` model
3) Load the inverse kinematics data (File > Load Motion... > `ik_output_run.mot`)
4) Load the faked GRFs as experimental data (File > Preview Experimental Data... > `muscle_forces_as_pseudo_grfs.mot`)
5) Hold control and click on both the IK "Coordinates" Motions and the Experimental Data to select both of them at the same time
6) Right click and select "Sync Motions"
7) Play the motion file! 

## Method 2: Import bone geometry into MATLAB and overlay forces as 3D lines  

<img src="https://raw.githubusercontent.com/johnjdavisiv/line-of-action-visualization/main/demo_line_of_action_plot.png" height="600">

*As illustrated in* `demo_plot_forces_on_femur_in_matlab.m`

This method exploits the fact that model geometry meshes are expressed in the same coordinate system (after a Z-Y axis flip) as the muscle lines of action, if you export with `local_ref_system` set to `true`. 

This method has a downside too, which is that you have to manually convert the .vtp mesh file to an .stl file to read it into MATLAB. I just used a free website like [this one](https://www.weiy.city/tools__trashed/3d-files-converter/), but you can probably do it with 3D modeling software (I just don't know how).  

This repo has the femur mesh already converted to an .stl file. Do note that MATLAB must be version R2018b or later to use the `stlread()` function.

This method is slower, trickier, and more involved from a data processing perspective than option #1 above but if you take your time you can get some really nice looking results. 

### An aside: running the line of action plugin through the MATLAB API

Running the plugin through the MATLAB API requires a few workarounds but is easily possible. [See this GitHub Gist for a demo.](https://gist.github.com/johnjdavisiv/26b17b41afd7555e0c18f8cd84f38123) It leverages the 'PropertyHelper' class to fool MATLAB into thinking the line of action plugin is just a regular muscle analysis. This might work in Python too but I haven't tried it.  


## Important notes and quirks  

In both methods you might notice that some muscle forces seem to float in midair. This is by design, and is a consequence of the `effective_attachments` flag in the muscle line of action config. When muscles wrap around wrapping surfaces, their effective attachment point can be different from their anatomical attachment point. See [this video and especially timestamp 15:40](https://www.youtube.com/watch?v=0e6vQV_ioCI&t=15m42s
) for details. You should consider your use-case and decide whether anatomical or effective attachment points are what you want. 

The MATLAB code here uses my utility function `read_mot()` (despite the name, also works on .sto files). It is kind of hacky but gets the job done. The officially-sactioned way to read and write mot files would be to use the API and covert to/from MATLAB structs.  

The files here are just a demo. There are a few best-practices I didn't adhere to when putting it together: I just grabbed the CMC actuators for running static optimization, and the IK is getting filtered for static optimization but not for the muscle line of action analysis. You would want to be consistent and thoughtful with these things in a real research project.  

The muscle line of action exports are missing the first and last datapoints, probably because of a change in how filtering was implemented in OpenSim 3.3 vs 4.0. The MATLAB code I use manually fixes this by just extrapolating out the data by one sample in either direction. 

The demo is inefficient in that it runs SO on the whole file even though we only plot one gait cycle. This is also because of some oddities involving filtering and edge effects. Again, you'd want to change this "in production."