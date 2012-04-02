# coding: utf-8
require 'sinatra'
Bundler.setup :default

require 'programr'

HAPPYBOT = ProgramR::Facade.new
HAPPYBOT.learn(['./aiml/happybot.aiml'])

set server: 'thin', connections: []

get '/' do
  halt erb(:login) unless params[:user]
  erb :chat, locals: { user: params[:user].gsub(/\W/, '') }
end

get '/stream', provides: 'text/event-stream' do
  stream :keep_open do |out|
    settings.connections << out
    out.callback { settings.connections.delete(out) }
  end
end

post '/' do
  reply = HAPPYBOT.get_reaction(params[:msg])
  if reply.empty?
    reply = "I don't know anything about that yet..."
  end
  settings.connections.each { |out| out << "data: #{params[:user]}: #{params[:msg]}|#{reply}\n\n"}
  204 # response without entity body
end

__END__

@@ layout
<html>
  <head>
    <title>Super Simple Chat with Sinatra</title> 
    <meta charset="utf-8" />
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script> 
  </head>
  <body><%= yield %></body>
</html>

@@ login
<form action='/'>
  <label for='user'>User Name:</label>
  <input name='user' value='' />
  <input type='submit' value="GO!" />
</form>

@@ chat
<pre id='chat'></pre>

<script>
  // reading
  var es = new EventSource('/stream');
  es.onmessage = function(e) {
    msg = e.data.split('|')
    $('#chat').append(msg[0] + "\n")
    $('#chat').append("Happybot:" + msg[1] + "\n")
  };

  // writing
  $("form").live("submit", function(e) {
    $.post('/', {user: "<%= user %>", msg: $('#msg').val()});
    $('#msg').val(''); $('#msg').focus();
    e.preventDefault();
  });
</script>

<form>
  <input id='msg' placeholder='type message here...' />
</form>
