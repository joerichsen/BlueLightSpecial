module BlueLightSpecial
  class Routes

    # In your application's config/routes.rb, draw BlueLightSpecial's routes:
    #
    # @example
    #   map.resources :posts
    #   BlueLightSpecial::Routes.draw(map)
    #
    # If you need to override a BlueLightSpecial route, invoke your app route
    # earlier in the file so Rails' router short-circuits when it finds
    # your route:
    #
    # @example
    #   map.resources :users, :only => [:new, :create]
    #   BlueLightSpecial::Routes.draw(map)
    def self.draw(map)
      map.resource :impersonation,
        :controller => 'blue_light_special/impersonations',
        :only       => [:create, :destroy]
      map.resources :impersonations,
        :controller => 'blue_light_special/impersonations',
        :only       => :index
    end

  end
end
