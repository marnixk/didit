# Didit - Simple Ruby Dependency Injection

Didit is a tiny gem that gives you a simple dependency injection mechanism 
with package scanning for the Ruby programming language. It extends the base
class "Object" with a number of operation you can use to decorate your classes
with.

To create a class that is a service one could do the following:

    class MyService
        as_service
    end

Now, when the ServiceScan runs and loads the ruby file, it will recognize this
class a service and registers it for safe keeping. Any service is able to inject
other services, or a list of services of a certain type. To inject MyService into
another service do the following:

    class AnotherService
         as_service
         inject :my_service
    end

This will automatically generate a method called 'my_service' that returns the one
instance to our MyService class. It is also possible to get a list of certain service
objects:

    class BaseService; end
    class A < BaseService; as_service; end
    class B < BaseService; as_service; end;

    class AnotherService
        as_service
        inject_list BaseService, as: "service_list"
    end

Now, in your methods you can us the 'service_list' method to retrieve an array of 
available BaseService implementations.

Finally, it is possible to run code after the service has been initialized and all
the injectables have been setup properly. To do this, specify a method that is ran
post_construct, like so:

    class AnotherService
        as_service
        
        post_construct :after_init
        
        def after_init
            puts "Run afterwards"
        end
    end

    