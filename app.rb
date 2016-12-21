require 'redis'
#require 'redis-sentinel'
require 'timeout'
require 'logger'
require 'sinatra'

class TestClient
  def initialize
    @sentinels = [
      { host: 'redis-sentinel', port: 26379 }
      #{ host: '10.1.4.111', port: 26379 }
#      { host: 'sentinel03.example.com', port: 26379 },
    ]

    @redis = Redis.new(
      url: 'redis://mymaster',
      sentinels: @sentinels,
      failover_reconnect_timeout: 60,
      logger: Logger.new(STDOUT)
    )
  end

  def test_connection
    @redis_slave = Redis.new(
      url: 'redis://mymaster',
      sentinels: @sentinels,
      role: 'slave',
      failover_reconnect_timeout: 60,
      logger: Logger.new(STDOUT)
    )
    input = Random.rand(10_000_000)
    output = nil
    puts"Writing value #{input} to master and reading from random slave."    
    @redis.set('foo', input)

    #Timeout.timeout(3) do
      output = @redis_slave.get('foo').to_i
    #end

    return "ERROR: Incorrect response #{input} != #{output}" unless input == output
    return "Success (#{input} == #{output}) from random slave #{@redis_slave.id}"
  #rescue Timeout::Error
  #  return 'ERROR: Timeout exceeded. Read took longer than 3s'
end
  
  def subscribe
    @redis.subscribe("one", "two") do |on|
      on.message do |channel, message|
       puts "pub/sub test received: ##{channel}: #{message}"
       @redis.unsubscribe if message == "exit"
      end
    end
  end
  
  
end

test = TestClient.new
STDOUT.sync = true
# Test connection before subscribing.
#puts test.test_connection
#sleep(10)
#test.subscribe
while true
puts test.test_connection
sleep(10)
end
