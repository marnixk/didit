require "didit/version"
require "didit/object_functions"
require "didit/service_scan"

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

