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
    @redis_slave = Redis.new(
#      master_name: 'mymaster',

      url: 'redis://mymaster',
      sentinels: @sentinels,
      role: slave,
      failover_reconnect_timeout: 60,
      logger: Logger.new(STDOUT)
    )

  end

  def test_connection
    input = Random.rand(10_000_000)
    output = nil
    
    @redis.set('foo', input)

    Timeout.timeout(2) do
      output = @redis_slave.get('foo').to_i
    end

    return "ERROR: Incorrect response #{input} != #{output}" unless input == output
    return "Success (#{input} == #{output}) from #{@redis.id}"
  rescue Timeout::Error
    return 'ERROR: Timeout exceeded'
  end
end

test = TestClient.new
STDOUT.sync = true
while true
puts test.test_connection
sleep(10)
end
