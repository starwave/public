# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe TromsoWallpaperApp do
  def app
    TromsoWallpaperApp
  end

  describe 'GET /health' do
    it 'returns health status' do
      get '/health'

      expect(last_response).to be_ok
      expect(last_response.content_type).to include('application/json')

      body = JSON.parse(last_response.body)
      expect(body['status']).to eq('ok')
      expect(body['timestamp']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end

  describe 'GET /maramboi' do
    context 'when action is g' do
      it 'returns theme library' do
        get '/maramboi?a=g'

        expect(last_response).to be_ok
        expect(last_response.content_type).to include('application/json')

        body = JSON.parse(last_response.body)
        expect(body).to be_an(Array)
        expect(body.length).to be > 0

        expect(body.first).to have_key('Label')
        expect(body.first).to have_key('Config')
      end
    end

    context 'when action is invalid' do
      it 'returns error' do
        get '/maramboi?a=invalid'

        expect(last_response.status).to eq(400)

        body = JSON.parse(last_response.body)
        expect(body).to have_key('error')
      end
    end

    context 'when action parameter is missing' do
      it 'returns error' do
        get '/maramboi'

        expect(last_response.status).to eq(400)
      end
    end
  end

  describe 'GET /ngorongoro' do
    it 'handles wallpaper request with parameters' do
      get '/ngorongoro?a=tweb&d=1920x1080&t=default2&o='

      expect(last_response).to be_ok
      expect(last_response.content_type).to include('application/json')

      body = JSON.parse(last_response.body)
      expect(body).to have_key('message')
      expect(body).to have_key('params')
      expect(body['params']['d']).to eq('1920x1080')
      expect(body['params']['t']).to eq('default2')
    end

    it 'handles different dimension formats' do
      dimensions = ['1920x1080', '3840x2160', '2732x2048', '1080x2280']

      dimensions.each do |dimension|
        get "/ngorongoro?a=tweb&d=#{dimension}&t=default1"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body['params']['d']).to eq(dimension)
      end
    end

    it 'handles all theme types' do
      themes = %w[default1 default2 custom photo recent wallpaper landscape movie1 movie2 special1 special2 all]

      themes.each do |theme|
        get "/ngorongoro?a=tweb&d=1920x1080&t=#{theme}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body['params']['t']).to eq(theme)
      end
    end
  end

  describe 'CORS' do
    it 'includes CORS headers' do
      get '/health'

      expect(last_response.headers).to have_key('Access-Control-Allow-Origin')
    end

    it 'handles OPTIONS preflight request' do
      options '/maramboi'

      expect(last_response).to be_ok
    end
  end
end
