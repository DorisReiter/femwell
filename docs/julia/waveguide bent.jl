# ---
# jupyter:
#   jupytext:
#     custom_cell_magics: kql
#     formats: jl:percent,ipynb
#     text_representation:
#       extension: .jl
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.11.2
#   kernelspec:
#     display_name: base
#     language: julia
#     name: julia-1.9
# ---

# %% [markdown]
# # Mode solving for bent waveguides

# %% [markdown]
# ```{caution}
# **This example is under construction**
# As Julia-Dicts are not ordered, the mesh might become incorrect when adjusted (for now, better do the meshing in python)
# ```

# %% tags=["hide-output", "thebe-init"]
using PyCall
np = pyimport("numpy")
shapely = pyimport("shapely")
shapely.affinity = pyimport("shapely.affinity")
clip_by_rect = pyimport("shapely.ops").clip_by_rect
OrderedDict = pyimport("collections").OrderedDict
mesh_from_OrderedDict = pyimport("femwell.mesh").mesh_from_OrderedDict

radius = 1
wg_width = 0.5
wg_thickness = 0.22
sim_left = 0.5
sim_right = 3
sim_top = 1
sim_bottom = 3
pml_thickness = 3
core = shapely.geometry.box(radius - wg_width / 2, 0, radius + wg_width / 2, wg_thickness)

env = shapely.geometry.box(
    radius - wg_width / 2 - sim_left,
    -sim_bottom - pml_thickness,
    radius + wg_width / 2 + sim_right + pml_thickness,
    wg_thickness + sim_top,
)

polygons = OrderedDict(
    core = core,
    box = clip_by_rect(env, -np.inf, -np.inf, np.inf, 0),
    clad = clip_by_rect(env, -np.inf, 0, np.inf, np.inf),
)

resolutions = Dict(
    "core" => Dict("resolution" => 0.015, "distance" => 0.5),
    "slab" => Dict("resolution" => 0.015, "distance" => 0.5),
)

mesh = mesh_from_OrderedDict(
    polygons,
    resolutions,
    default_resolution_max = 0.2,
    filename = "mesh.msh",
)

# %% tags=["remove-stderr", "hide-output", "thebe-init"]
using Gridap
using Gridap.Geometry
using Gridap.Visualization
using Gridap.ReferenceFEs
using GridapGmsh
using GridapMakie, CairoMakie

using Femwell.Maxwell.Waveguide

CairoMakie.inline!(true)

# %% tags=["remove-stderr"]
model = GmshDiscreteModel("mesh.msh")
Ω = Triangulation(model)
#fig = plot(Ω)
#fig.axis.aspect=DataAspect()
#wireframe!(Ω, color=:black, linewidth=1)
#display(fig)

labels = get_face_labeling(model)

epsilons = ["core" => 3.48^2, "box" => 1.46^2, "clad" => 1.0^2]
ε(tag) = Dict(get_tag_from_name(labels, u) => v for (u, v) in epsilons)[tag]


#dΩ = Measure(Ω, 1)
τ = CellField(get_face_tag(labels, num_cell_dims(model)), Ω)
pml_x = x -> 0
pml_y = x -> 0
pml_x = x -> 0.1 * max(0, x[1] - (radius + wg_width / 2 + sim_right))^2
pml_y = x -> 0.1 * max(0, -x[2] - sim_bottom)^2

modes = calculate_modes(model, ε ∘ τ, λ = 1.55, num = 2, order = 1)
modes = calculate_modes(
    model,
    ε ∘ τ,
    λ = 1.55,
    num = 2,
    order = 1,
    radius = radius,
    pml = [pml_x, pml_y],
    k0_guess = modes[1].k,
)
println(n_eff(modes[1]))
println(log10(abs(imag(n_eff(modes[1])))))
# write_mode_to_vtk("mode", modes[2])

plot_mode(modes[1], absolute = true)
#plot_mode(modes[2])
modes

# %% [markdown]
# For comparison, we the effective refractive index of a straight waveguide:

# %% tags=["remove-stderr"]

#modes_p = calculate_modes(model, ε ∘ τ, λ = 1.55, num = 2, order = 1)
#println(n_eff(modes_p[1]))
#plot_mode(modes_p[1], absolute = true)

# %%