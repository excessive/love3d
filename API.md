# Namespace

* love3d.math.constants.DOT_THRESHOLD
* love3d.math.constants.FLT_EPSILON
* love3d.math.intersect.circle_circle(circle1, circle2) [also circles{}?]
* love3d.math.intersect.line_line(point1, point2, point3, point4) [also points{}?]
* love3d.math.intersect.ray_triangle(ray, triangle)
* love3d.math.matrix({matrix})
* love3d.math.mesh.compute_normal(a, b, c)
* love3d.math.mesh.average(vertices)
* love3d.math.quaternion(x, y, z, w)
* love3d.math.simplex
* love3d.math.vec2(x, y)
* love3d.math.vec3(x, y, z)
* love3d.new_camera(vec3)
* love3d.new_matrix({matrix})
* love3d.new_model(model_file)
* love3d.new_quaternion(x, y, z, w)
* love3d.new_vec2(x, y)
* love3d.new_vec3(x, y, z)
* love3d.physics.* (This will probably end up being a wrapper for the Bullet physics engine)


# Objects

## Camera

* Camera:get_direction()
* Camera:get_position()
* Camera:reset()
* Camera:rotate_xy(vec2)
* Camera:set_direction(vec3)
* Camera:set_fov(fov_y)
* Camera:set_perspective(bool)
* Camera:set_position(vec3)


## Matrix

* Matrix:clone()
* Matrix:identity()
* Matrix:invert()
* Matrix:look_at(eye, center, up)
* Matrix:ortho(left, right, top, bottom, near, far)
* Matrix:perspective(fov_y, aspect, near, far)
* Matrix:pop()
* Matrix:project(object, view, projection, viewport)
* Matrix:push()
* Matrix:reset()
* Matrix:rotate(angle_vec3, axis_vec3)
* Matrix:scale(scale_vec3)
* Matrix:to_vec4s()
* Matrix:translate(translate_vec3)
* Matrix:transpose()
* Matrix:unproject(window, view, projection, viewport)


# Model

* Model:animate(animations)
* Model:draw(scale)
* Model:get_animations()
* Model:get_materials()
* Model:get_shader()
* Model:get_textures()
* Model:interpolate(animation, start_frame, end_frame)
* Model:set_material(material_file)
* Model:set_shader(shader_file)
* Model:set_texture(texture_file)
* Model:update(dt)


## Quaternion

## Vec2

* Vec2:angle_to(other)
* Vec2:clone()
* Vec2:cross(v)
* Vec2.dist(a, b)
* Vec2.dist2(a, b)
* Vec2:len()
* Vec2:len2()
* Vec2:mirror_on(v)
* Vec2:normalize()
* Vec2:normalize_inplace()
* Vec2:perpendicular()
* Vec2.permul(a, b)
* Vec2:project_on(v)
* Vec2:rotate(phi)
* Vec2:rotate_inplace(phi)
* Vec2:trim(maxLen)
* Vec2:trim_inplace(maxLen)
* Vec2:unpack()


## Vec3

* Vec3:angle_between(other)
* Vec3:angle_to(other)
* Vec3:clone()
* Vec3:cross(v)
* Vec3.dist(a, b)
* Vec3.dist2(a, b)
* Vec3.dot(a, b)
* Vec3:len()
* Vec3:len2()
* Vec3.lerp(a, b, s)
* Vec3:mirror_on(v)
* Vec3:normalize()
* Vec3:normalize_inplace()
* Vec3:orientation_to_direction(orientation)
* Vec3:perpendicular()
* Vec3:project_from(v)
* Vec3:project_on(v)
* Vec3:rotate(phi, axis)
* Vec3:rotate_inplace(phi, axis)
* Vec3:trim(maxLen)
* Vec3:trim_inplace(maxLen)
* Vec3:tuple()
* Vec3:unpack()
