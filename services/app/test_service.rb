module App

	class BaseService
	end

	class A < App::BaseService
		as_service

		def called
			puts "A is called"
		end
	end

	class B < App::BaseService
		as_service

		def called
			puts "B is called"
		end
	end

	class TestService

		as_service
		post_construct :after_init
		post_construct :after_init_2

		def after_init
			puts "INITIALIZING COMPLETED"
		end

		def after_init_2
			puts "THIS ONE IS RUN LATER"
		end

	end


	class AnotherService

		as_service

		inject :test_service
		inject_list App::BaseService, as: 'common'

		post_construct :show_instances

		def show_instances
			common.each do |instance|
				instance.called
			end
		end

	end

end