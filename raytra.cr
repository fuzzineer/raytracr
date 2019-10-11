require "stumpy_png"
include StumpyPNG

# Config
# ------------------------------------
WIDTH = 640
HEIGHT = 480
MAX_DEPTH = 3
BACKGROUND_COLOR = {0.5, 0.5, 0.5}
FOV = 30
# ------------------------------------

class Vec3
	getter x, y, z
	def initialize(@x : Float64, @y : Float64, @z : Float64)
	end
	def initialize(v : Float64)
		@x, @y, @z = v, v, v
	end
	
	def +(vec : Vec3)
		Vec3.new(x + vec.x, y + vec.y, z + vec.z)
	end
	def -(vec : Vec3)
		Vec3.new(x - vec.x, y - vec.y, z - vec.z)
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
		self.dot(self)
	end
	def components
		{x, y, z}
	end
	def normalize
		mag = Math.sqrt(x ** 2 + y ** 2 + z ** 2)
		Vec3.new(x / mag, y / mag, z / mag)
	end
	def dot(vec)
		x * vec.x + y * vec.y + z * vec.z
	end
end
Color = Vec3

class Sphere
	getter center, radius, color, reflect
	def initialize(@center : Vec3, @radius : Float64, 
	               @color : Vec3, @reflect : Float64)
	end
	
	def intersect(ray_orig, ray_dir)
		dist = ray_orig - center
		b = 2 * dist.dot(ray_dir)
		c = dist.abs - radius ** 2
		disc = (b ** 2) - (4 * c)
		if disc < 0
			return 1e8
		end
		sq = Math.sqrt(disc)
		t0 = (-b - sq) / 2
		t1 = (-b + sq) / 2
		return t0 < t1 ? t0 : t1
	end
	def normal(intersect)
		(intersect - center) / radius
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
	return normal
	
	#return nearest_obj.color
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
			image[col, row] = RGBA.from_rgb(*color.components.map{|c| c * 255})
		end
	end
	
	StumpyPNG.write(image, "out.png")
end

world = [
	Sphere.new(Vec3.new(0, 0, 20), 4, Color.new(1, 0, 0), 0)
]

render(world)
