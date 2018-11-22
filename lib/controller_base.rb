require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params)
    @req = req
    @res = res
    @params = params.merge(req.params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response ||= false
  end

  # Set the response status code and header
  def redirect_to(url)
    if already_built_response?
      raise Exception
    else
      session.store_session(@res) 
      @res.status = 302
      @res['Location'] = url
      @already_built_response = true
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    if already_built_response?
      raise Exception
    else 
      session.store_session(@res)
      @res['Content-Type'] = content_type
      @res.write(content)
      @already_built_response = true
    end
    
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    path = File.dirname(__FILE__)
    new_path = File.join(path, "..", "views", self.class.name.underscore, "#{template_name}.html.erb")
    file_content = File.read(new_path)
    erb_code = ERB.new(file_content).result(binding)
    render_content(erb_code, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end
end

