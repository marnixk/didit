
#
#   This class loads ruby files and initializes the services specified inside of them
#
class ServiceScan

	attr_reader :base_dirs

	def initialize(base_dirs = ["services"])
		@base_dirs = base_dirs
	end

	def run!
		perform_initial_scan
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
		def perform_initial_scan
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
