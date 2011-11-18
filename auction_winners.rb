require 'rubygems'
require 'mongo'
require 'twilio-ruby'
require './local_settings'

db_name = 'rc_auction'
items_coll = 'items'
bidders_coll = 'bidders'
winners_coll = 'winners'

db = Mongo::Connection.new.db(db_name)

db[winners_coll].remove

puts
puts "AUCTION WINNERS..."
puts

# step through auction items and print winners
db[items_coll].find.sort('number').each do |item|
  
  puts "#{item['number']}. #{item['name']}: #{item['bids'].size} bids entered"
  
  if item['bids'] && item['bids'].size > 0 then
    item['bids'].sort_by! { |b| b['amount'].to_i }
    high = item['bids'].last
    winner = db[bidders_coll].find_one({ 'phone' => high['bidder_phone'] })
    
    puts "   HIGH BID: $#{high['amount']}"
    puts "   WINNER:   #{winner['name']} (#{winner['phone']})"
    
    # notify winner
    puts "   ...sending SMS to the winner..."
    msg = sprintf("Yay! You won the RaiseCache auction for \"#{item['name']}\". Thanks for supporting RaiseCache and hackNY!")
    puts "   #{msg}"
    # @client = Twilio::REST::Client.new $account_sid, $auth_token
    # @client.account.sms.messages.create(
    #   :from => $auction_number,
    #   :to => winner['phone'],
    #   :body => msg
    # )
    
    # send Venmo invoice
    puts "   ...sending Venmo SMS to the winner..."
    venmo_msg = "Please pay for your auction item here: https://venmo.com/?txn=Pay&recipients=6513570214&amount=#{high['amount']}&note=RaiseCache%20auction"
    puts "   #{venmo_msg}"
    # @client.account.sms.messages.create(
    #   :from => $auction_number,
    #   :to => winner['phone'],
    #   :body => venmo_msg
    # )
  
    # save for posterity
    db[winners_coll].insert({
      'ts' => Time.now.to_s,
      'item_number' => item['number'],
      'item_name' => item['name'],
      'num_bids' => item['bids'].size,
      'high_bid' => high['amount'],
      'winner_name' => winner['name'],
      'winner_phone' => winner['phone']
    })
  end
  
end