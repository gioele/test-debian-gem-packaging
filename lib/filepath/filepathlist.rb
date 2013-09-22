# This is free software released into the public domain (CC0 license).


class FilePathList
	include Enumerable

	SEPARATOR = ':'.freeze

	def initialize(raw_entries = nil)
		raw_entries ||= []
		@entries = raw_entries.map { |e| e.as_path }
	end

	def select_entries(type)
		raw_entries = @entries.delete_if { |e| !e.send(type.to_s + '?') }
		return FilePathList.new(raw_entries)
	end

	def files
		return select_entries(:file)
	end

	def links
		return select_entries(:link)
	end

	def directories
		return select_entries(:directory)
	end

	def /(extra_path)
		return self.map { |path| path / extra_path }
	end

	def +(extra_entries)
		return FilePathList.new(@entries + extra_entries.to_a)
	end

	def -(others)
		remaining_entries = @entries - others.as_path_list.to_a

		return FilePathList.new(remaining_entries)
	end

	def <<(extra_path)
		return FilePathList.new(@entries + [extra_path.as_path])
	end

	def *(other_list)
		if !other_list.is_a? FilePathList
			other_list = FilePathList.new(Array(other_list))
		end
		other_entries = other_list.entries
		paths = @entries.product(other_entries).map { |p1, p2| p1 / p2 }
		return FilePathList.new(paths)
	end

	def remove_common_segments
		all_segs = @entries.map(&:segments)
		max_length = all_segs.map(&:length).min

		idx_different = nil

		(0..max_length).each do |i|
			segment = all_segs.first[i]

			different = all_segs.any? { |segs| segs[i] != segment }
			if different
				idx_different = i
				break
			end
		end

		idx_different ||= max_length

		remaining_segs = all_segs.map { |segs| segs[idx_different..-1] }

		return FilePathList.new(remaining_segs)
	end

	# @return [FilePathList] the path list itself

	def as_path_list
		self
	end

	def to_a
		@entries
	end

	def to_s
		@to_s ||= @entries.map(&:to_str).join(SEPARATOR)
	end


	# @private
	def inspect
		@entries.inspect
	end

	def ==(other)
		@entries == other.as_path_list.to_a
	end

	module ArrayMethods
		# @private
		def self.define_array_method(name)
			define_method(name) do |*args, &block|
				return @entries.send(name, *args, &block)
			end
		end

		define_array_method :[]

		define_array_method :empty?

		define_array_method :include?

		define_array_method :each

		define_array_method :all?

		define_array_method :any?

		define_array_method :none?

		define_array_method :size
	end

	module EntriesMethods
		def map(&block)
			mapped_entries = @entries.map(&block)
			return FilePathList.new(mapped_entries)
		end

		def select(pattern = nil, &block)
			if !block_given?
				block = proc { |e| e =~ pattern }
			end

			remaining_entries = @entries.select { |e| block.call(e) }

			return FilePathList.new(remaining_entries)
		end

		def exclude(pattern = nil, &block)
			if block_given?
				select { |e| !block.call(e) }
			else
				select { |e| !(e =~ pattern) }
			end
		end
	end

	include ArrayMethods
	include EntriesMethods
end
