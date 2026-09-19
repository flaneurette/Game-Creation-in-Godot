bl_info = {
    "name": "Material Baker",
    "author": "Claude",
    "version": (1, 4, 0),
    "blender": (2, 80, 0),
    "location": "3D Viewport > Sidebar (N key) > Baker tab",
    "description": "Bakes the shader of any named meshes into image textures on a '_baked' copy, ready for game engines",
    "category": "Object",
}

import math
import os

import bpy
from bpy.props import BoolProperty, IntProperty, PointerProperty, StringProperty
from bpy.types import Operator, Panel, PropertyGroup
from bpy_extras.io_utils import ExportHelper

SUFFIX = "_baked"
CONVERTIBLE = {'MESH', 'CURVE', 'SURFACE', 'FONT'}


# ----------------------------------------------------------------------------
# Panel settings
# ----------------------------------------------------------------------------
class MatBakerProps(PropertyGroup):
    names: StringProperty(
        name="Mesh names",
        description="Comma separated names (or parts of names) of the objects to bake, e.g. trunk, leaves",
        default="",
    )
    texture_size: IntProperty(
        name="Texture size", description="Width and height of the baked images in pixels",
        default=1024, min=64, max=8192,
    )
    bake_normal: BoolProperty(
        name="Bake normal map",
        description="Also bake bump / normal detail into a normal map image",
        default=True,
    )
    reunwrap: BoolProperty(
        name="Re-unwrap UVs",
        description="Create fresh non-overlapping UVs with Smart UV Project. "
                    "Untick to keep the model's own UVs (only if they do not overlap)",
        default=True,
    )
    hide_originals: BoolProperty(
        name="Hide originals",
        description="Hide the original objects after baking, so only the baked copies show",
        default=True,
    )
    embed_textures: BoolProperty(
        name="Embed textures in FBX",
        description="Store the texture images inside the FBX file itself. "
                    "The PNG files are also saved next to the export either way. "
                    "(GLB files always contain their textures)",
        default=True,
    )
    pack_images: BoolProperty(
        name="Pack images in .blend",
        description="Also store the images inside the .blend file, so saving the .blend keeps them",
        default=True,
    )
    overwrite: BoolProperty(
        name="Overwrite existing materials",
        description="Also replace materials that objects already have, including a starter shader you "
                    "already tweaked (it is reset). Off = only objects without any material get the starter shader",
        default=False,
    )


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
def parse_names(text):
    return [t.strip().lower() for t in text.split(",") if t.strip()]


def find_objects(context, tokens):
    found = []
    for o in context.scene.objects:
        if o.type not in CONVERTIBLE:
            continue
        n = o.name.lower()
        if n.endswith(SUFFIX):
            continue                     # never bake our own baked copies
        if any(t in n for t in tokens):
            found.append(o)
    return found


def deselect_all(context):
    """Deselect everything without bpy.ops, so it works from any editor / dialog."""
    for o in context.view_layer.objects:
        o.select_set(False)


def ensure_object_mode(context):
    """Leave Edit / Paint modes, otherwise many operators refuse to run."""
    ob = context.object
    if ob is not None and ob.mode != 'OBJECT':
        try:
            bpy.ops.object.mode_set(mode='OBJECT')
        except RuntimeError:
            pass


def select_only(context, obj):
    deselect_all(context)
    obj.select_set(True)
    context.view_layer.objects.active = obj


