# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'rack/cors'
require 'json'

class TromsoWallpaperApp < Sinatra::Base
  configure do
    set :port, ENV.fetch('PORT', 3001)
    set :bind, '0.0.0.0'
    set :public_folder, File.join(root, '..', 'public')
    set :static, true

    # Enable CORS
    use Rack::Cors do
      allow do
        origins '*'
        resource '*',
                 headers: :any,
                 methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end

    # Logging
    configure :development do
      set :logging, Logger::DEBUG
    end
  end

  # Theme library data
  THEME_LIBRARY = [
    { Label: 'Nature Collection', Config: '/nature;;#green#|#forest#' },
    { Label: 'Urban Scenes', Config: '/urban;;#city#|#architecture#' },
    { Label: 'Abstract Art', Config: '/abstract;;#modern#|#colors#' },
    { Label: 'Minimalist', Config: '/minimal;;#simple#|#clean#' },
    { Label: 'Space & Astronomy', Config: '/space;;#galaxy#|#stars#' }
  ].freeze

  # Health check endpoint
  get '/health' do
    json status: 'ok', timestamp: Time.now.iso8601
  end

  # Get theme library
  get '/maramboi' do
    action = params[:a]

    if action == 'g'
      json THEME_LIBRARY
    else
      status 400
      json error: 'Invalid action'
    end
  end

  # Get wallpaper (proxy to actual wallpaper service)
  get '/ngorongoro' do
    action = params[:a]
    dimension = params[:d]
    theme = params[:t]
    options = params[:o]

    # Log the request
    logger.info "Wallpaper request: action=#{action}, dimension=#{dimension}, theme=#{theme}, options=#{options}"

    # In production, this would proxy to your actual wallpaper service
    # For now, return a placeholder
    json message: 'Wallpaper endpoint',
         params: {
           a: action,
           d: dimension,
           t: theme,
           o: options
         }
  end

  # Serve React app for all other routes (SPA)
  get '*' do
    if File.exist?(File.join(settings.public_folder, 'index.html'))
      send_file File.join(settings.public_folder, 'index.html')
    else
      status 404
      json error: 'Application not found. Please build the frontend first.'
    end
  end

  # Error handling
  error do
    error = env['sinatra.error']
    logger.error "Error: #{error.message}"
    logger.error error.backtrace.join("\n")

    status 500
    json error: 'Internal server error'
  end
end
