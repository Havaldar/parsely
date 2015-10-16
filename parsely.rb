class Component
	def initialize(name, start)
		@name = name
		@children = []
		@parents = []
		@start = start
		@close = start
	end
	def name
		@name
	end
	def close
		@close
	end
	def start
		@start
	end
	def children
		@children
	end
	def parents
		@parents
	end
	def add_child(child)
		@children.push(child)
	end
	def add_parent(parent)
		@parents.push(parent)
	end
	def set_start(start)
		@start = start
	end
	def set_close(close)
		@close = close
	end
end
def is_number?(object)
  true if Float(object) rescue false
end
def get_tag_comp(tag, comps)
	comps.each do |c|
		if tag.eql?(c.name)
			return c
		end
	end
	return nil
end
def print_hierarchy(component, level)
	result = "+"
	if component.children.empty?
		result = "#{component.name}\n"
	else
		result += "#{component.name}\n"
		component.children.each do |c|
			result += ("--" * (level)) + "#{print_hierarchy(c, level+1)}"
		end
	end
	return result
end
raw_files = Dir["#{ARGV[0]}/**/*.jsx"]
files = []
tags = []
raw_files.each do |file_name|
  if !File.directory?(file_name) && File.readable?(file_name)
    files.push(file_name)
  end
end

output = File.open("hierarchy.txt", "w")
components = []
component_names = []
count = 1
files.each do |file|
	open_brackets = 0
	open_parenthesis = 0
	current_component = nil
	f = File.open(file, "r")
	f.each_line do |line|
		if line.include? "React.createClass"
			name = line[/var(.*?)=/m,1]
			if name.nil?
				name = line[/const(.*?)=/m,1]
			end
			name.strip!
			if !component_names.include? name
				current_component = Component.new(name, count)
				components.push(current_component)
				component_names.push(current_component.name)
			end

		end
		open_parenthesis = open_parenthesis + line.count('(') - line.count(')')
		open_brackets = open_brackets + line.count('{') - line.count('}')

		if open_brackets == 0 && open_parenthesis == 0 && !current_component.nil?
			current_component.set_close(count)
			current_component = nil
		end
		count += 1
	end
	f.close
end
count = 1
files.each do |file|
	f = File.new(file)
	f.each_line do |line|
		if line.include? "ReactDOM.render" or line.include? "React.render"
			break
		end
		if line[/\<(.*?)$/]
			tag = line[/\<(.*?)$/].strip.gsub("<","").gsub(">","").gsub("/","").gsub(";","").gsub("=","").split[0]
			if component_names.include? tag
				tag_comp = get_tag_comp(tag, components)
				parent_comp = nil
				components.each do |i|
					if i.close >= count && i.start <= count
						parent_comp = i
					end
				end
				if !tag_comp.parents.include?(parent_comp)&&!parent_comp.nil?
					tag_comp.add_parent(parent_comp)
					parent_comp.add_child(tag_comp)
				end
			else
				if !is_number?(tag) 
					tags.push(tag)
				end
			end
		end
		count += 1
	end
	f.close
end
output.write("Hierarchy:")
components.each do |c|
	if c.parents.empty?
		output.write print_hierarchy(c,1)
	end
end
output.write("\n\nAll the HTML tags used:")
tags.uniq!
tags.each do |i|
	output.write("\n #{i}")
end