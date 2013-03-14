require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'sinatra-authentication'
require 'digest/sha1'
require 'haml'


if development? # This is set by default, override with `RACK_ENV=production rackup`
  require 'sinatra/reloader'
  require 'debugger'
  Debugger.settings[:autoeval] = true
  Debugger.settings[:autolist] = 1
  Debugger.settings[:reload_source_on_change] = true
end

# TODO:
# . logging
# . media types testing
# . put the database somewhere else
# . GET a range
# . multi-user with authentication

configure :development, :production do
  set :datamapper_url, "sqlite3://#{File.dirname(__FILE__)}/kix.sqlite3"
end
configure :test do
  set :datamapper_url, "sqlite3://#{File.dirname(__FILE__)}/kix-test.sqlite3"
end

DataMapper.setup(:default, settings.datamapper_url)

use Rack::Session::Cookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'

class Task
  include DataMapper::Resource

  Task.property(:id, Serial)
  Task.property(:user_id, Integer, :required => true)
  Task.property(:type, Text, :required => true)
  Task.property(:text, Text)
  Task.property(:completed, Boolean, :default => false)
  Task.property(:created_at, DateTime)
  Task.property(:updated_at, DateTime)

  def to_json(*a)
   {
      'id'            => self.id,
      'user_id'       => self.user_id,
      'type'          => self.type,
      'text'          => self.text,
      'completed'     => self.completed,
      'created_at'    => self.created_at,
      'updated_at'    => self.updated_at

   }.to_json(*a)
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!

def jsonp?(json)
  if params[:callback]
    return("#{params[:callback]}(#{json})")
  else
    return(json)
  end
end

# comment out for dev mode
before '/task*' do
  login_required
end

get '/' do
  redirect '/index.html'
end

# get all tasks in existence
get '/tasks' do
  tasks = Task.all.to_a

  if tasks.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  return [200, {'Content-Type' => 'application/json'}, [jsonp?(tasks.to_json)]]

end

# get all task in existence by id.
get '/task/:id' do
  task = Task.get(params[:id])

  if task.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  return [200, {'Content-Type' => 'application/json'}, [jsonp?(task.to_json)]]
end

get '/user' do
  task = Task.all(:user_id  => current_user.id).to_a

  if task.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  return [200, {'Content-Type' => 'application/json'}, [jsonp?(task.to_json)]]
end

#get all task by specific user_id
get '/user/:cur_usr' do
  task = Task.all(:user_id  =>  params[:cur_usr]).to_a

  if task.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  return [200, {'Content-Type' => 'application/json'}, [jsonp?(task.to_json)]]
end


## For testing:
## curl -vX PUT -d '{"current_user.id": "2", "type": "fin_goal", "text": "10000.000", "completed": "true" }' http://localhost:9292/task

#



# make new tasks.
put '/task' do
  # Request.body.read is destructive, make sure you don't use a puts here.
  data = JSON.parse(request.body.read)

  # Normally we would let the model validations handle this but we don't
  # have validati3ons yet so we have to check now and after we save.
  if data.nil? || data['user_id'].nil? || data['type'].nil?
    return [406, {'Content-Type' => 'application/json'}, ['']]
  end

  task = Task.create(
              :user_id => data['current_user.id'],
              :type => data['type'],
              :text => data['text'],
              :completed => data['completed'],
              :created_at => Time.now,
              :updated_at => Time.now)

  # PUT requests must return a Location header for the new resource
  if task.save
    return [201, {'Content-Type' => 'application/json', 'Location' => "/task/#{task.id}"}, [jsonp?(task.to_json)]]
  else
    return [406, {'Content-Type' => 'application/json'}, ['']]
  end
end

post '/test' do
  # puts params[:post][:type_task]
  # puts "hello"
  # puts params[:input]
  # puts params[:type_task]
  # puts params[:completed]
  # Request.body.read is destructive, make sure you don't use a puts here.
  # data = JSON.parse(request.body.read)

  # Normally we would let the model validations handle this but we don't
  # have validati3ons yet so we have to check now and after we save.

  # if data.nil? || data['user_id'].nil? || data['type'].nil?
  #   return [406, {'Content-Type' => 'application/json'}, ['']]
  # end

  task = Task.create(
              # :user_id => current_user.id,
              :user_id => current_user.id,
              :type => params[:post][:type_task],
              :text => params[:post][:type_text],
              :completed => params[:post][:completed],
              :created_at => Time.now,
              :updated_at => Time.now)

  # # PUT requests must return a Location header for the new resource
  if task.save
    return [201, {'Content-Type' => 'application/json'}, ['Good, work.']]
  else
    return [406, {'Content-Type' => 'application/json'}, ['ERROR']]
  end
end


#update task text field and completeness
post '/task/:id' do
  # Request.body.read is destructive, make sure you don't use a puts here.
  data = JSON.parse(request.body.read)
  if data.nil?
    return [406, {'Content-Type' => 'application/json'}, ['']]
  end

  task = Task.get(params[:id])
  if task.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  %w(text completed).each do |key|
    if !data[key].nil? && data[key] != task[key]
      task[key] = data[key]
      task['updated_at'] = Time.now
    end
  end


  if task.save then
    return [200, {'Content-Type' => 'application/json'}, [jsonp?(task.to_json)]]
  else
    return [406, {'Content-Type' => 'application/json'}, ['']]
  end
end

# Remove a task + user entirely. For admin use.
delete '/task/:id' do
  task = Task.get(params[:id])
  if task.nil?
    return [404, {'Content-Type' => 'application/json'}, ['']]
  end

  if task.destroy then
    return [204, {'Content-Type' => 'application/json'}, ['']]
  else
    return [500, {'Content-Type' => 'application/json'}, ['']]
  end
end


