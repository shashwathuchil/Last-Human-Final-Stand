# Blender 4.2 headless asset generation for "Last Human: Final Stand" clone.
# Run: blender -b -P tools/make_assets.py
# Exports stylized low-poly GLB models into assets/models/.

import bpy
import math
import os
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "models")
os.makedirs(OUT, exist_ok=True)

# ---------- helpers ----------

def mat(name, color, rough=0.8, metal=0.0, emit=None, emit_str=0.0):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emit:
        bsdf.inputs["Emission Color"].default_value = (*emit, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit_str
    return m


def apply_mat(obj, m):
    if obj.data and hasattr(obj.data, "materials"):
        obj.data.materials.clear()
        obj.data.materials.append(m)


def box(name, loc, scale, m, bevel=0.06):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = (scale[0] / 2, scale[1] / 2, scale[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    if bevel > 0:
        mod = o.modifiers.new("bev", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier="bev")
    apply_mat(o, m)
    return o


def sph(name, loc, radius, m, scale=(1, 1, 1), seg=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc, segments=seg, ring_count=rings)
    o = bpy.context.object
    o.name = name
    if scale != (1, 1, 1):
        o.scale = scale
        bpy.ops.object.transform_apply(scale=True)
    apply_mat(o, m)
    return o


def cyl(name, loc, radius, depth, m, rot=(0, 0, 0), vertices=12, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc,
                                        vertices=vertices, rotation=rot)
    o = bpy.context.object
    o.name = name
    if scale != (1, 1, 1):
        o.scale = scale
        bpy.ops.object.transform_apply(scale=True)
    apply_mat(o, m)
    return o


def join_all(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    bpy.context.object.name = name
    return bpy.context.object


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)


def export_glb(path):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB",
                              export_apply=True, export_yup=True)
    print("WROTE", path)


# ---------- shared materials ----------

SKIN = lambda: mat("skin", (0.85, 0.6, 0.45))
SKIN_D = lambda: mat("skin_dark", (0.55, 0.38, 0.3))
BLUE = lambda: mat("blue_suit", (0.15, 0.3, 0.75))
BLUE_D = lambda: mat("blue_dark", (0.08, 0.18, 0.45))
GOLD = lambda: mat("gold", (0.95, 0.72, 0.15), rough=0.35, metal=0.85)
GUN = lambda: mat("gunmetal", (0.15, 0.16, 0.19), rough=0.45, metal=0.7)
WHITE = lambda: mat("vest_white", (0.92, 0.92, 0.9))
ORANGE = lambda: mat("shorts_orange", (0.85, 0.28, 0.12))
BROWN = lambda: mat("boots_brown", (0.35, 0.22, 0.12))
ZOMBIE = lambda: mat("zombie_skin", (0.45, 0.55, 0.4))
ZOMBIE_C = lambda: mat("zombie_cloth", (0.3, 0.28, 0.3))
APRON = lambda: mat("apron", (0.45, 0.32, 0.2))
GREY = lambda: mat("grey", (0.5, 0.52, 0.55))
DARK = lambda: mat("dark", (0.12, 0.13, 0.16))
ROAD = lambda: mat("asphalt", (0.32, 0.33, 0.36))
LINE = lambda: mat("roadline", (0.85, 0.85, 0.8))
RAIL = lambda: mat("rail", (0.55, 0.58, 0.62), rough=0.4, metal=0.6)
RED = lambda: mat("gate_red", (0.85, 0.12, 0.12))
GREEN = lambda: mat("gate_green", (0.1, 0.75, 0.3))
GLASS = lambda: mat("glass", (0.3, 0.45, 0.6), rough=0.2, metal=0.5)
CONCRETE = lambda: mat("concrete", (0.55, 0.55, 0.52))


# ---------- 1. HERO SOLDIER (big minigunner, ~2.8 tall) ----------

def build_hero():
    clear()
    sk, bl, bd, gun, gold = SKIN(), BLUE(), BLUE_D(), GUN(), GOLD()
    o = []
    # legs
    o.append(cyl("legL", (-0.35, 0, 0.5), 0.22, 1.0, bd, vertices=10))
    o.append(cyl("legR", (0.35, 0, 0.5), 0.22, 1.0, bd, vertices=10))
    o.append(box("bootL", (-0.35, -0.08, 0.12), (0.5, 0.7, 0.25), gold))
    o.append(box("bootR", (0.35, -0.08, 0.12), (0.5, 0.7, 0.25), gold))
    # big V torso
    o.append(sph("torso", (0, 0, 1.75), 0.62, bl, scale=(1.35, 0.85, 1.15)))
    o.append(sph("chest", (0, -0.15, 2.1), 0.55, bl, scale=(1.5, 0.75, 0.9)))
    # belt + bandolier
    o.append(cyl("belt", (0, 0, 1.3), 0.62, 0.18, DARK(), vertices=12, scale=(1.25, 0.8, 1)))
    b = box("bandolier", (0.15, -0.52, 2.15), (0.25, 0.1, 1.4), gold)
    b.rotation_euler[1] = math.radians(-30)
    o.append(b)
    # head + beret
    o.append(sph("head", (0, 0, 2.75), 0.32, sk, scale=(1, 0.95, 1.1)))
    o.append(sph("beret", (0.05, 0, 3.05), 0.28, bl, scale=(1.15, 1.0, 0.45)))
    o.append(box("jaw", (0, -0.15, 2.62), (0.4, 0.35, 0.18), sk))
    # arms: thick, holding gun forward (gun along -Y... we face -Y? Godot forward -Z; build facing -Y then rotate at export—simpler: build facing -Z? glTF exporter maps -Y fwd. Build facing +Y in Blender => -Y in Godot? To keep it simple, build character facing -Y in Blender (glTF -Z fwd in Godot). Blender: arms reach toward -Y.
    for sx in (-1, 1):
        o.append(cyl(f"arm{sx}", (sx * 0.85, -0.15, 2.25), 0.26, 0.9, sk, rot=(math.radians(60), 0, 0), vertices=10))
        o.append(cyl(f"forearm{sx}", (sx * 0.7, -0.75, 1.9), 0.2, 0.7, sk, rot=(math.radians(85), 0, sx * math.radians(15)), vertices=10))
        o.append(sph(f"hand{sx}", (sx * 0.62, -1.1, 1.9), 0.18, sk))
        o.append(sph(f"shoulder{sx}", (sx * 0.85, 0, 2.5), 0.32, sk))
    # minigun: body + barrel cluster, pointing -Y
    o.append(box("gunbody", (0, -1.25, 1.95), (0.7, 0.9, 0.5), gun))
    o.append(cyl("barrels", (0, -1.9, 1.95), 0.16, 0.9, gold, rot=(math.radians(90), 0, 0), vertices=10))
    for i in range(6):
        a = i * math.pi / 3
        o.append(cyl(f"b{i}", (0.14 * math.cos(a), -1.95 + 0 * math.sin(a), 1.95 + 0.14 * math.sin(a)), 0.045, 1.0, gun, rot=(math.radians(90), 0, 0), vertices=8))
    join_all(o, "hero")
    export_glb(os.path.join(OUT, "hero.glb"))


# ---------- 2. RUNNER (small vest guy, ~1.15 tall) ----------

def build_runner():
    clear()
    sk, wh, orn, gun, br = SKIN(), WHITE(), ORANGE(), GUN(), BROWN()
    o = []
    o.append(cyl("legL", (-0.13, 0, 0.22), 0.09, 0.42, orn, vertices=8))
    o.append(cyl("legR", (0.13, 0, 0.22), 0.09, 0.42, orn, vertices=8))
    o.append(box("bootL", (-0.13, -0.05, 0.05), (0.18, 0.3, 0.1), br, bevel=0.03))
    o.append(box("bootR", (0.13, -0.05, 0.05), (0.18, 0.3, 0.1), br, bevel=0.03))
    o.append(sph("hips", (0, 0, 0.5), 0.24, orn, scale=(1.15, 0.9, 0.7)))
    o.append(sph("torso", (0, 0, 0.85), 0.26, wh, scale=(1.3, 0.8, 1.0)))
    o.append(sph("head", (0, -0.02, 1.28), 0.16, sk, scale=(1, 0.95, 1.05)))
    o.append(sph("hair", (0, 0.01, 1.37), 0.14, br, scale=(1.05, 1.0, 0.6)))
    for sx in (-1, 1):
        o.append(cyl(f"arm{sx}", (sx * 0.33, -0.05, 0.95), 0.09, 0.45, sk, rot=(math.radians(50), 0, sx * math.radians(-20)), vertices=8))
    # small rifle slung pointing up-forward
    o.append(cyl("rifle", (0.15, -0.35, 1.05), 0.05, 0.6, gun, rot=(math.radians(75), 0, math.radians(-20)), vertices=8))
    join_all(o, "runner")
    export_glb(os.path.join(OUT, "runner.glb"))


# ---------- 3. HORDE ENEMY (small hunched zombie, ~1.0) ----------

def build_enemy():
    clear()
    z, c, d = ZOMBIE(), ZOMBIE_C(), DARK()
    o = []
    o.append(cyl("legL", (-0.12, 0, 0.18), 0.08, 0.35, d, vertices=8))
    o.append(cyl("legR", (0.12, 0, 0.18), 0.08, 0.35, d, vertices=8))
    t = sph("torso", (0, 0.05, 0.65), 0.26, c, scale=(1.15, 0.9, 1.1))
    t.rotation_euler[0] = math.radians(20)  # hunched forward
    o.append(t)
    o.append(sph("head", (0, -0.12, 1.0), 0.17, z, scale=(1, 1, 1.05)))
    for sx in (-1, 1):
        o.append(cyl(f"arm{sx}", (sx * 0.3, -0.25, 0.7), 0.07, 0.45, z, rot=(math.radians(80), 0, sx * math.radians(-10)), vertices=8))
    join_all(o, "enemy")
    export_glb(os.path.join(OUT, "enemy.glb"))


# ---------- 4. BOSS (giant fat butcher, ~4.2 tall) ----------

def build_boss():
    clear()
    z, ap, d, sk = ZOMBIE(), APRON(), DARK(), SKIN_D()
    o = []
    o.append(cyl("legL", (-0.5, 0, 0.6), 0.32, 1.1, d, vertices=10))
    o.append(cyl("legR", (0.5, 0, 0.6), 0.32, 1.1, d, vertices=10))
    o.append(sph("belly", (0, -0.1, 1.9), 1.15, sk, scale=(1.2, 1.0, 1.15)))
    o.append(sph("chest", (0, 0, 2.9), 0.9, sk, scale=(1.35, 0.95, 0.95)))
    # apron
    o.append(box("apron", (0, -0.95, 1.9), (1.5, 0.25, 2.0), ap, bevel=0.15))
    # head + wrap
    o.append(sph("head", (0, -0.15, 3.85), 0.45, sk, scale=(1, 0.95, 1.0)))
    o.append(cyl("wrap", (0, -0.15, 4.15), 0.46, 0.25, ap, vertices=12))
    # glowing eyes
    o.append(sph("eyeL", (-0.18, -0.55, 3.95), 0.07, mat("eye_glow", (1, 0.3, 0.1), emit=(1, 0.2, 0.05), emit_str=3)))
    o.append(sph("eyeR", (0.18, -0.55, 3.95), 0.07, mat("eye_glow", (1, 0.3, 0.1), emit=(1, 0.2, 0.05), emit_str=3)))
    # thick arms hanging forward
    for sx in (-1, 1):
        o.append(cyl(f"arm{sx}", (sx * 1.05, -0.2, 2.9), 0.38, 1.2, sk, rot=(math.radians(30), 0, 0), vertices=10))
        o.append(sph(f"fist{sx}", (sx * 1.05, -0.7, 2.2), 0.42, sk))
    join_all(o, "boss")
    export_glb(os.path.join(OUT, "boss.glb"))


# ---------- 5. PEDESTAL for hero ----------

def build_pedestal():
    clear()
    o = [box("base", (0, 0, 0.3), (3.2, 3.2, 0.6), GREY(), bevel=0.1),
         box("top", (0, 0, 0.65), (2.7, 2.7, 0.15), CONCRETE(), bevel=0.03)]
    join_all(o, "pedestal")
    export_glb(os.path.join(OUT, "pedestal.glb"))


# ---------- 6. BRIDGE SEGMENT (8 wide x 20 long, railings) ----------

def build_bridge():
    clear()
    o = []
    o.append(box("road", (0, 0, -0.3), (8.0, 20.0, 0.6), ROAD(), bevel=0))
    # dashed center line + lane marks
    for i in range(4):
        y = -8.0 + i * 5.0
        o.append(box(f"line{i}", (0, y, 0.005), (0.15, 2.2, 0.02), LINE(), bevel=0))
    # edge lines
    o.append(box("edgeL", (-3.7, 0, 0.005), (0.12, 20, 0.02), LINE(), bevel=0))
    o.append(box("edgeR", (3.7, 0, 0.005), (0.12, 20, 0.02), LINE(), bevel=0))
    # railings both sides
    for sx in (-1, 1):
        for i in range(5):
            y = -9.0 + i * 4.5
            o.append(box(f"post{sx}_{i}", (sx * 4.1, y, 0.8), (0.15, 0.15, 1.6), RAIL(), bevel=0.02))
        o.append(cyl(f"rail{sx}_a", (sx * 4.1, 0, 1.45), 0.05, 20, RAIL(), rot=(math.radians(90), 0, 0), vertices=8))
        o.append(cyl(f"rail{sx}_b", (sx * 4.1, 0, 0.9), 0.04, 20, RAIL(), rot=(math.radians(90), 0, 0), vertices=8))
    join_all(o, "bridge")
    export_glb(os.path.join(OUT, "bridge.glb"))


# ---------- 7. SKYSCRAPERS (3 variants in one file) ----------

def build_buildings():
    clear()
    # building A: slab tower
    o = [box("bA", (0, 0, 15), (10, 10, 30), mat("bldA", (0.18, 0.22, 0.35)), bevel=0.2)]
    for f in range(8):
        for c_ in range(3):
            o.append(box(f"wA{f}{c_}", (-3 + c_ * 3, -5.02, 4 + f * 3.2), (1.6, 0.05, 1.6), GLASS(), bevel=0.05))
    join_all(o, "bld_a")
    # building B: stepped
    o = [box("bB1", (16, 0, 9), (7, 8, 18), mat("bldB", (0.25, 0.2, 0.3)), bevel=0.2),
         box("bB2", (16, 0, 20), (5, 6, 6), mat("bldB", (0.25, 0.2, 0.3)), bevel=0.15),
         box("bB3", (16, 0, 25), (2, 3, 4), DARK(), bevel=0.1)]
    join_all(o, "bld_b")
    # building C: thin spire
    o = [box("bC", (-16, 0, 18), (5, 5, 36), mat("bldC", (0.15, 0.2, 0.32)), bevel=0.15),
         cyl("antenna", (-16, 0, 39), 0.1, 6, DARK(), vertices=6)]
    join_all(o, "bld_c")
    export_glb(os.path.join(OUT, "buildings.glb"))


# ---------- 8. GATE (frame + banner; number via Label3D) ----------

def build_gate():
    clear()
    o = []
    for sx in (-1, 1):
        o.append(cyl(f"post{sx}", (sx * 2.6, 0, 1.6), 0.12, 3.2, RAIL(), vertices=10))
    o.append(box("banner", (0, 0, 3.1), (5.6, 0.25, 1.2), GREY(), bevel=0.08))
    join_all(o, "gate")
    export_glb(os.path.join(OUT, "gate.glb"))


if __name__ == "__main__":
    build_hero()
    build_runner()
    build_enemy()
    build_boss()
    build_pedestal()
    build_bridge()
    build_buildings()
    build_gate()
    print("ALL ASSETS DONE")