def unwrap(context, obj):
    select_only(context, obj)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    # angle_limit is in degrees before Blender 2.91 and in radians afterwards
    angle = math.radians(66.0) if bpy.app.version >= (2, 91, 0) else 66.0
    bpy.ops.uv.smart_project(angle_limit=angle, island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')


def fresh_image(name, size, non_color=False):
    old = bpy.data.images.get(name)
    if old:
        bpy.data.images.remove(old)
    img = bpy.data.images.new(name, size, size, alpha=False)
    if non_color:
        img.colorspace_settings.name = "Non-Color"
    return img


def remove_old_baked(obj_name):
    old = bpy.data.objects.get(obj_name + SUFFIX)
    if old is None:
        return
    data = old.data
    bpy.data.objects.remove(old, do_unlink=True)
    if data is not None and data.users == 0:
        if isinstance(data, bpy.types.Mesh):
            bpy.data.meshes.remove(data)


def prepare_temp_material(temp, original):
    """Make sure a temporary copy has nodes so it can be baked."""
    if not temp.use_nodes:
        temp.use_nodes = True
        for n in temp.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                n.inputs["Base Color"].default_value = tuple(original.diffuse_color)


def add_bake_target(temp):
    nodes = temp.node_tree.nodes
    target = nodes.new("ShaderNodeTexImage")
    target.location = (-800, -800)
    for n in nodes:
        n.select = False
    target.select = True
    nodes.active = target                # Blender bakes into the ACTIVE image node
    return target


def build_starter_shader(name):
    """A simple procedural shader to tweak by hand in the Shader Editor."""
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    bsdf.inputs["Roughness"].default_value = 0.8
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    coord = nodes.new("ShaderNodeTexCoord")
    coord.location = (-1100, 0)

    mapping = nodes.new("ShaderNodeMapping")
    mapping.location = (-900, 0)
    mapping.label = "Mapping (stretch / move pattern)"

    noise = nodes.new("ShaderNodeTexNoise")
    noise.location = (-700, 0)
    noise.label = "Pattern (change Scale / Detail)"
    noise.inputs["Scale"].default_value = 12.0
    noise.inputs["Detail"].default_value = 12.0

    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (-450, 150)
    ramp.label = "Colors (click the color squares)"
    ramp.color_ramp.elements[0].color = (0.10, 0.08, 0.06, 1.0)
    ramp.color_ramp.elements[1].color = (0.45, 0.38, 0.30, 1.0)

    bump = nodes.new("ShaderNodeBump")
    bump.location = (-100, -250)
    bump.label = "Bump (change Strength)"
    bump.inputs["Strength"].default_value = 0.6

    links.new(coord.outputs["Object"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def build_baked_material(name, color_img, normal_img):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    color_node = nodes.new("ShaderNodeTexImage")
    color_node.image = color_img
    color_node.location = (-300, 150)
    links.new(color_node.outputs["Color"], bsdf.inputs["Base Color"])

    if normal_img is not None:
        normal_node = nodes.new("ShaderNodeTexImage")
        normal_node.image = normal_img
        normal_node.location = (-500, -250)
        normal_map = nodes.new("ShaderNodeNormalMap")
        normal_map.location = (-150, -250)
        links.new(normal_node.outputs["Color"], normal_map.inputs["Color"])
        links.new(normal_map.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


# ----------------------------------------------------------------------------
# The bake, for one object
# ----------------------------------------------------------------------------
def bake_object(context, props, obj):
    """Bakes a copy of obj. The original object and its materials stay untouched."""
    if not any(s.material for s in obj.material_slots):
        raise RuntimeError("'%s' has no material to bake" % obj.name)

    remove_old_baked(obj.name)

    # 1. work on a copy
    dup = obj.copy()
    dup.data = obj.data.copy()
    dup.name = obj.name + SUFFIX
    dup.data.name = dup.name
    for c in obj.users_collection:
        c.objects.link(dup)

    temps, targets = [], []
    try:
        # 2. make it a real mesh with modifiers applied
        if dup.type != 'MESH':
            select_only(context, dup)
            bpy.ops.object.convert(target='MESH')
            dup = context.view_layer.objects.active
        elif dup.modifiers:
            select_only(context, dup)
            try:
                bpy.ops.object.convert(target='MESH')
                dup = context.view_layer.objects.active
            except RuntimeError:
                pass                     # keep the modifiers if they can't be applied

        # 3. temporary material copies, so the originals are never touched
        for i, m in enumerate(dup.data.materials):
            if m is None:
                continue
            t = m.copy()
            prepare_temp_material(t, m)
            dup.data.materials[i] = t
            temps.append(t)
            targets.append(add_bake_target(t))

        # 4. UVs
        if props.reunwrap or len(dup.data.uv_layers) == 0:
            unwrap(context, dup)

        # 5. bake
        def bake(img, bake_type):
            for tnode in targets:
                tnode.image = img
            select_only(context, dup)
            if bake_type == 'DIFFUSE':
                bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, margin=8, use_clear=True)
            else:
                bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT', margin=8, use_clear=True)

        color_img = fresh_image(obj.name + "_color", props.texture_size)
        bake(color_img, 'DIFFUSE')
        normal_img = None
        if props.bake_normal:
            normal_img = fresh_image(obj.name + "_normal", props.texture_size, non_color=True)
            bake(normal_img, 'NORMAL')

        # 6. swap in one clean material that only uses the baked images
        final = build_baked_material(obj.name + SUFFIX, color_img, normal_img)
        dup.data.materials.clear()
        dup.data.materials.append(final)
        for p in dup.data.polygons:
            p.material_index = 0
        for t in temps:
            bpy.data.materials.remove(t)
    except Exception:
        # clean up the half-made copy and its temporary materials, then re-raise
        data = dup.data
        bpy.data.objects.remove(dup, do_unlink=True)
        if isinstance(data, bpy.types.Mesh) and data.users == 0:
            bpy.data.meshes.remove(data)
        for t in temps:
            if t.name in bpy.data.materials:
                bpy.data.materials.remove(t)
        raise
    return dup


# ----------------------------------------------------------------------------
# Operators
# ----------------------------------------------------------------------------
class OBJECT_OT_mat_baker_shader(Operator):
    bl_idname = "object.mat_baker_shader"
    bl_label = "Create Shader"
    bl_description = ("Give the named objects a starter procedural shader, then tweak it in the Shader Editor. "
                      "Objects that already have a material are left alone unless 'Overwrite' is ticked")
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        props = context.scene.mat_baker
        tokens = parse_names(props.names)
        if not tokens:
            self.report({'ERROR'}, "Type at least one mesh name")
            return {'CANCELLED'}
        objs = find_objects(context, tokens)
        if not objs:
            self.report({'ERROR'}, "No objects in the scene match those names")
            return {'CANCELLED'}

        ensure_object_mode(context)
        created, skipped = [], []
        for obj in objs:
            has_material = any(s.material for s in obj.material_slots)
            if has_material and not props.overwrite:
                skipped.append(obj.name)
                continue
            mat = build_starter_shader(obj.name + "_shader")
            obj.data.materials.clear()
            obj.data.materials.append(mat)
            created.append(obj)

        if created:
            deselect_all(context)
            for o in created:
                o.select_set(True)
            context.view_layer.objects.active = created[0]

        if skipped:
            self.report({'INFO'}, "Skipped (already have a material, tweak that one directly): "
                                  + ", ".join(skipped))
        if not created:
            self.report({'WARNING'}, "Nothing created. Tick 'Overwrite existing materials' to replace them")
            return {'CANCELLED'}
        self.report({'INFO'}, "Starter shader added to %d object(s). Open the Shading workspace to tweak it, "
                              "then press Bake Now." % len(created))
        return {'FINISHED'}


class OBJECT_OT_mat_baker_run(Operator):
    bl_idname = "object.mat_baker_run"
    bl_label = "Bake Now"
    bl_description = "Bake the shader of the named meshes into images on a '_baked' copy"
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        props = context.scene.mat_baker
        tokens = parse_names(props.names)
        if not tokens:
            self.report({'ERROR'}, "Type at least one mesh name")
            return {'CANCELLED'}

        objs = find_objects(context, tokens)
        if not objs:
            self.report({'ERROR'}, "No objects in the scene match those names")
            return {'CANCELLED'}

        ensure_object_mode(context)

        scene = context.scene
        old_engine = scene.render.engine
        old_samples = scene.cycles.samples
        scene.render.engine = 'CYCLES'
        scene.cycles.samples = 1          # plenty for color / normal baking

        baked, failed = [], []
        try:
            for obj in objs:
                try:
                    baked.append((obj, bake_object(context, props, obj)))
                except RuntimeError as e:
                    failed.append(str(e))
        finally:
            scene.render.engine = old_engine
            scene.cycles.samples = old_samples

        for original, _dup in baked:
            if props.hide_originals:
                original.hide_set(True)

        if baked:
            deselect_all(context)
            for _o, dup in baked:
                dup.select_set(True)
            context.view_layer.objects.active = baked[-1][1]

        for msg in failed:
            self.report({'WARNING'}, msg)
        if not baked:
            self.report({'ERROR'}, "Nothing was baked")
            return {'CANCELLED'}
        self.report({'INFO'}, "Baked %d object(s). Tweak the shader and bake again, or scroll down "
                              "the panel and click Export FBX." % len(baked))
        return {'FINISHED'}


def prepare_baked_for_export(op, context, filepath):
    """Shared by the FBX and GLB buttons. Returns the baked objects (now selected) or None."""
    props = context.scene.mat_baker
    tokens = parse_names(props.names)

    objs = [
        o for o in context.scene.objects
        if o.type == 'MESH' and o.name.lower().endswith(SUFFIX)
        and (not tokens or any(t in o.name.lower() for t in tokens))
    ]
    if not objs:
        op.report({'ERROR'}, "No '_baked' copies found. Press Bake Now first")
        return None

    ensure_object_mode(context)
    folder = os.path.dirname(bpy.path.abspath(filepath))
    os.makedirs(folder, exist_ok=True)

    # save every baked image as a PNG next to the export, then use the saved file
    replaced = {}
    for o in objs:
        for slot in o.material_slots:
            mat = slot.material
            if mat is None or not mat.use_nodes:
                continue
            for node in mat.node_tree.nodes:
                if node.type != 'TEX_IMAGE' or node.image is None:
                    continue
                img = node.image
                if img not in replaced:
                    path = os.path.join(folder, img.name.replace(os.sep, "_") + ".png")
                    img.filepath_raw = path
                    img.file_format = 'PNG'
                    img.save()
                    loaded = bpy.data.images.load(path, check_existing=True)
                    loaded.reload()
                    loaded.colorspace_settings.name = img.colorspace_settings.name
                    if props.pack_images:
                        try:
                            loaded.pack()
                        except RuntimeError:
                            pass
                    replaced[img] = loaded
                node.image = replaced[img]
    for old in replaced:
        if old.users == 0:
            bpy.data.images.remove(old)

    # select only the baked copies for the exporter
    deselect_all(context)
    for o in objs:
        o.select_set(True)
    context.view_layer.objects.active = objs[0]
    return objs


def gltf_selection_kwarg():
    """The glTF exporter calls this option 'export_selected' in Blender 2.83 and 'use_selection' later."""
    try:
        names = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
        return "use_selection" if "use_selection" in names else "export_selected"
    except Exception:
        return "use_selection"


class OBJECT_OT_mat_baker_export(Operator, ExportHelper):
    bl_idname = "object.mat_baker_export"
    bl_label = "Export FBX"
    bl_description = ("Save the baked images as PNG files, pack them, and export the '_baked' copies "
                      "as an FBX with the textures included")

    filename_ext = ".fbx"
    filter_glob: StringProperty(default="*.fbx", options={'HIDDEN'})

    def execute(self, context):
        props = context.scene.mat_baker
        objs = prepare_baked_for_export(self, context, self.filepath)
        if objs is None:
            return {'CANCELLED'}
        bpy.ops.export_scene.fbx(
            filepath=self.filepath,
            use_selection=True,
            object_types={'MESH'},
            path_mode='COPY',
            embed_textures=props.embed_textures,
        )
        self.report({'INFO'}, "Exported %d object(s) to %s. PNG files are next to it." % (len(objs), self.filepath))
        return {'FINISHED'}


class OBJECT_OT_mat_baker_export_glb(Operator, ExportHelper):
    bl_idname = "object.mat_baker_export_glb"
    bl_label = "Export GLB"
    bl_description = ("Save the baked images as PNG files, pack them, and export the '_baked' copies "
                      "as a single .glb file with the textures included")

    filename_ext = ".glb"
    filter_glob: StringProperty(default="*.glb", options={'HIDDEN'})

    def execute(self, context):
        objs = prepare_baked_for_export(self, context, self.filepath)
        if objs is None:
            return {'CANCELLED'}
        kwargs = {
            "filepath": self.filepath,
            "export_format": 'GLB',
            gltf_selection_kwarg(): True,
        }
        try:
            bpy.ops.export_scene.gltf(**kwargs)
        except AttributeError:
            self.report({'ERROR'}, "glTF exporter not found. Enable it in Edit > Preferences > Add-ons: "
                                   "'Import-Export: glTF 2.0'")
            return {'CANCELLED'}
        self.report({'INFO'}, "Exported %d object(s) to %s. PNG files are next to it." % (len(objs), self.filepath))
        return {'FINISHED'}


class OBJECT_OT_mat_baker_fill(Operator):
    bl_idname = "object.mat_baker_fill"
    bl_label = "Use Selected Names"
    bl_description = "Fill the name field with the names of the currently selected objects"

    def execute(self, context):
        names = [o.name for o in context.selected_objects if not o.name.lower().endswith(SUFFIX)]
        if not names:
            self.report({'WARNING'}, "Select some objects first")
            return {'CANCELLED'}
        context.scene.mat_baker.names = ", ".join(names)
        return {'FINISHED'}


# ----------------------------------------------------------------------------
# Panel
# ----------------------------------------------------------------------------
class VIEW3D_PT_mat_baker(Panel):
    bl_label = "Material Baker"
    bl_idname = "VIEW3D_PT_mat_baker"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = "Baker"

    def draw(self, context):
        layout = self.layout
        p = context.scene.mat_baker

        box = layout.box()
        box.label(text="Meshes")
        box.prop(p, "names")
        box.operator("object.mat_baker_fill", icon='RESTRICT_SELECT_OFF')

        box = layout.box()
        box.label(text="1. Shader")
        box.operator("object.mat_baker_shader", icon='NODE_MATERIAL')
        box.prop(p, "overwrite")
        box.label(text="Then tweak it in the Shader Editor")

        box = layout.box()
        box.label(text="2. Bake")
        col = box.column(align=True)
        col.prop(p, "texture_size")
        col.prop(p, "bake_normal")
        col.prop(p, "reunwrap")
        col.prop(p, "hide_originals")
        box.operator("object.mat_baker_run", icon='RENDER_STILL')
        box.label(text="Result: '<name>_baked' copies")

        box = layout.box()
        box.label(text="3. Export")
        box.prop(p, "embed_textures")
        box.prop(p, "pack_images")
        box.operator("object.mat_baker_export_glb", icon='EXPORT')
        box.operator("object.mat_baker_export", icon='EXPORT')


# ----------------------------------------------------------------------------
# Registration
# ----------------------------------------------------------------------------
classes = (
    MatBakerProps,
    OBJECT_OT_mat_baker_shader,
    OBJECT_OT_mat_baker_run,
    OBJECT_OT_mat_baker_export,
    OBJECT_OT_mat_baker_export_glb,
    OBJECT_OT_mat_baker_fill,
    VIEW3D_PT_mat_baker,
)


def register():
    for c in classes:
        bpy.utils.register_class(c)
    bpy.types.Scene.mat_baker = PointerProperty(type=MatBakerProps)


def unregister():
    del bpy.types.Scene.mat_baker
    for c in reversed(classes):
        bpy.utils.unregister_class(c)


if __name__ == "__main__":
    try:
        unregister()          # allows re-running from the Text Editor
    except Exception:
        pass
    register()
