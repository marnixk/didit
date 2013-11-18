
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