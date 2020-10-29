require 'rack'


class MansoServer
  def call env
    [200, {"Content-Type" => "text/html"}, ["Hello Manso Beach Folks ! #{Time.now} \n"]]
  end
end   
   

