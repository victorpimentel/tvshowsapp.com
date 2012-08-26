class Uploader
	attr_accessor :name

	def initialize(name)
		self.name = name
	end

	def is_valid?(uploaders_override = [])
		(VALID_UPLOADERS + uploaders_override).include? self.name
	end

	def is_better_than?(other, uploaders_override = [])
		uploaders = VALID_UPLOADERS + uploaders_override
		other_name = (other.is_a? Uploader) ? other.name : other
		uploaders.index(name) < uploaders.index(other_name)
	end
end
