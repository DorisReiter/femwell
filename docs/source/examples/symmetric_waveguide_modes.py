import tempfile
from collections import OrderedDict

import shapely.geometry
import shapely.affinity
from skfem import Mesh, Basis, ElementTriP0

from femwell.mode_solver import compute_modes, plot_mode
from femwell.mesh import mesh_from_OrderedDict

core = shapely.geometry.box(-.5, -.17, .5, .17)

polygons = OrderedDict(
    core=core,
    clad=shapely.affinity.scale(core.buffer(5, resolution=8), yfact=.3)
)

resolutions = dict(
    core={"resolution": .03, "distance": .1}
)

with tempfile.TemporaryDirectory() as tmpdirname:
    mesh_from_OrderedDict(polygons, resolutions, filename=tmpdirname + '/mesh.msh', default_resolution_max=10)
    mesh = Mesh.load(tmpdirname + '/mesh.msh')

basis0 = Basis(mesh, ElementTriP0(), intorder=4)
epsilon = basis0.zeros(dtype=complex)
epsilon[basis0.get_dofs(elements='core')] = 1.9963 ** 2
epsilon[basis0.get_dofs(elements='clad')] = 1.444 ** 2

lams, basis, xs = compute_modes(basis0, epsilon, wavelength=1.55, mu_r=1, num_modes=1)
plot_mode(basis, xs[0].real, colorbar=True)
