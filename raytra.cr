require "stumpy_png"
include StumpyPNG

# Config
# ------------------------------------
WIDTH = 640
HEIGHT = 480
MAX_DEPTH = 5
BACKGROUND_COLOR = {0.5, 0.5, 0.5}
FOV = 30
# ------------------------------------

class Vec3
	getter x, y, z
	def initialize(@x : Float64, @y : Float64, @z : Float64)
	end
	def initialize(v : Float64)
		@x = @y = @z = v
	end
	
	def +(vec : Vec3)
		Vec3.new(x + vec.x, y + vec.y, z + vec.z)
	end
	def -(vec : Vec3)
		Vec3.new(x - vec.x, y - vec.y, z - vec.z)
	end
	def *(color : Vec3)
		Vec3.new(x * color.x, y * color.y, z * color.z)
	end
	def *(fac : Float64)
		Vec3.new(x * fac, y * fac, z * fac)
	end
	def /(fac : Float64)
		Vec3.new(x / fac, y / fac, z / fac)
	end
	def -
		Vec3.new(-x, -y, -z)
	end
	def abs
		dot(self)
	end
	def components
		{x, y, z}
	end
	def normalize
		mag = Math.sqrt(self.abs)
		Vec3.new(x / mag, y / mag, z / mag)
	end
	def dot(vec)
		x * vec.x + y * vec.y + z * vec.z
	end
end
Color = Vec3

class Sphere
	getter center, radius, color, reflect
	def initialize(@center : Vec3, @radius  : Float64,
	               @color  : Vec3, @reflect : Float64)
	end
	
	def intersect(ray_orig, ray_dir)
		dist = ray_orig - center
		b = 2 * dist.dot(ray_dir)
		return 1e8 if b > 0
		c = dist.abs - radius ** 2
		disc = (b ** 2) - (4 * c)
		return 1e8 if disc < 0
		sq = Math.sqrt(disc)
		t0 = (-b - sq) / 2
		t1 = (-b + sq) / 2
		return t0 < t1 ? t0 : t1
	end
	def normal(intersect)
		(intersect - center) / radius
	end
	def color(intersect)
		color
	end
end

class CheckeredSphere < Sphere
	def color(intersect)
		checker = (intersect.x.floor % 2) == (intersect.z.floor % 2)
		color * (checker ? 1.0 : 0.0)
	end
end

struct PointLight
	property pos, color
	def initialize(@pos : Vec3, @color : Vec3)
	end
end

def raytrace(ray_orig, ray_dir, world, depth = 0)
	
	nearest_obj = nil
	min_dist = 1e8
	
	world.each do |obj|
		dist = obj.intersect(ray_orig, ray_dir)
		if dist < min_dist
			min_dist = dist
			nearest_obj = obj
		end
	end
	
	if nearest_obj.nil?
		return Color.new(*BACKGROUND_COLOR)
	end
	
	intersect = ray_orig + ray_dir * min_dist
	normal = nearest_obj.normal(intersect).normalize
	
	color = Color.new(0.05)
	
	test_light = PointLight.new(Vec3.new(0, 20, 10), Color.new(1))
	
	light_dir = (test_light.pos - intersect).normalize
	origin_dir = (Vec3.new(0) - intersect).normalize
	
	offset = intersect + normal * 1e-4
	
	light_distances = world.map { |obj| obj.intersect(offset, light_dir) }
	light_nearest = light_distances.min
	light_visible = light_distances[world.index(nearest_obj).not_nil!] == light_nearest
	
	lv = Math.max(0.0, normal.dot(light_dir))
	color += nearest_obj.color(intersect) * test_light.color * lv if light_visible
	
	if nearest_obj.reflect > 0 && depth < MAX_DEPTH
		reflect_ray_dir = (ray_dir - normal * 2.0 * ray_dir.dot(normal)).normalize
		color += raytrace(offset, reflect_ray_dir, world, depth + 1) * nearest_obj.reflect
	end
	
	phong = normal.dot((light_dir + origin_dir).normalize)
	color += test_light.color * (phong.clamp(0.0, 1.0) ** 50) if light_visible
	
	return color
end

def render(world)
	
	image = Canvas.new(WIDTH, HEIGHT)
	
	aspect_ratio = WIDTH / HEIGHT.to_f64
	angle = Math.tan(Math::PI * 0.5 * FOV / 180)
	
	(0...HEIGHT).each do |row|
		(0...WIDTH).each do |col|
			x = (2 * ((col + 0.5) * (1.0 / WIDTH)) - 1) * angle * aspect_ratio
			y = (1 - 2 * ((row + 0.5) * (1.0 / HEIGHT))) * angle
			
			ray_orig = Vec3.new(0, 0, 0)
			ray_dir = Vec3.new(x, y, 1).normalize
			
			color = raytrace(ray_orig, ray_dir, world)
			image[col, row] = RGBA.from_rgb(*color.components.map{|c| c.clamp(0.0, 1.0) * 255})
		end
	end
	
	StumpyPNG.write(image, "out.png")
end

world = [
	CheckeredSphere.new(Vec3.new(0, -10004, 20), 10000, Color.new(0.25), 0.2),
	Sphere.new(Vec3.new(0, 0, 20), 4, Color.new(1, 0, 0), 0.2),
	Sphere.new(Vec3.new(6, -1, 20), 2, Color.new(0, 0, 1), 0.2),
]

render(world)
