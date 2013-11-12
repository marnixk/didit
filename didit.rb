
# ------------------------------------------------------------------------
#    Contains service retrieval functions that can be called from
#    anywhere outside the services contexts to get an 'in'. Great for
#    calling from a Rails controller for example
# ------------------------------------------------------------------------
module Didit

	private

		SERVICES = {}

		#
		#  Convert a word cased word into a underscored version of it
		#
		def self.underscore(word)
			word.gsub!(/::/, '/')
			word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
			word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
			word.tr!("-", "_")
			word.downcase!
			word
		end

	public	

		#
		#   Returns a symbol of the class that it is passed
		#
		def self.get_class_identifier(clazz)
			Didit::underscore(clazz.name).to_sym
		end
		
		#
		#   Return the service object for a specific class
		#
		def self.service_object(clazz)
			identifier = Didit::get_class_identifier(clazz)
			return Didit::SERVICES.find { |(key, val)| val[:identifier] == identifier }.last
		end

		#
		#   Returns a list of services that all have a particular object base
		#
		def self.services_with_base(clazz)
			Didit::SERVICES\
				.find_all { |key, service| service[:class_instance].is_a? clazz }\
				.map { |(key, service)| service[:class_instance] }
		end

		#
		#  Get the instance of a service with the name `identifier`
		#
		def self.service(identifier)
			return Didit::SERVICES[identifier][:class_instance]
		end

end


#
#   Anything can be a service, so we add these static methods to the Object.
#
class Object

	#
	#   Called when a class declares itself as being a service
	#
	def self.as_service
		identifier = Didit::get_class_identifier(self)
		*folders, base_identifier = identifier.to_s.split("/")
		Didit::SERVICES[base_identifier.to_sym] = {
			identifier: identifier,
			class_object: self,
			class_instance: self.new
		}
	end

	#
	#   Called after all services have been loaded
	# 
	def self.post_construct(method_symbol)
		service = Didit::service_object(self)
		raise "this object doesn't declare as_service" unless service
		
		service[:post_config] = [] unless service[:post_config]
		service[:post_config] << method_symbol
	end


	#
	#  Called when a service wants to have something injected
	# 
	def self.inject(identifier)
		service = Didit::service_object(self)
		raise "this object doesn't declare as_service" unless service

		service[:requires] = [] unless service[:requires]
		service[:requires] << {
			type: 'one',
			id: identifier
		}
	end

	#
	#  Requests a list of a specific base type to be injected
	# 
	def self.inject_list(base_class, args)
		service = Didit::service_object(self)
		raise "this object doesn't declare as_service" unless service
		
		service[:requires] = [] unless service[:requires]
		service[:requires] << {
			type: 'multiple',
			id: base_class,
			var_name: args[:as]
		}
	end

end


#
#   This class loads ruby files and initializes the services specified inside of them
#
class ServiceScan

	attr_reader :base_dirs

	def initialize(base_dirs = ["services"])
		@base_dirs = base_dirs
	end

	def run!
		initial_scan
		inject_single
		inject_lists
		post_construct_triggers
	end


	private
		
		# 
		#  Run the post construct methods
		# 
		def post_construct_triggers
			Didit::SERVICES.each do |(key, service)|
				if service[:post_config] then
					service[:post_config].each do |method_name|
						service[:class_instance].method(method_name).call
					end
				end
			end

		end

		#
		#  Find injectables for the inject_list methods that have been specified
		#
		def inject_lists
			Didit::SERVICES.each do |(key, service)|
				get_multi_injects(service).each do |needs| 
					puts ".. service #{service[:identifier]} requires #{needs[:id]}"

					instances_list = Didit::services_with_base(needs[:id])
					puts "INSTANCES: #{instances_list.inspect}"

					service_instance = service[:class_instance]
					add_attr_reader(service_instance, needs[:var_name], instances_list)
				end
			end

		end

		#
		#  Find injectable that is to be bound to inject
		#
		def inject_single
			Didit::SERVICES.each do |(key, service)|
				get_single_inject(service).each do |needs| 
					puts ".. service #{service[:identifier]} requires #{needs[:id]}"

					injected_instance = Didit::service(needs[:id])
					service_instance = service[:class_instance]
					add_attr_reader(service_instance, needs[:id].to_sym, injected_instance)
				end
			end
		end

		#
		#   Return a list of single injects for a service
		# 
		def get_single_inject(service)
			if not service[:requires] or service[:requires].empty?
				[]
			else
				service[:requires].find_all { |req| req[:type] == "one" }
			end
		end

		#
		#   Return a list of multiple injects for a service
		#
		def get_multi_injects(service)
			puts service.inspect
			if not service[:requires] or service[:requires].empty?
				[]
			else
				service[:requires].find_all { |req| req[:type] == "multiple" }
			end
		end

		# 
		#   Add a reader method to a service_instance
		# 
		def add_attr_reader(service_instance, id, injectable)
			metaclass = class << service_instance; self; end

			metaclass.send(:define_method, id) do
				injectable
			end
		end

		#
		#  Scan the specified folders and load them
		#
		def initial_scan
			root_folder = Dir.pwd
			puts "From: #{root_folder}"

			@base_dirs.each do |dir|

				puts "Scanning #{dir}"

				Dir.chdir(dir)
				Dir.glob("**/*.rb") do |file|
					load "./#{file}"
				end

				Dir.chdir(root_folder)
			end		
		end

end

#
#  Create a service scanner and run it!
#
ServiceScan.new.run!